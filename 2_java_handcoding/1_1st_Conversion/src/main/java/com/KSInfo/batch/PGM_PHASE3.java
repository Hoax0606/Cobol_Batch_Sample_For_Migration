package com.KSInfo.batch;

import org.springframework.beans.factory.annotation.Autowired;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.ArrayList;
import java.math.RoundingMode;

import com.KSInfo.batch.dao.PGM_PHASE3Dao;
import com.KSInfo.batch.dto.PGM_PHASE3Dto;
import com.KSInfo.batch.PGM_BLOGSVR;

import lombok.extern.slf4j.Slf4j;

@Slf4j
public class PGM_PHASE3 {

    @Autowired
    private PGM_PHASE3Dao dao;

    @Autowired
    private PGM_BLOGSVR PGM_BLOGSVR;

    public void MAIN(PGM_PHASE3Dto dto) {
        INIT(dto);
        do {
            DATA_PROCESS(dto);
        } while(!dto.getWS_FLAGS().WS_EOF());
        FINALIZE(dto);

        dto.getSYS_COMMON_AREADto().setSYS_RET_CODE(dto.getDCL_TB_BATCH_LOGDto().getBLG_RETURN_CODE());
        System.exit(dto.getSYS_COMMON_AREADto().getSYS_RET_CODE());
    }

    private void INIT(PGM_PHASE3Dto dto) {
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
            // SET BATCH-ERROR TO TRUE
            dto.getSYS_COMMON_AREADto().setSYS_RET_CODE(dto.getDCL_TB_BATCH_LOGDto().getBLG_RETURN_CODE());
            System.exit(dto.getSYS_COMMON_AREADto().getSYS_RET_CODE());
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
        DELETE_TRX_DETAIL(dto);

        // EXEC SQL COMMIT            END-EXEC.
        // EXEC SQL OPEN C-STG-TRX    END-EXEC.

        // IF SQLCODE NOT = 0 THEN
        //     MOVE SQLCODE           TO ERR-SQLCODE
        //     MOVE 'CURSOR OPEN ERROR' TO ERR-DESCRIPTION
        //     PERFORM SYSTEM-ERROR-000
        //     SET BATCH-ERROR TO TRUE
        //     MOVE SYS-RET-CODE TO RETURN-CODE
        //     STOP RUN
        // ELSE
        //     CONTINUE
        // END-IF.
    }


    private void DATA_PROCESS(PGM_PHASE3Dto dto) {
        try {
            List<PGM_PHASE3Dto> list = dao.select_01(dto);
            for (PGM_PHASE3Dto row : list) {
                dto.getWS_COUNTERSDto_3().setWS_TOTAL_READ(
                    dto.getWS_COUNTERSDto_3().getWS_TOTAL_READ() + 1);
                JOIN_INST_MASTER(row);
            }
        } catch (Exception e) {
            dto.getERR_LOG_AREADto().setERR_DESCRIPTION("STG CURSOR FETCH ERROR");
            DB_ERROR(dto);
            // SET WS-EOF         TO TRUE
        }

        // TODO: for 문으로 바꿀 수 있는 방법 생각 또는 ASIS와 동일한 방법 고려
        // EVALUATE SQLCODE
        //     WHEN 0
        //         ADD 1              TO WS-TOTAL-READ
        //         PERFORM JOIN-INST-MASTER-000
        //     WHEN 100
        //         SET WS-EOF         TO TRUE
        //     WHEN OTHER
        //         MOVE SQLCODE       TO ERR-SQLCODE
        //         MOVE 'STG CURSOR FETCH ERROR' TO ERR-DESCRIPTION
        //         PERFORM DB-ERROR-000
        //         SET WS-EOF         TO TRUE
        // END-EVALUATE.
    }

    private void JOIN_INST_MASTER(PGM_PHASE3Dto dto) {

    }

    private void CALC_FEE(PGM_PHASE3Dto dto) {
        dto.getWS_WORK_AREASDto_2().setWS_FEE_AMT_COMP(dto.getDCL_TB_STG_TRXDto().getSTG_TRX_AMT().multiply(dto.getDCL_TB_INST_MASTERDto().getINST_MAST_FEE_RATE()).setScale(0,RoundingMode.HALF_UP));
    }




