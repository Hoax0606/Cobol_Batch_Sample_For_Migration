package com.KSInfo.batch;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.List;

import javax.print.DocFlavor.STRING;

import java.math.RoundingMode;
import java.io.BufferedWriter;
import java.io.FileWriter;
import java.io.IOException;
import java.math.BigDecimal;

import com.KSInfo.batch.dao.PGM_PHASE4Dao;
import com.KSInfo.batch.dto.PGM_PHASE4Dto;
import com.KSInfo.batch.dto.DCL_TB_NET_SUMMARYDto;
import com.KSInfo.batch.dto.PGM_BLOGSVRDto;
import lombok.extern.slf4j.Slf4j;

@Slf4j
public class PGM_PHASE4 {
    private int SQLCODE = 0;
    private int resultCode;

    private BufferedWriter OUT_FILE;

    @Value("${batch.file.path.output}")
    private String OUT_FILE_Path;

    @Autowired
    private PGM_PHASE4Dao dao;

    @Autowired
    private PGM_BLOGSVR PGM_BLOGSVR;

    @Autowired
    private PGM_BLOGSVRDto PGM_BLOGSVRDto;
    public void MAIN(PGM_PHASE4Dto dto) {
        INIT(dto);
        dto.setFetchOffset(0);
        while (!dto.getWS_FLAGSDto_2().getWS_EOF_FLAG().equals(dto.getWS_FLAGSDto_2().WS_EOF)) {
            DATA_PROCESS(dto);
        }
        FINALIZE(dto);

        this.resultCode = dto.getSYS_COMMON_AREADto().getSYS_RET_CODE();
        System.exit(this.resultCode);
    }

