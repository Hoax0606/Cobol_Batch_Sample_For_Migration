package com.KSInfo.batch;

import org.springframework.beans.factory.annotation.Autowired;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.math.BigDecimal;

import com.KSInfo.batch.dao.PGM_PHASE2Dao;
import com.KSInfo.batch.dto.PGM_PHASE2Dto;
import com.KSInfo.batch.dto.PGM_BLOGSVRDto;

import lombok.extern.slf4j.Slf4j;

@Slf4j
public class PGM_PHASE2 {
    
    private int SQLCODE = 0;
    private int resultCode = 0;

    @Autowired
    private PGM_PHASE2Dao dao;

    @Autowired
    private PGM_BLOGSVR PGM_BLOGSVR;

    @Autowired
    private PGM_BLOGSVRDto PGM_BLOGSVRDto;

    public void MAIN(PGM_PHASE2Dto dto) {
        INIT(dto);
        do {
            DATA_PROCESS(dto);
        } while(dto.getWS_FLAGSDto_2().getWS_EOF_FLAG().equals(dto.getWS_FLAGSDto_2().WS_EOF));
        FINALIZE(dto);

        this.resultCode = dto.getSYS_COMMON_AREADto().getSYS_RET_CODE();
        System.exit(this.resultCode);
    }

    private void INIT(PGM_PHASE2Dto dto) {
        dto.getSYS_COMMON_AREADto().setSYS_JOB_ID(dto.getWS_PHASE_ID());
        dto.getSYS_COMMON_AREADto().setSYS_BIZ_DATE(LocalDate.now().format(DateTimeFormatter.ofPattern("yyyyMMdd")));
        dto.setWS_START_DATETIME(LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyyMMddHHmmss")));

        // INITIALIZE NETTING-TABLE.

        // ACCEPT WS-DATASRC      FROM ENVIRONMENT 'GIXSQL_DB_CONN'.
        // ACCEPT WS-USER         FROM ENVIRONMENT 'GIXSQL_USER'.
        // ACCEPT WS-PWD          FROM ENVIRONMENT 'GIXSQL_PWD'.
        
        if (dto.getWS_DB_CONNDto().getWS_DATASRC().equals("")) {
            dto.getERR_LOG_AREADto().setERR_DESCRIPTION("GIXSQL_DB_CONN NOT SET");
            SYSTEM_ERROR(dto);
            dto.getSYS_COMMON_AREADto().setSYS_RET_CODE(dto.getSYS_COMMON_AREADto().BATCH_ERROR);
            this.resultCode = dto.getSYS_COMMON_AREADto().getSYS_RET_CODE();
            System.exit(this.resultCode);
        } else {
            // CONTINUE
        }

        // OPEN INPUT IN-FILE.

        if (!dto.getWS_FILE_STATUSDto_2().getWS_IN_STAT().equals("00")) {
            dto.getERR_LOG_AREADto().setERR_DESCRIPTION("INPUT FILE OPEN ERROR");
            SYSTEM_ERROR(dto);
            dto.getSYS_COMMON_AREADto().setSYS_RET_CODE(dto.getSYS_COMMON_AREADto().BATCH_ERROR);
            this.resultCode = dto.getSYS_COMMON_AREADto().getSYS_RET_CODE();
            System.exit(this.resultCode);
        } else {
            // CONTINUE
        }
        

        // EXEC SQL 
        //     CONNECT :WS-USER IDENTIFIED BY :WS-PWD
        //             USING :WS-DATASRC
        // END-EXEC.

        // IF SQLCODE NOT = 0 THEN
        //     MOVE SQLCODE           TO ERR-SQLCODE
        //     MOVE 'DB CONNECT ERROR' TO ERR-DESCRIPTION
        //     PERFORM SYSTEM-ERROR-000
        //     SET BATCH-ERROR TO TRUE
        //     MOVE SYS-RET-CODE TO RETURN-CODE
        //     STOP RUN
        // ELSE
        //     CONTINUE
        // END-IF.

        BATCHLOG_START(dto);

        dao.delete_01(dto);
        // EXEC SQL COMMIT END-EXEC.

        READ_IN_FILE(dto);
    }

    private void DATA_PROCESS(PGM_PHASE2Dto dto){
        // INSPECT IN-REC
        //        CONVERTING 'abcdefghijklmnopqrstuvwxyz'
        //                TO 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.
        StringBuilder sb = new StringBuilder(dto.getIN_REC());
        for (int i = 0; i < sb.length(); i++) {
            int idx = "abcdefghijklmnopqrstuvwxyz".indexOf(sb.charAt(i));
            if (idx >= 0) {
                sb.setCharAt(i, "ABCDEFGHIJKLMNOPQRSTUVWXYZ".charAt(idx));
            }
        }
        dto.setIN_REC(sb.toString());

        // MOVE IN-REC TO FILE-CONTROL-REC.

        if (dto.getFILE_CONTROL_RECDto().getREC_TYPE().equals("H")) {
            dto.getWS_COUNTERSDto().setWS_SKIP_CNT(dto.getWS_COUNTERSDto().getWS_SKIP_CNT() + 1);
            log.info(" > HEADER  RECORD SKIPPED");
        } else if (dto.getFILE_CONTROL_RECDto().getREC_TYPE().equals("T")) {
            dto.getWS_COUNTERSDto().setWS_SKIP_CNT(dto.getWS_COUNTERSDto().getWS_SKIP_CNT() + 1);
            log.info(" > TRAILER RECORD SKIPPED");
        } else {
            // MOVE IN-REC TO FILE-CONTROL-REC.
            CHECK_INST(dto);
        }

        READ_IN_FILE(dto);
    }

    private void READ_IN_FILE(PGM_PHASE2Dto dto) {
        // READ IN-FILE
        //     AT END
        //         SET WS-EOF         TO TRUE
        //     NOT AT END
        //         ADD 1              TO WS-READ-CNT
        // END-READ.
    }

    private void CHECK_INST(PGM_PHASE2Dto dto) {
        dto.getDCL_TB_INST_MASTERDto().setINST_MAST_CD(dto.getTRX_RECORDDto().getINST_CD());

        dao.select_01(dto);

        if (SQLCODE == 0) {
            INSERT_DB(dto);
        } else if (SQLCODE == 100) {
            dto.getWS_COUNTERSDto().setWS_INST_SKIP_CNT(dto.getWS_COUNTERSDto().getWS_INST_SKIP_CNT() + 1);
            log.info(" > INST NOT FOUND SKIP: [" + dto.getTRX_RECORDDto().getINST_CD() + "]");
        } else {
            dto.getERR_LOG_AREADto().setERR_SQLCODE(SQLCODE);
            dto.getERR_LOG_AREADto().setERR_DESCRIPTION("INST MASTER SELECT ERROR");
            DB_ERROR(dto);
        }
    }

    private void INSERT_DB(PGM_PHASE2Dto dto) {
        dto.getDCL_TB_STG_TRXDto().setSTG_TRX_DATE(dto.getTRX_RECORDDto().getTRX_DATE());
        dto.getDCL_TB_STG_TRXDto().setSTG_TRX_SEQ(new BigDecimal(dto.getTRX_RECORDDto().getTRX_SEQ()));
        dto.getDCL_TB_STG_TRXDto().setSTG_INST_CD(dto.getTRX_RECORDDto().getINST_CD());
        dto.getDCL_TB_STG_TRXDto().setSTG_ACC_NO(dto.getTRX_RECORDDto().getACC_NO());
        dto.getDCL_TB_STG_TRXDto().setSTG_TRX_TYPE(dto.getTRX_RECORDDto().getTRX_TYPE());
        dto.getDCL_TB_STG_TRXDto().setSTG_TRX_AMT(BigDecimal.valueOf(dto.getTRX_RECORDDto().getTRX_AMT()));

        dto.getWS_WORK_AREASDto_2().setWS_FEE_AMT_COMP(dto.getDCL_TB_STG_TRXDto().getSTG_TRX_AMT().multiply(dto.getDCL_TB_INST_MASTERDto().getINST_MAST_FEE_RATE()));
        dto.getDCL_TB_STG_TRXDto().setSTG_FEE_AMT(dto.getWS_WORK_AREASDto_2().getWS_FEE_AMT_COMP());
        dto.getDCL_TB_STG_TRXDto().setSTG_PROC_STAT(dto.getWS_PROC_STAT_INIT());

        try {
            dao.insert_01(dto);

            if (SQLCODE == 0) {
                dto.getWS_COUNTERSDto().setWS_INSERT_CNT(dto.getWS_COUNTERSDto().getWS_INSERT_CNT() + 1);
                dto.getWS_COUNTERSDto().setWS_COMMIT_CNT(dto.getWS_COUNTERSDto().getWS_COMMIT_CNT() + 1);
            } else {
                dto.getWS_COUNTERSDto().setWS_ERR_CNT(dto.getWS_COUNTERSDto().getWS_ERR_CNT() + 1);
                dto.getERR_LOG_AREADto().setERR_SQLCODE(SQLCODE);
                dto.getERR_LOG_AREADto().setERR_DESCRIPTION("DB INSERT ERROR");
                DB_ERROR(dto);
            }
        } catch (Exception e) {

        }

        if (dto.getWS_COUNTERSDto().getWS_COMMIT_CNT() >= dto.getWS_COMMIT_INTERVAL()) {
            // EXEC SQL COMMIT END-EXEC
            dto.getWS_COUNTERSDto().setWS_COMMIT_CNT(0);
            PROGRESS_LOG(dto);
        } else {
            // CONTINUE
        }
    }

    private void PROGRESS_LOG(PGM_PHASE2Dto dto) {
        log.info( " >... " + dto.getWS_COUNTERSDto().getWS_INSERT_CNT() + " RECORDS INSERTED... <");
    }

    private void FINALIZE(PGM_PHASE2Dto dto) {
        if (dto.getWS_COUNTERSDto().getWS_COMMIT_CNT() > 0) {
            // EXEC SQL COMMIT END-EXEC
        } else {
            // CONTINUE
        }

        // CLOSE IN-FILE.

        BATCHLOG_END(dto);
        // EXEC SQL COMMIT            END-EXEC.

        // EXEC SQL DISCONNECT CURRENT END-EXEC.

        log.info(" > ========= PGM-PHASE2 RESULT =========");
        log.info(" > TOTAL READ   : " + dto.getWS_COUNTERSDto().getWS_READ_CNT());
        log.info(" > TOTAL INSERT : " + dto.getWS_COUNTERSDto().getWS_INSERT_CNT());
        log.info(" > SKIPPED(H/T) : " + dto.getWS_COUNTERSDto().getWS_SKIP_CNT());
        log.info(" > INST  SKIP   : " + dto.getWS_COUNTERSDto().getWS_INST_SKIP_CNT());
        log.info(" > DB ERRORS    : " + dto.getWS_COUNTERSDto().getWS_ERR_CNT());
        log.info(" > =====================================");
    }

    private void SYSTEM_ERROR(PGM_PHASE2Dto dto) {
        dto.getERR_LOG_AREADto().setERR_PGM_ID(dto.getWS_PROG_NAME());
        dto.getERR_LOG_AREADto().setERR_SEVERITY(dto.getERR_LOG_AREADto().ERR_FATAL);
        log.info("*** SYSTEM FATAL ERROR ***");
        log.info("PGM: " + dto.getERR_LOG_AREADto().getERR_PGM_ID() + " SQLCODE: " + dto.getERR_LOG_AREADto().getERR_SQLCODE());
        log.info("MSG: " + dto.getERR_LOG_AREADto().getERR_DESCRIPTION());
    }

    private void DB_ERROR(PGM_PHASE2Dto dto) {
        dto.getERR_LOG_AREADto().setERR_PGM_ID(dto.getWS_PROG_NAME());
        dto.getERR_LOG_AREADto().setERR_SEVERITY(dto.getERR_LOG_AREADto().ERR_WARN);
        dto.getSYS_COMMON_AREADto().setSYS_RET_CODE(dto.getSYS_COMMON_AREADto().BATCH_WARNING);

        log.info("*** DB ERROR *** SEQ: " + dto.getDCL_TB_STG_TRXDto().getSTG_TRX_SEQ());
        log.info("SQLCODE: " + dto.getERR_LOG_AREADto().getERR_SQLCODE() + " | MSG: " + dto.getERR_LOG_AREADto().getERR_DESCRIPTION());
    }

    private void BATCHLOG_START(PGM_PHASE2Dto dto) {
        dto.getDCL_TB_BATCH_LOGDto().setBLG_PGM_ID(dto.getWS_PROG_NAME());
        dto.getDCL_TB_BATCH_LOGDto().setBLG_BIZ_DATE(dto.getSYS_COMMON_AREADto().getSYS_BIZ_DATE());
        dto.getDCL_TB_BATCH_LOGDto().setBLG_START_DT(dto.getWS_START_DATETIME());
        dto.getDCL_TB_BATCH_LOGDto().setBLG_REMARK("PHASE2 STARTED");
        dto.getDCL_TB_BATCH_LOGDto().setBLG_ACTION("START");
        
        PGM_BLOGSVR.MAIN(PGM_BLOGSVRDto);

        if (dto.getDCL_TB_BATCH_LOGDto().getBLG_RETURN_CODE() != 0) {
            log.info(" > [WARN] BLOGSVR END FAILED. RC=" + dto.getDCL_TB_BATCH_LOGDto().getBLG_RETURN_CODE());
        } else {
            // CONTINUE
        }
    }

    private void BATCHLOG_END(PGM_PHASE2Dto dto) {
        dto.getDCL_TB_BATCH_LOGDto().setBLG_PROC_CNT(dto.getWS_COUNTERSDto().getWS_INSERT_CNT());
        dto.getDCL_TB_BATCH_LOGDto().setBLG_ERR_CNT(dto.getWS_COUNTERSDto().getWS_ERR_CNT());
        dto.getDCL_TB_BATCH_LOGDto().setBLG_ACTION("END  ");

        if (dto.getWS_COUNTERSDto().getWS_ERR_CNT() > 0) {
            dto.getDCL_TB_BATCH_LOGDto().setBLG_STAT("E");
            dto.getDCL_TB_BATCH_LOGDto().setBLG_REMARK("PHASE2 COMPLETED WITH ERRORS");
        } else {
            dto.getDCL_TB_BATCH_LOGDto().setBLG_STAT("S");
            dto.getDCL_TB_BATCH_LOGDto().setBLG_REMARK("PHASE2 COMPLETED SUCCESSFULLY");
        }

        PGM_BLOGSVR.MAIN(PGM_BLOGSVRDto);

        if (dto.getDCL_TB_BATCH_LOGDto().getBLG_RETURN_CODE() != 0) {
            log.info(" > [WARN] BLOGSVR END FAILED. RC=" + dto.getDCL_TB_BATCH_LOGDto().getBLG_RETURN_CODE());
        } else {
            // CONTINUE
        }
    }

}