    private void DELETE_TRX_DETAIL(PGM_PHASE3Dto dto) {    
        dto.getDCL_TB_TRX_DETAILDto().setDTL_SETTLE_DATE(dto.getSYS_COMMON_AREADto().getSYS_BIZ_DATE());
   
        try {
            dao.delete_01(dto);

        } catch (Exception e) {
            System.out.println(e.getMessage());
            // dto.getERR_LOG_AREADto().setERR_SQLCODE(e.getMessage());
            dto.getERR_LOG_AREADto().setERR_DESCRIPTION("TRX_DETAIL DELETE ERROR");
            DB_ERROR(dto);
        }
    }

    private void INSERT_INST_STAT(PGM_PHASE3Dto dto) {
        dto.getDCL_TB_INST_DAILY_STATDto().setIDS_SETTLE_DATE(dto.getSYS_COMMON_AREADto().getSYS_BIZ_DATE());
        dto.getDCL_TB_INST_DAILY_STATDto().setIDS_INST_CD(dto.getNETTING_TABLE().);
    
    }

    private void DELETE_NET_SUMMARY(PGM_PHASE3Dto dto) {
        dto.getDCL_TB_NET_SUMMARYDto().setSUM_SETTLE_DATE(dto.getSYS_COMMON_AREADto().getSYS_BIZ_DATE());
    
        try {
            dao.delete_03(dto);
        } catch (Exception e) {
            // MOVE SQLCODE           TO ERR-SQLCODE
            dto.getERR_LOG_AREADto().setERR_DESCRIPTION("NET_SUMMARY DELETE ERROR");
            DB_ERROR(dto);
        }
    }

    private void OPEN_JOIN_CURSOR(PGM_PHASE3Dto dto) {
        // MOVE SYS-BIZ-DATE          TO IDS-SETTLE-DATE.
        // SET WS-JOIN-NOT-EOF        TO TRUE.

        // EXEC SQL OPEN C-DAILY-STAT-JOIN END-EXEC.

        // IF SQLCODE NOT = 0 THEN
        //     MOVE SQLCODE           TO ERR-SQLCODE
        //     MOVE 'JOIN CURSOR OPEN ERROR' TO ERR-DESCRIPTION
        //     PERFORM SYSTEM-ERROR-000
        //     SET BATCH-ERROR TO TRUE
        //     MOVE SYS-RET-CODE TO RETURN-CODE
        //     STOP RUN
        // ELSE
        //     CONTINUE
        // END-IF.
    }

    private void FETCH_AND_INSERT_SUMMARY(PGM_PHASE3Dto dto) {

    }

    private void INSERT_NET_SUMMARY(PGM_PHASE3Dto dto) {
        try {
            dao.insert_03(dto);
            // SQLCODE = 0
            dto.getWS_COUNTERSDto_3().setWS_SUMMARY_INS_CNT(
                dto.getWS_COUNTERSDto_3().getWS_SUMMARY_INS_CNT() + 1);  // ADD 1 TO WS-SUMMARY-INS-CNT
        } catch (Exception e) {
            // MOVE SQLCODE           TO ERR-SQLCODE
            dto.getERR_LOG_AREADto().setERR_DESCRIPTION("NET_SUMMARY INSERT ERROR");
            DB_ERROR(dto);
        }
    }

    private void CLOSE_JOIN_CURSOR(PGM_PHASE3Dto dto) {
        // EXEC SQL CLOSE C-DAILY-STAT-JOIN END-EXEC.

        // IF SQLCODE NOT = 0 THEN
        //     MOVE SQLCODE           TO ERR-SQLCODE
        //     MOVE 'JOIN CURSOR CLOSE ERROR' TO ERR-DESCRIPTION
        //     PERFORM DB-ERROR-000
        // ELSE
        //     CONTINUE
        // END-IF.
    }