    public void INIT(PGM_PHASE4Dto dto) {
        dto.getSYS_COMMON_AREADto().setSYS_JOB_ID(dto.getWS_PHASE_ID());
        dto.getSYS_COMMON_AREADto().setSYS_BIZ_DATE(LocalDate.now().format(DateTimeFormatter.ofPattern("yyyyMMdd")));
        dto.setWS_START_DATETIME(LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyyMMddHHmmss")));
        dto.setWS_BIZ_DATE_W(dto.getSYS_COMMON_AREADto().getSYS_BIZ_DATE());

        // ACCEPT WS-DATASRC      FROM ENVIRONMENT 'GIXSQL_DB_CONN'.
        // ACCEPT WS-USER         FROM ENVIRONMENT 'GIXSQL_USER'.
        // ACCEPT WS-PWD          FROM ENVIRONMENT 'GIXSQL_PWD'.

        if (dto.getWS_DB_CONNDto().getWS_DATASRC().equals("")) {
            dto.getWS_COUNTERSDto_4().setWS_ERR_CNT(SQLCODE);
            dto.getERR_LOG_AREADto().setERR_DESCRIPTION("GIXSQL_DB_CONN NOT SET");
            SYSTEM_ERROR(dto);
            dto.getSYS_COMMON_AREADto().setSYS_RET_CODE(dto.getSYS_COMMON_AREADto().BATCH_ERROR);
            dto.getDCL_TB_BATCH_LOGDto().setBLG_RETURN_CODE(dto.getSYS_COMMON_AREADto().getSYS_RET_CODE());
            System.exit(dto.getSYS_COMMON_AREADto().getSYS_RET_CODE());
        } else {
            // CONTINUE
        }

        try{
           OUT_FILE = new BufferedWriter(new FileWriter(OUT_FILE_Path));
           // CONTINUE
        } catch (Exception e){
            dto.getERR_LOG_AREADto().setERR_DESCRIPTION("OUTPUT FILE OPEN ERROR");
            SYSTEM_ERROR(dto);
            dto.getSYS_COMMON_AREADto().setSYS_RET_CODE(dto.getSYS_COMMON_AREADto().BATCH_ERROR);
            this.resultCode = dto.getSYS_COMMON_AREADto().getSYS_RET_CODE();
            System.exit(this.resultCode);
        }

        // EXEC SQL
        //     CONNECT :WS-USER IDENTIFIED BY :WS-PWD
        //             USING :WS-DATASRC
        // END-EXEC.

        if (SQLCODE != 0) {
            dto.getERR_LOG_AREADto().setERR_SQLCODE(SQLCODE);
            dto.getERR_LOG_AREADto().setERR_DESCRIPTION("DB CONNECT ERROR");
            SYSTEM_ERROR(dto);
            dto.getSYS_COMMON_AREADto().setSYS_RET_CODE(dto.getSYS_COMMON_AREADto().BATCH_ERROR);
            this.resultCode = dto.getSYS_COMMON_AREADto().getSYS_RET_CODE();
            System.exit(this.resultCode);
        } else {
            // CONTINUE
        }

        BATCHLOG_START(dto);

        // EXEC SQL OPEN C-NET-SUMMARY END-EXEC.

        if (SQLCODE != 0) {
            dto.getERR_LOG_AREADto().setERR_SQLCODE(SQLCODE);
            dto.getERR_LOG_AREADto().setERR_DESCRIPTION("CURSOR OPEN ERROR");
            SYSTEM_ERROR(dto);
            dto.getSYS_COMMON_AREADto().setSYS_RET_CODE(dto.getSYS_COMMON_AREADto().BATCH_ERROR);
            this.resultCode = dto.getSYS_COMMON_AREADto().getSYS_RET_CODE();
            System.exit(this.resultCode);
        } else {
            // CONTINUE
        }

        WRITE_HEADER(dto);
    }

    public void DATA_PROCESS(PGM_PHASE4Dto dto) {
        List<DCL_TB_NET_SUMMARYDto> list = dao.select_01(dto, dto.getFetchLimit(), dto.getFetchOffset());

        for (DCL_TB_NET_SUMMARYDto row : list) {
            dto.getDCL_TB_NET_SUMMARYDto().setSUM_SETTLE_DATE(row.getSUM_SETTLE_DATE());
            dto.getDCL_TB_NET_SUMMARYDto().setSUM_INST_CD(row.getSUM_INST_CD());
            dto.getDCL_TB_NET_SUMMARYDto().setSUM_INST_NAME(row.getSUM_INST_NAME());
            dto.getDCL_TB_NET_SUMMARYDto().setSUM_TOT_IN(row.getSUM_TOT_IN());
            dto.getDCL_TB_NET_SUMMARYDto().setSUM_TOT_OUT(row.getSUM_TOT_OUT());
            dto.getDCL_TB_NET_SUMMARYDto().setSUM_NET_AMT(row.getSUM_NET_AMT());
            dto.getDCL_TB_NET_SUMMARYDto().setSUM_TOT_FEE(row.getSUM_TOT_FEE());
            dto.getDCL_TB_NET_SUMMARYDto().setSUM_TOT_CNT(row.getSUM_TOT_CNT());

            if (SQLCODE == 0) {
                WRITE_DATA(dto);
            } else if (SQLCODE == 100) {
                dto.getWS_FLAGSDto_2().setWS_EOF_FLAG(dto.getWS_FLAGSDto_2().WS_EOF);
            } else {
                dto.getERR_LOG_AREADto().setERR_SQLCODE(SQLCODE);
                dto.getERR_LOG_AREADto().setERR_DESCRIPTION("CURSOR FETCH ERROR");
                SYSTEM_ERROR(dto);
                dto.getSYS_COMMON_AREADto().setSYS_RET_CODE(dto.getSYS_COMMON_AREADto().BATCH_ERROR);
                this.resultCode = dto.getSYS_COMMON_AREADto().getSYS_RET_CODE();
                System.exit(this.resultCode);
            }
        }
        
        dto.setFetchOffset(dto.getFetchOffset() + dto.getFetchLimit());
        if (list.size() < dto.getFetchLimit()) {
            dto.getWS_FLAGSDto_2().setWS_EOF_FLAG(dto.getWS_FLAGSDto_2().WS_EOF);
        }
    }

    public void WRITE_HEADER(PGM_PHASE4Dto dto) {
        dto.setOUT_REC("");
        dto.getFILE_CONTROL_RECDto().setREC_TYPE("H");
        dto.getHEADER_RECDto().setHDR_CREATE_DATE(dto.getSYS_COMMON_AREADto().getSYS_BIZ_DATE());
        dto.setOUT_REC(dto.getFILE_CONTROL_RECDto());
        try {
            OUT_FILE.write(dto.getOUT_REC());
            OUT_FILE.newLine();
        } catch (IOException e) {
            
        }
    }

    public void WRITE_DATA(PGM_PHASE4Dto dto) {
        dto.setREC_KEYDto("D"
        + dto.getDCL_TB_NET_SUMMARYDto().getSUM_SETTLE_DATE()
        + LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyyMMddHHmmss"))
        + dto.getDCL_TB_NET_SUMMARYDto().getSUM_INST_CD());

        dto.getDATA_RECDto().setOUT_INST_NAME(dto.getDCL_TB_NET_SUMMARYDto().getSUM_INST_NAME());
        StringBuilder sb = new StringBuilder(dto.getDATA_RECDto().getOUT_INST_NAME());
        for (int i = 0; i < sb.length(); i++) {
            int idx = "ABCDEFGHIJKLMNOPQRSTUVWXYZ".indexOf(sb.charAt(i));
            if (idx >= 0) {
                sb.setCharAt(i, "abcdefghijklmnopqrstuvwxyz".charAt(idx));
            }
        }
        dto.getDATA_RECDto().setOUT_INST_NAME(sb.toString());

        dto.getDATA_RECDto().setOUT_TOT_IN(dto.getDCL_TB_NET_SUMMARYDto().getSUM_TOT_IN());
        dto.getDATA_RECDto().setOUT_TOT_OUT(dto.getDCL_TB_NET_SUMMARYDto().getSUM_TOT_OUT());
        dto.getDATA_RECDto().setOUT_NET_AMT(dto.getDCL_TB_NET_SUMMARYDto().getSUM_NET_AMT());
        dto.getDATA_RECDto().setOUT_TOT_FEE(dto.getDCL_TB_NET_SUMMARYDto().getSUM_TOT_FEE());
        dto.getDATA_RECDto().setOUT_TOTAL_CNT(dto.getDCL_TB_NET_SUMMARYDto().getSUM_TOT_CNT());
        try {
            OUT_FILE.write(dto.getOUT_REC());
            OUT_FILE.newLine();
        } catch (IOException e) {
            
        }

        dto.getWS_EDIT_AREADto().setED_TOT_IN(dto.getDCL_TB_NET_SUMMARYDto().getSUM_TOT_IN().toString());
        dto.getWS_EDIT_AREADto().setED_TOT_OUT(dto.getDCL_TB_NET_SUMMARYDto().getSUM_TOT_OUT().toString());
        dto.getWS_EDIT_AREADto().setED_NET_AMT(dto.getDCL_TB_NET_SUMMARYDto().getSUM_NET_AMT().toString());
        dto.getWS_EDIT_AREADto().setED_TOT_FEE(dto.getDCL_TB_NET_SUMMARYDto().getSUM_TOT_FEE().toString());
        log.info(" > [DATA]" + " KEY=[" + dto.getREC_KEYDto() + "]" + " NAME=" + dto.getDATA_RECDto().getOUT_INST_NAME() + " IN=" + dto.getWS_EDIT_AREADto().getED_TOT_IN() + " OUT=" + dto.getWS_EDIT_AREADto().getED_TOT_OUT() + " NET=" + dto.getWS_EDIT_AREADto().getED_NET_AMT() + " FEE=" + dto.getWS_EDIT_AREADto().getED_TOT_FEE());

        dto.getWS_COUNTERSDto_4().setWS_CALC_CNT(dto.getWS_COUNTERSDto_4().getWS_CALC_CNT() + 1);
        dto.getWS_CALC_TOTALSDto_4().setWS_CALC_IN(dto.getWS_CALC_TOTALSDto_4().getWS_CALC_IN().add(dto.getDCL_TB_NET_SUMMARYDto().getSUM_TOT_IN()));
        dto.getWS_CALC_TOTALSDto_4().setWS_CALC_OUT(dto.getWS_CALC_TOTALSDto_4().getWS_CALC_OUT().add(dto.getDCL_TB_NET_SUMMARYDto().getSUM_TOT_OUT()));
        dto.getWS_CALC_TOTALSDto_4().setWS_CALC_AMT(dto.getWS_CALC_TOTALSDto_4().getWS_CALC_AMT().add(dto.getDCL_TB_NET_SUMMARYDto().getSUM_NET_AMT()));
        dto.getWS_CALC_TOTALSDto_4().setWS_CALC_FEE(dto.getWS_CALC_TOTALSDto_4().getWS_CALC_FEE().add(dto.getDCL_TB_NET_SUMMARYDto().getSUM_TOT_FEE()));

        dto.getWS_WORK_AREASDto_4().setWS_MOD_WORK(dto.getWS_COUNTERSDto_4().getWS_CALC_CNT() % dto.getWS_PROGRESS_INTERVAL());
        if (dto.getWS_WORK_AREASDto_4().getWS_MOD_WORK() == 0) {
            PROGRESS_LOG(dto);
        } else {
            // CONTINUE
        }

    }

    public void FINALIZE(PGM_PHASE4Dto dto) {
        // EXEC SQL CLOSE C-NET-SUMMARY END-EXEC.

        WRITE_TRAILER(dto);

        try {
            if (OUT_FILE != null) OUT_FILE.close();
        } catch (IOException e) {
            
        }

        BATCHLOG_END(dto);
        // EXEC SQL COMMIT            END-EXEC.

        // EXEC SQL DISCONNECT CURRENT END-EXEC.

        dto.getWS_EDIT_AREADto().setED_CALC_AMT(dto.getWS_CALC_TOTALSDto_4().getWS_CALC_AMT().toString());
        log.info(" > ========= PGM-PHASE4 RESULT =========");
        log.info(" > DATA WRITTEN : " + dto.getWS_COUNTERSDto_4().getWS_CALC_CNT());
        log.info(" > TOTAL IN AMT : " + dto.getWS_CALC_TOTALSDto_4().getWS_CALC_IN());
        log.info(" > TOTAL OUT AMT: " + dto.getWS_CALC_TOTALSDto_4().getWS_CALC_OUT());
        log.info(" > TOTAL FEE AMT: " + dto.getWS_CALC_TOTALSDto_4().getWS_CALC_FEE());
        log.info(" > TOTAL NET AMT: " + dto.getWS_CALC_TOTALSDto_4().getWS_CALC_AMT());
        log.info(" > DB ERRORS    : " + dto.getWS_COUNTERSDto_4().getWS_ERR_CNT());
        log.info(" > =====================================");

    }

    public void WRITE_TRAILER(PGM_PHASE4Dto dto) {
        dto.setOUT_REC("");
        dto.getFILE_CONTROL_RECDto().setREC_TYPE("T");
        dto.getTRAILER_RECDto().setTRL_TOT_CNT(dto.getWS_COUNTERSDto_4().getWS_CALC_CNT());
        dto.getTRAILER_RECDto().setTRL_TOT_AMT(dto.getWS_CALC_TOTALSDto_4().getWS_CALC_AMT());
        dto.setOUT_REC(dto.getFILE_CONTROL_RECDto().getREC_TYPE() + "" + dto.getTRAILER_RECDto().getTRL_TOT_CNT() + "" + dto.getTRAILER_RECDto().getTRL_TOT_AMT());
        try {
            OUT_FILE.write(dto.getOUT_REC());
            OUT_FILE.newLine();
        } catch (IOException e) {
            
        }
    }

    public void PROGRESS_LOG(PGM_PHASE4Dto dto) {
        log.info(" > ... " + dto.getWS_COUNTERSDto_4().getWS_CALC_CNT() + " RECORDS WRITTEN... <");
    }

    public void BATCHLOG_START(PGM_PHASE4Dto dto) {
        dto.getDCL_TB_BATCH_LOGDto().setBLG_PGM_ID(dto.getWS_PROG_NAME());
        dto.getDCL_TB_BATCH_LOGDto().setBLG_BIZ_DATE(dto.getSYS_COMMON_AREADto().getSYS_BIZ_DATE());
        dto.getDCL_TB_BATCH_LOGDto().setBLG_START_DT(dto.getWS_START_DATETIME());
        dto.getDCL_TB_BATCH_LOGDto().setBLG_REMARK("PHASE4 STARTED");
        dto.getDCL_TB_BATCH_LOGDto().setBLG_ACTION("START");
        
        PGM_BLOGSVR.MAIN(PGM_BLOGSVRDto);

        if (dto.getDCL_TB_BATCH_LOGDto().getBLG_RETURN_CODE() != 0) {
            log.info("> [WARN] BLOGSVR START FAILED. RC=" + dto.getDCL_TB_BATCH_LOGDto().getBLG_RETURN_CODE());
        } else {
            // CONTINUE
        }
    }

    public void BATCHLOG_END(PGM_PHASE4Dto dto) {
        dto.getDCL_TB_BATCH_LOGDto().setBLG_PROC_CNT(dto.getWS_COUNTERSDto_4().getWS_CALC_CNT());
        dto.getDCL_TB_BATCH_LOGDto().setBLG_ERR_CNT(dto.getWS_COUNTERSDto_4().getWS_ERR_CNT());
        dto.getDCL_TB_BATCH_LOGDto().setBLG_ACTION("END  ");

        if (dto.getWS_COUNTERSDto_4().getWS_ERR_CNT() > 0) {
            dto.getDCL_TB_BATCH_LOGDto().setBLG_STAT("E");
            dto.getDCL_TB_BATCH_LOGDto().setBLG_REMARK("PHASE4 COMPLETED WITH ERRORS");
        } else {
            dto.getDCL_TB_BATCH_LOGDto().setBLG_STAT("S");
            dto.getDCL_TB_BATCH_LOGDto().setBLG_REMARK("PHASE4 COMPLETED SUCCESSFULLY");
        }

        PGM_BLOGSVR.MAIN(PGM_BLOGSVRDto);

        if (dto.getDCL_TB_BATCH_LOGDto().getBLG_RETURN_CODE() != 0) {
            log.info("> [WARN] BLOGSVR END FAILED. RC=" + dto.getDCL_TB_BATCH_LOGDto().getBLG_RETURN_CODE());
        } else {
            // CONTINUE
        }
    }

    public void SYSTEM_ERROR(PGM_PHASE4Dto dto) {
        dto.getERR_LOG_AREADto().setERR_PGM_ID(dto.getWS_PROG_NAME());
        dto.getERR_LOG_AREADto().setERR_SEVERITY(dto.getERR_LOG_AREADto().ERR_FATAL);
        dto.getSYS_COMMON_AREADto().setSYS_RET_CODE(dto.getSYS_COMMON_AREADto().BATCH_ERROR);
        log.info("*** SYSTEM FATAL ERROR ***");
        log.info("PGM: " + dto.getERR_LOG_AREADto().getERR_PGM_ID() + " SQLCODE: " + dto.getERR_LOG_AREADto().getERR_SQLCODE());
        log.info("MSG: " + dto.getERR_LOG_AREADto().getERR_DESCRIPTION());
    }

    public void DB_ERROR(PGM_PHASE4Dto dto) {
        dto.getERR_LOG_AREADto().setERR_PGM_ID(dto.getWS_PROG_NAME());
        dto.getERR_LOG_AREADto().setERR_SEVERITY(dto.getERR_LOG_AREADto().ERR_WARN);
        dto.getSYS_COMMON_AREADto().setSYS_RET_CODE(dto.getSYS_COMMON_AREADto().BATCH_WARNING);
        dto.getWS_COUNTERSDto_4().setWS_ERR_CNT(dto.getWS_COUNTERSDto_4().getWS_ERR_CNT() + 1);
        log.info("*** DB ERROR ***");
        log.info("PGM: " + dto.getERR_LOG_AREADto().getERR_PGM_ID() + " SQLCODE: " + dto.getERR_LOG_AREADto().getERR_SQLCODE());
        log.info("MSG: " + dto.getERR_LOG_AREADto().getERR_DESCRIPTION());
        log.info("KEY: [" + dto.getREC_KEYDto() + "]");
    }

}