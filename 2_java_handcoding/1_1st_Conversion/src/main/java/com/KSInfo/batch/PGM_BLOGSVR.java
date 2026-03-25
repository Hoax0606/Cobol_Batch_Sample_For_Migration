package com.KSInfo.batch;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;

import org.springframework.beans.factory.annotation.Autowired;

import com.KSInfo.batch.dao.PGM_BLOGSVRDao;
import com.KSInfo.batch.dto.PGM_BLOGSVRDto;
import com.KSInfo.batch.dto.DCL_TB_BATCH_LOGDto;

import lombok.extern.slf4j.Slf4j;

@Slf4j
public class PGM_BLOGSVR {
    @Autowired
    private PGM_BLOGSVRDao dao;
    //!!1.PROCEDURE                      DIVISION USING DCL-TB-BATCH-LOG.
    @Autowired
    private DCL_TB_BATCH_LOGDto DCL_TB_BATCH_LOGDto;
    

    public void MAIN(PGM_BLOGSVRDto dto){
        //!!2.PROCEDURE                      DIVISION USING DCL-TB-BATCH-LOG.
        // DCL_TB_BATCH_LOGDto DCL_TB_BATCH_LOGDto = dto.getDCL_TB_BATCH_LOGDto();

        dto.getDCL_TB_BATCH_LOGDto().setBLG_RETURN_CODE(0);

        DB_CONNECT_CHECK(dto);

        if(DCL_TB_BATCH_LOGDto.getBLG_RETURN_CODE() !=0) {
            return;
        } else {
            // CONTINUE
        }

        if (dto.getDCL_TB_BATCH_LOGDto().getBLG_ACTION().equals(dto.getDCL_TB_BATCH_LOGDto().BLG_START)) {
            BATCHLOG_START(dto);
        } 
        else if (dto.getDCL_TB_BATCH_LOGDto().getBLG_ACTION().equals(dto.getDCL_TB_BATCH_LOGDto().BLG_END)) {
            BATCHLOG_END(dto);
        } 
        else {
            // log.warn("> [BLOGSVR] UNKNOWN ACTION: " + action);
            log.info("> [BLOGSVR] UNKNOWN ACTION: " + dto.getDCL_TB_BATCH_LOGDto().getBLG_ACTION());
            DCL_TB_BATCH_LOGDto.setBLG_RETURN_CODE(8);
        }

        if (DCL_TB_BATCH_LOGDto.getBLG_RETURN_CODE() == 0) {
            // !! EXEC SQL COMMIT            END-EXEC
                // log.info("> [BLOGSVR] PROCESS SUCCESSFULLY COMMITTED.");
        } else {
             // CONTINUE
        }

        // ctx.close();
        //GOBACK.!!

    }

    private void DB_CONNECT_CHECK(PGM_BLOGSVRDto dto) {
        // ACCEPT WS-DATASRC      FROM ENVIRONMENT 'GIXSQL_DB_CONN'.
        // ACCEPT WS-USER         FROM ENVIRONMENT 'GIXSQL_USER'.
        // ACCEPT WS-PWD          FROM ENVIRONMENT 'GIXSQL_PWD'.

        if (dto.getWS_DB_CONNDto().getWS_DATASRC().equals("")) {
            log.info("> [BLOGSVR] GIXSQL_DB_CONN NOT SET, SKIP");
            DCL_TB_BATCH_LOGDto.setBLG_RETURN_CODE(8);
        }
        else {
                // EXEC SQL 
                //     CONNECT :WS-USER IDENTIFIED BY :WS-PWD
                //             USING :WS-DATASRC
                // END-EXEC.
                // IF SQLCODE = 0 THEN
                //     CONTINUE
                // ELSE
                //     MOVE SQLCODE TO WS-SQLCODE-DISP
                //     DISPLAY '> [BLOGSVR] DB CONNECT FAILED. SQLCODE='
                //             WS-SQLCODE-DISP
                //     MOVE 8 TO BLG-RETURN-CODE
                // END-IF
        }

    }

    private void BATCHLOG_START(PGM_BLOGSVRDto dto) {
        // dto.getDCL_TB_BATCH_LOGDto.setBLG_START_DT(LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyyMMddHHmmss")));
        DCL_TB_BATCH_LOGDto.setBLG_START_DT(LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyyMMddHHmmss")));
        DCL_TB_BATCH_LOGDto.setBLG_END_DT("");
        DCL_TB_BATCH_LOGDto.setBLG_STAT("R");
        DCL_TB_BATCH_LOGDto.setBLG_PROC_CNT(0);
        DCL_TB_BATCH_LOGDto.setBLG_ERR_CNT(0);

        // EXEC SQL
        //     INSERT INTO TB_BATCH_LOG
        //             (PGM_ID,        BIZ_DATE,      START_DT,
        //             END_DT,        STAT,          PROC_CNT,
        //             ERR_CNT,       REMARK)
        //     VALUES (:BLG-PGM-ID,   :BLG-BIZ-DATE, :BLG-START-DT,
        //             :BLG-END-DT,   :BLG-STAT,     :BLG-PROC-CNT,
        //             :BLG-ERR-CNT,  :BLG-REMARK)
        // END-EXEC.
        int rs1 = dao.insert_01(dto);

        // IF SQLCODE NOT = 0 THEN
        //    MOVE SQLCODE TO WS-SQLCODE-DISP
        //    DISPLAY '> [BLOGSVR] START INSERT ERROR. SQLCODE='
        //            WS-SQLCODE-DISP
        //    MOVE 8 TO BLG-RETURN-CODE
        // ELSE
        //    EXEC SQL COMMIT            END-EXEC

        //    EXEC SQL
        //        SELECT MAX(BATCH_ID)
        //          INTO :BLG-BATCH-ID
        //          FROM TB_BATCH_LOG
        //         WHERE PGM_ID   = :BLG-PGM-ID
        //           AND BIZ_DATE = :BLG-BIZ-DATE
        //    END-EXEC
        dao.select_01(dto);

        //    IF SQLCODE NOT = 0 THEN
        //        MOVE SQLCODE TO WS-SQLCODE-DISP
        //        DISPLAY '> [BLOGSVR] BATCH_ID SELECT ERROR. SQLCODE='
        //                WS-SQLCODE-DISP
        //        MOVE 8 TO BLG-RETURN-CODE
        //    ELSE
        //        CONTINUE
        //    END-IF
        // END-IF.
    }

    private void BATCHLOG_END(PGM_BLOGSVRDto dto) {
        DCL_TB_BATCH_LOGDto.setBLG_END_DT(LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyyMMddHHmmss")));

        // EXEC SQL
        //     UPDATE TB_BATCH_LOG
        //         SET END_DT   = :BLG-END-DT,
        //             STAT     = :BLG-STAT,
        //             PROC_CNT = :BLG-PROC-CNT,
        //             ERR_CNT  = :BLG-ERR-CNT,
        //             REMARK   = :BLG-REMARK
        //     WHERE BATCH_ID = :BLG-BATCH-ID
        // END-EXEC.
        
        int rs = dao.update_01(dto);

        // IF SQLCODE NOT = 0 THEN
        //     MOVE SQLCODE TO WS-SQLCODE-DISP
        //     DISPLAY '> [BLOGSVR] END UPDATE ERROR. SQLCODE='
        //             WS-SQLCODE-DISP
        //     MOVE 8 TO BLG-RETURN-CODE
        // ELSE
        //     CONTINUE
        // END-IF.
    }

}