    private void BATCHLOG_START(PGM_PHASE3Dto dto) {
        dto.getDCL_TB_BATCH_LOGDto().setBLG_PGM_ID(dto.getWS_PROG_NAME());
        dto.getDCL_TB_BATCH_LOGDto().setBLG_BIZ_DATE(dto.getSYS_COMMON_AREADto().getSYS_BIZ_DATE());
        dto.getDCL_TB_BATCH_LOGDto().setBLG_START_DT(dto.getWS_START_DATETIME());
        dto.getDCL_TB_BATCH_LOGDto().setBLG_REMARK("PHASE3 STARTED");
        dto.getDCL_TB_BATCH_LOGDto().setBLG_ACTION("START");
        
        PGM_BLOGSVR.MAIN(dto.getDCL_TB_BATCH_LOGDto());

        if (dto.getDCL_TB_BATCH_LOGDto().getBLG_RETURN_CODE() != 0) {
            log.info(" > [WARN] BLOGSVR END FAILED. RC=" + dto.getDCL_TB_BATCH_LOGDto().getBLG_RETURN_CODE());
        } else {
            // CONTINUE
        }
    }

    private void BATCHLOG_END(PGM_PHASE3Dto dto) {
        dto.getDCL_TB_BATCH_LOGDto().setBLG_PROC_CNT(dto.getWS_COUNTERSDto_3().getWS_TOTAL_READ());
        dto.getDCL_TB_BATCH_LOGDto().setBLG_ERR_CNT(dto.getWS_COUNTERSDto_3().getWS_ERR_CNT());
        dto.getDCL_TB_BATCH_LOGDto().setBLG_ACTION("END");

        if (dto.getWS_COUNTERSDto_3().getWS_ERR_CNT() > 0) {
            dto.getDCL_TB_BATCH_LOGDto().setBLG_STAT("E");
            dto.getDCL_TB_BATCH_LOGDto().setBLG_REMARK("PHASE3 COMPLETED WITH ERRORS");
        } else {
            dto.getDCL_TB_BATCH_LOGDto().setBLG_STAT("S");
            dto.getDCL_TB_BATCH_LOGDto().setBLG_REMARK("PHASE3 COMPLETED SUCCESSFULLY");
        }

        PGM_BLOGSVR.MAIN(dto.getDCL_TB_BATCH_LOGDto());

        if (dto.getDCL_TB_BATCH_LOGDto().getBLG_RETURN_CODE() != 0) {
            log.info(" > [WARN] BLOGSVR END FAILED. RC=" + dto.getDCL_TB_BATCH_LOGDto().getBLG_RETURN_CODE());
        } else {
            // CONTINUE
        }
    }

    private void PROCESS_LOG(PGM_PHASE3Dto dto) {
        log.info( " >... " + dto.getWS_COUNTERSDto_3().getWS_TOTAL_READ() + " RECORDS PROCESSED / DETAIL: " + dto.getWS_COUNTERSDto_3().getWS_DETAIL_INS_CNT());
    }

    private void SYSTEM_ERROR(PGM_PHASE3Dto dto) {
        dto.getERR_LOG_AREADto().setERR_PGM_ID(dto.getWS_PROG_NAME());
        // SET ERR-FATAL              TO TRUE.
        // SET BATCH-ERROR            TO TRUE.
        log.info("*** SYSTEM FATAL ERROR ***");
        log.info("PGM: " + dto.getERR_LOG_AREADto().getERR_PGM_ID() + " SQLCODE: " + dto.getERR_LOG_AREADto().getERR_SQLCODE());
        log.info("MSG: " + dto.getERR_LOG_AREADto().getERR_DESCRIPTION());
    } 

    private void DB_ERROR(PGM_PHASE3Dto dto) {
        dto.getERR_LOG_AREADto().setERR_PGM_ID(dto.getWS_PROG_NAME());
        // SET ERR-WARN               TO TRUE.
        // SET BATCH-WARNING          TO TRUE.

        log.info("*** DB ERROR ***");
        log.info("PGM: " + dto.getERR_LOG_AREADto().getERR_PGM_ID() + " SQLCODE: " + dto.getERR_LOG_AREADto().getERR_SQLCODE());
        log.info("MSG: " + dto.getERR_LOG_AREADto().getERR_DESCRIPTION());
    }

    private void DB_WARN(PGM_PHASE3Dto dto) {
        dto.getERR_LOG_AREADto().setERR_PGM_ID(dto.getWS_PROG_NAME());
        // SET ERR-INFO               TO TRUE.
        log.info("> [WARN] INST=[" + dto.getDCL_TB_STG_TRXDto().getSTG_INST_CD() + "] " + dto.getERR_LOG_AREADto().getERR_DESCRIPTION());
    }
}