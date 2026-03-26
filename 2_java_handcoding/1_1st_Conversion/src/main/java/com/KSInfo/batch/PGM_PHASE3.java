package com.KSInfo.batch;

import org.springframework.beans.factory.annotation.Autowired;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.math.RoundingMode;
import java.math.BigDecimal;

import com.KSInfo.batch.dao.PGM_PHASE3Dao;
import com.KSInfo.batch.dto.PGM_PHASE3Dto;
import com.KSInfo.batch.dto.PGM_BLOGSVRDto;
import lombok.extern.slf4j.Slf4j;

@Slf4j
public class PGM_PHASE3 {

    private int SQLCODE = 0;
    // private int NET_IDX;
    private int resultCode;

    @Autowired
    private PGM_PHASE3Dao dao;

    @Autowired
    private PGM_BLOGSVR PGM_BLOGSVR;

    @Autowired
    private PGM_BLOGSVRDto PGM_BLOGSVRDto;

    public void MAIN(PGM_PHASE3Dto dto) {
        INIT(dto);
        while (!dto.getWS_FLAGSDto().getWS_EOF_FLAG().equals(dto.getWS_FLAGSDto().WS_EOF)) {
            DATA_PROCESS(dto);
        }
        FINALIZE(dto);

        this.resultCode = dto.getSYS_COMMON_AREADto().getSYS_RET_CODE();
        System.exit(this.resultCode);
    }

    private void INIT(PGM_PHASE3Dto dto) {
        dto.getSYS_COMMON_AREADto().setSYS_JOB_ID(dto.getWS_PHASE_ID());
        dto.getSYS_COMMON_AREADto().setSYS_BIZ_DATE(LocalDate.now().format(DateTimeFormatter.ofPattern("yyyyMMdd")));
        dto.setWS_START_DATETIME(LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyyMMddHHmmss")));

        // INITIALIZE NETTING-TABLE.

        // ACCEPT WS-DATASRC FROM ENVIRONMENT 'GIXSQL_DB_CONN'.
        // ACCEPT WS-USER FROM ENVIRONMENT 'GIXSQL_USER'.
        // ACCEPT WS-PWD FROM ENVIRONMENT 'GIXSQL_PWD'.

        if (dto.getWS_DB_CONNDto().getWS_DATASRC().equals("")) {
            dto.getWS_COUNTERSDto_3().setWS_ERR_CNT(SQLCODE);
            dto.getERR_LOG_AREADto().setERR_DESCRIPTION("GIXSQL_DB_CONN NOT SET");
            SYSTEM_ERROR(dto);
            dto.getSYS_COMMON_AREADto().setSYS_RET_CODE(dto.getSYS_COMMON_AREADto().BATCH_ERROR);
            dto.getDCL_TB_BATCH_LOGDto().setBLG_RETURN_CODE(dto.getSYS_COMMON_AREADto().getSYS_RET_CODE());
            System.exit(dto.getSYS_COMMON_AREADto().getSYS_RET_CODE());
        } else {
            // CONTINUE
        }

        // EXEC SQL
        // CONNECT :WS-USER IDENTIFIED BY :WS-PWD
        // USING :WS-DATASRC
        // END-EXEC.

        if (SQLCODE != 0) {
            dto.getWS_COUNTERSDto_3().setWS_ERR_CNT(SQLCODE);
            dto.getERR_LOG_AREADto().setERR_DESCRIPTION("DB CONNECT ERROR");
            SYSTEM_ERROR(dto);
            dto.getSYS_COMMON_AREADto().setSYS_RET_CODE(dto.getSYS_COMMON_AREADto().BATCH_ERROR);
            this.resultCode = dto.getSYS_COMMON_AREADto().getSYS_RET_CODE();
            System.exit(this.resultCode);
        } else {
            // CONTINUE
        }

        BATCHLOG_START(dto);
        DELETE_TRX_DETAIL(dto);

        // EXEC SQL COMMIT END-EXEC.
        // EXEC SQL OPEN C-STG-TRX END-EXEC.

        if (SQLCODE != 0) {
            dto.getWS_COUNTERSDto_3().setWS_ERR_CNT(SQLCODE);
            dto.getERR_LOG_AREADto().setERR_DESCRIPTION("CURSOR OPEN ERROR");
            SYSTEM_ERROR(dto);
            dto.getSYS_COMMON_AREADto().setSYS_RET_CODE(dto.getSYS_COMMON_AREADto().BATCH_ERROR);
            this.resultCode = dto.getSYS_COMMON_AREADto().getSYS_RET_CODE();
            System.exit(this.resultCode);
        } else {
            // CONTINUE
        }
    }

    private void DATA_PROCESS(PGM_PHASE3Dto dto) {
        // EXEC SQL
        // FETCH C-STG-TRX
        // INTO :STG-TRX-DATE, :STG-TRX-SEQ,
        // :STG-INST-CD, :STG-ACC-NO,
        // :STG-TRX-TYPE, :STG-TRX-AMT,
        // :STG-FEE-AMT
        // END-EXEC.

        if (SQLCODE == 0) {
            dto.getWS_COUNTERSDto_3().setWS_TOTAL_READ(dto.getWS_COUNTERSDto_3().getWS_TOTAL_READ() + 1);
            JOIN_INST_MASTER(dto);
        } else if (SQLCODE == 100) {
            dto.getWS_FLAGSDto().setWS_EOF_FLAG(dto.getWS_FLAGSDto().WS_EOF);
        } else {
            dto.getWS_COUNTERSDto_3().setWS_ERR_CNT(SQLCODE);
            dto.getERR_LOG_AREADto().setERR_DESCRIPTION("STG CURSOR FETCH ERROR");
            DB_ERROR(dto);
            dto.getWS_FLAGSDto().setWS_EOF_FLAG(dto.getWS_FLAGSDto().WS_EOF);
        }
    }

    private void JOIN_INST_MASTER(PGM_PHASE3Dto dto) {
        dto.getDCL_TB_STG_TRXDto().setSTG_INST_CD(null);

        dao.select_03(dto);

        if (SQLCODE == 0) {
            CALC_FEE(dto);
            INSERT_TRX_DETAIL(dto);
            AGGREGATE_MEMORY(dto);
            UPDATE_STG_STAT(dto);
            CHUNK_COMMIT(dto);
        } else if (SQLCODE == 100) {
            dto.getWS_COUNTERSDto_3().setWS_ERR_CNT(dto.getWS_COUNTERSDto_3().getWS_ERR_CNT() + 1);
            dto.getERR_LOG_AREADto().setERR_DESCRIPTION("INST NOT FOUND IN MASTER");
            DB_WARN(dto);
        } else {
            dto.getWS_COUNTERSDto_3().setWS_ERR_CNT(SQLCODE);
            dto.getERR_LOG_AREADto().setERR_DESCRIPTION("INST MASTER JOIN SELECT ERROR");
            DB_ERROR(dto);
        }
    }

    private void CALC_FEE(PGM_PHASE3Dto dto) {
        dto.getWS_WORK_AREASDto_3().setWS_FEE_WORK(dto.getDCL_TB_STG_TRXDto().getSTG_TRX_AMT()
                .multiply(dto.getDCL_TB_INST_MASTERDto().getINST_MAST_FEE_RATE()).setScale(0, RoundingMode.HALF_UP));
    }

    private void INSERT_TRX_DETAIL(PGM_PHASE3Dto dto) {
        dto.getDCL_TB_TRX_DETAILDto().setDTL_SETTLE_DATE(dto.getSYS_COMMON_AREADto().getSYS_BIZ_DATE());
        dto.getDCL_TB_TRX_DETAILDto().setDTL_TRX_SEQ(dto.getDCL_TB_STG_TRXDto().getSTG_TRX_SEQ());
        dto.getDCL_TB_TRX_DETAILDto().setDTL_INST_CD(dto.getDCL_TB_STG_TRXDto().getSTG_INST_CD());
        dto.getDCL_TB_TRX_DETAILDto().setDTL_INST_NAME(dto.getDCL_TB_INST_MASTERDto().getINST_MAST_NAME());
        dto.getDCL_TB_TRX_DETAILDto().setDTL_ACC_NO(dto.getDCL_TB_STG_TRXDto().getSTG_ACC_NO());
        dto.getDCL_TB_TRX_DETAILDto().setDTL_TRX_TYPE(dto.getDCL_TB_STG_TRXDto().getSTG_TRX_TYPE());
        dto.getDCL_TB_TRX_DETAILDto().setDTL_TRX_AMT(dto.getDCL_TB_STG_TRXDto().getSTG_TRX_AMT());
        dto.getDCL_TB_TRX_DETAILDto().setDTL_STG_FEE_AMT(dto.getDCL_TB_STG_TRXDto().getSTG_FEE_AMT());
        dto.getDCL_TB_TRX_DETAILDto().setDTL_FEE_RATE(dto.getDCL_TB_INST_MASTERDto().getINST_MAST_FEE_RATE());
        dto.getDCL_TB_TRX_DETAILDto().setDTL_CALC_FEE_AMT(dto.getWS_WORK_AREASDto_3().getWS_FEE_WORK());
        dto.getDCL_TB_TRX_DETAILDto().setDTL_PROC_STAT(dto.getWS_PROC_STAT_DONE());

        try {
            dao.insert_01(dto);

            if (SQLCODE == 0) {
                dto.getWS_COUNTERSDto_3().setWS_DETAIL_INS_CNT(dto.getWS_COUNTERSDto_3().getWS_DETAIL_INS_CNT() + 1);
            } else {
                dto.getWS_COUNTERSDto_3().setWS_ERR_CNT(dto.getWS_COUNTERSDto_3().getWS_ERR_CNT() + 1);
                dto.getWS_COUNTERSDto_3().setWS_ERR_CNT(SQLCODE);
                dto.getERR_LOG_AREADto().setERR_DESCRIPTION("TRX_DETAIL INSERT ERROR");
                DB_ERROR(dto);
            }
        } catch (Exception e) {

        }
    }

    private void AGGREGATE_MEMORY(PGM_PHASE3Dto dto) {
        dto.getWS_FLAGSDto().setWS_FOUND_FLAG(dto.getWS_FLAGSDto().WS_NOT_FOUND);

        for (int NET_IDX = 1; NET_IDX <= dto.getWS_NET_MAX_IDX()
                && !dto.getWS_FLAGSDto().getWS_FOUND_FLAG().equals(dto.getWS_FLAGSDto().WS_FOUND); NET_IDX++) {
            dto.getNETTING_TABLEDto().setNET_IDX(NET_IDX);
            if (dto.getNETTING_TABLEDto().getNET_ENTRYDto()[NET_IDX].getNET_INST_CD().equals(dto.getDCL_TB_STG_TRXDto()
                    .getSTG_INST_CD())) {
                dto.getWS_FLAGSDto().setWS_FOUND_FLAG(dto.getWS_FLAGSDto().WS_FOUND);
                dto.getNETTING_TABLEDto().getNET_ENTRYDto()[NET_IDX]
                        .setNET_CNT(dto.getNETTING_TABLEDto().getNET_ENTRYDto()[NET_IDX].getNET_CNT() + 1);
                dto.getNETTING_TABLEDto().getNET_ENTRYDto()[NET_IDX]
                        .setNET_TOT_FEE(dto.getNETTING_TABLEDto().getNET_ENTRYDto()[NET_IDX].getNET_TOT_FEE()
                                .add(dto.getWS_WORK_AREASDto_3().getWS_FEE_WORK()));
                if (dto.getDCL_TB_STG_TRXDto().getSTG_TRX_TYPE().equals("I")) {
                    dto.getNETTING_TABLEDto().getNET_ENTRYDto()[NET_IDX]
                            .setNET_TOT_IN(dto.getNETTING_TABLEDto().getNET_ENTRYDto()[NET_IDX]
                                    .getNET_TOT_IN().add(dto.getDCL_TB_STG_TRXDto().getSTG_TRX_AMT()));
                } else {
                    dto.getNETTING_TABLEDto().getNET_ENTRYDto()[NET_IDX]
                            .setNET_TOT_OUT(dto.getNETTING_TABLEDto().getNET_ENTRYDto()[NET_IDX]
                                    .getNET_TOT_OUT().add(dto.getDCL_TB_STG_TRXDto().getSTG_TRX_AMT()));
                }
            } else {
                // CONTINUE
            }
        }

        if (dto.getWS_FLAGSDto().getWS_FOUND_FLAG().equals(dto.getWS_FLAGSDto().WS_NOT_FOUND)) {
            dto.setWS_NET_MAX_IDX(dto.getWS_NET_MAX_IDX() + 1);
            dto.getNETTING_TABLEDto().setNET_IDX(dto.getWS_NET_MAX_IDX());
            dto.getNETTING_TABLEDto().getNET_ENTRYDto()[dto.getNETTING_TABLEDto().getNET_IDX()]
                    .setNET_INST_CD(dto.getDCL_TB_STG_TRXDto().getSTG_INST_CD());
            dto.getNETTING_TABLEDto().getNET_ENTRYDto()[dto.getNETTING_TABLEDto().getNET_IDX()].setNET_CNT(1);
            dto.getNETTING_TABLEDto().getNET_ENTRYDto()[dto.getNETTING_TABLEDto().getNET_IDX()]
                    .setNET_TOT_FEE(dto.getWS_WORK_AREASDto_3().getWS_FEE_WORK());
            dto.getNETTING_TABLEDto().getNET_ENTRYDto()[dto.getNETTING_TABLEDto().getNET_IDX()]
                    .setNET_TOT_IN(BigDecimal.valueOf(0));
            dto.getNETTING_TABLEDto().getNET_ENTRYDto()[dto.getNETTING_TABLEDto().getNET_IDX()]
                    .setNET_TOT_OUT(BigDecimal.valueOf(0));
            if (dto.getDCL_TB_STG_TRXDto().getSTG_TRX_TYPE().equals("I")) {
                dto.getNETTING_TABLEDto().getNET_ENTRYDto()[dto.getNETTING_TABLEDto().getNET_IDX()]
                        .setNET_TOT_IN(dto.getDCL_TB_STG_TRXDto().getSTG_TRX_AMT());
            } else {
                dto.getNETTING_TABLEDto().getNET_ENTRYDto()[dto.getNETTING_TABLEDto().getNET_IDX()]
                        .setNET_TOT_OUT(dto.getDCL_TB_STG_TRXDto().getSTG_TRX_AMT());
            }
        } else {
            // CONTINUE
        }
    }

    private void UPDATE_STG_STAT(PGM_PHASE3Dto dto) {
        try {
            dao.update_01(dto);

            if (SQLCODE == 0) {
                dto.getWS_COUNTERSDto_3().setWS_STAT_UPD_CNT(dto.getWS_COUNTERSDto_3().getWS_STAT_UPD_CNT() + 1);
            } else {
                dto.getWS_COUNTERSDto_3().setWS_ERR_CNT(dto.getWS_COUNTERSDto_3().getWS_ERR_CNT() + 1);
                dto.getWS_COUNTERSDto_3().setWS_ERR_CNT(SQLCODE);
                dto.getERR_LOG_AREADto().setERR_DESCRIPTION("STG_TRX UPDATE ERROR");
                DB_ERROR(dto);
            }
        } catch (Exception e) {

        }
    }

    private void CHUNK_COMMIT(PGM_PHASE3Dto dto) {
        dto.getWS_COUNTERSDto_3().setWS_COMMIT_CNT(dto.getWS_COUNTERSDto_3().getWS_COMMIT_CNT() + 1);

        if (dto.getWS_COUNTERSDto_3().getWS_COMMIT_CNT() > dto.getWS_COMMIT_INTERVAL()) {
            // EXEC SQL COMMIT END-EXEC
            dto.getWS_COUNTERSDto_3().setWS_COMMIT_CNT(0);
            PROGRESS_LOG(dto);
        } else {
            // CONTINUE
        }
    }

    private void FINALIZE(PGM_PHASE3Dto dto) {
        // EXEC SQL CLOSE C-STG-TRX END-EXEC.

        if (dto.getWS_COUNTERSDto_3().getWS_COMMIT_CNT() > 0) {
            // EXEC SQL COMMIT END-EXEC
        } else {
            // CONTINUE
        }

        DELETE_INST_STAT(dto);
        // EXEC SQL COMMIT END-EXEC.

        for (int NET_IDX = 1; NET_IDX <= dto.getWS_NET_MAX_IDX(); NET_IDX++) {
            dto.getNETTING_TABLEDto().setNET_IDX(NET_IDX);
            INSERT_INST_STAT(dto);
        }
        // EXEC SQL COMMIT END-EXEC.

        DELETE_NET_SUMMARY(dto);
        OPEN_JOIN_CURSOR(dto);
        while (!dto.getWS_FLAGSDto().getWS_JOIN_EOF_FLAG().equals(dto.getWS_FLAGSDto().WS_JOIN_EOF)) {
            FETCH_AND_INSERT_SUMMARY(dto);
        }
        CLOSE_JOIN_CURSOR(dto);

        // EXEC SQL COMMIT END-EXEC.

        BATCHLOG_END(dto);
        // EXEC SQL COMMIT END-EXEC.

        log.info(null);

        log.info(" > ========= PGM-PHASE3 RESULT =========");
        log.info("  > TOTAL READ       : " + dto.getWS_COUNTERSDto_3().getWS_TOTAL_READ());
        log.info("  > DETAIL INSERT    : " + dto.getWS_COUNTERSDto_3().getWS_DETAIL_INS_CNT());
        log.info("  > STG STAT UPDATE  : " + dto.getWS_COUNTERSDto_3().getWS_STAT_UPD_CNT());
        log.info("  > SUMMARY INSERT   : " + dto.getWS_COUNTERSDto_3().getWS_SUMMARY_INS_CNT());
        log.info("  > INST COUNT       : " + dto.getWS_NET_MAX_IDX());
        log.info("  > ERROR COUNT      : " + dto.getWS_COUNTERSDto_3().getWS_ERR_CNT());
        log.info("  > =====================================");

        // EXEC SQL DISCONNECT CURRENT END-EXEC.
    }

    private void DELETE_TRX_DETAIL(PGM_PHASE3Dto dto) {
        dto.getDCL_TB_TRX_DETAILDto().setDTL_SETTLE_DATE(dto.getSYS_COMMON_AREADto().getSYS_BIZ_DATE());

        try {
            dao.delete_01(dto);

            if (SQLCODE != 0 && SQLCODE != 100) {
                dto.getWS_COUNTERSDto_3().setWS_ERR_CNT(SQLCODE);
                dto.getERR_LOG_AREADto().setERR_DESCRIPTION("TRX_DETAIL DELETE ERROR");
                DB_ERROR(dto);
            } else {
                // CONTINUE
            }
        } catch (Exception e) {

        }
    }

    private void DELETE_INST_STAT(PGM_PHASE3Dto dto) {
        dto.getDCL_TB_INST_DAILY_STATDto().setIDS_SETTLE_DATE(dto.getSYS_COMMON_AREADto().getSYS_BIZ_DATE());

        try {
            dao.delete_02(dto);

            if (SQLCODE != 0 && SQLCODE != 100) {
                dto.getWS_COUNTERSDto_3().setWS_ERR_CNT(SQLCODE);
                dto.getERR_LOG_AREADto().setERR_DESCRIPTION("INST_STAT DELETE ERROR");
                DB_ERROR(dto);
            } else {
                // CONTINUE
            }
        } catch (Exception e) {

        }
    }

    private void INSERT_INST_STAT(PGM_PHASE3Dto dto) {
        dto.getDCL_TB_INST_DAILY_STATDto().setIDS_SETTLE_DATE(dto.getSYS_COMMON_AREADto().getSYS_BIZ_DATE());
        dto.getDCL_TB_INST_DAILY_STATDto()
                .setIDS_INST_CD(dto.getNETTING_TABLEDto().getNET_ENTRYDto()[dto.getNETTING_TABLEDto().getNET_IDX()]
                        .getNET_INST_CD());
        dto.getDCL_TB_INST_DAILY_STATDto()
                .setIDS_TOT_IN(dto.getNETTING_TABLEDto().getNET_ENTRYDto()[dto.getNETTING_TABLEDto().getNET_IDX()]
                        .getNET_TOT_IN());
        dto.getDCL_TB_INST_DAILY_STATDto()
                .setIDS_TOT_OUT(dto.getNETTING_TABLEDto().getNET_ENTRYDto()[dto.getNETTING_TABLEDto().getNET_IDX()]
                        .getNET_TOT_OUT());
        dto.getDCL_TB_INST_DAILY_STATDto()
                .setIDS_NET_AMT(dto.getNETTING_TABLEDto().getNET_ENTRYDto()[dto.getNETTING_TABLEDto().getNET_IDX()]
                        .getNET_TOT_IN()
                        .add(dto.getNETTING_TABLEDto().getNET_ENTRYDto()[dto.getNETTING_TABLEDto().getNET_IDX()]
                                .getNET_TOT_OUT()));
        dto.getDCL_TB_INST_DAILY_STATDto()
                .setIDS_TOT_FEE(dto.getNETTING_TABLEDto().getNET_ENTRYDto()[dto.getNETTING_TABLEDto().getNET_IDX()]
                        .getNET_TOT_FEE());
        dto.getDCL_TB_INST_DAILY_STATDto()
                .setIDS_TOTAL_CNT(BigDecimal
                        .valueOf(dto.getNETTING_TABLEDto().getNET_ENTRYDto()[dto.getNETTING_TABLEDto().getNET_IDX()]
                                .getNET_CNT()));

        try {
            dao.insert_02(dto);

            if (SQLCODE != 0) {
                dto.getWS_COUNTERSDto_3().setWS_ERR_CNT(SQLCODE);
                dto.getERR_LOG_AREADto().setERR_DESCRIPTION("INST_STAT INSERT ERROR");
                DB_ERROR(dto);
            } else {
                // CONTINUE
            }
        } catch (Exception e) {

        }
    }

    private void DELETE_NET_SUMMARY(PGM_PHASE3Dto dto) {
        dto.getDCL_TB_NET_SUMMARYDto().setSUM_SETTLE_DATE(dto.getSYS_COMMON_AREADto().getSYS_BIZ_DATE());

        try {
            dao.delete_03(dto);

            if (SQLCODE != 0 && SQLCODE != 100) {
                dto.getWS_COUNTERSDto_3().setWS_ERR_CNT(SQLCODE);
                dto.getERR_LOG_AREADto().setERR_DESCRIPTION("NET_SUMMARY DELETE ERROR");
                DB_ERROR(dto);
            } else {
                // CONTINUE
            }
        } catch (Exception e) {

        }
    }

    private void OPEN_JOIN_CURSOR(PGM_PHASE3Dto dto) {
        dto.getDCL_TB_INST_DAILY_STATDto().setIDS_SETTLE_DATE(dto.getSYS_COMMON_AREADto().getSYS_BIZ_DATE());
        dto.getWS_FLAGSDto().setWS_JOIN_EOF_FLAG(dto.getWS_FLAGSDto().WS_JOIN_NOT_EOF);

        // EXEC SQL OPEN C-DAILY-STAT-JOIN END-EXEC.

        if (SQLCODE != 0) {
            dto.getWS_COUNTERSDto_3().setWS_ERR_CNT(SQLCODE);
            dto.getERR_LOG_AREADto().setERR_DESCRIPTION("JOIN CURSOR OPEN ERROR");
            SYSTEM_ERROR(dto);
            dto.getSYS_COMMON_AREADto().setSYS_RET_CODE(dto.getSYS_COMMON_AREADto().BATCH_ERROR);
            this.resultCode = dto.getSYS_COMMON_AREADto().getSYS_RET_CODE();
            System.exit(this.resultCode);
        } else {
            // CONTINUE;
        }
    }

    private void FETCH_AND_INSERT_SUMMARY(PGM_PHASE3Dto dto) {
        // EXEC SQL
        // FETCH C-DAILY-STAT-JOIN
        // INTO :SUM-SETTLE-DATE, :SUM-INST-CD,
        // :SUM-INST-NAME, :SUM-FEE-RATE,
        // :SUM-TOT-IN, :SUM-TOT-OUT,
        // :SUM-NET-AMT, :SUM-TOT-FEE,
        // :SUM-TOT-CNT
        // END-EXEC.

        if (SQLCODE == 0) {
            INSERT_NET_SUMMARY(dto);
        } else if (SQLCODE == 100) {
            dto.getWS_FLAGSDto().setWS_JOIN_EOF_FLAG(dto.getWS_FLAGSDto().WS_JOIN_EOF);
        } else {
            dto.getWS_COUNTERSDto_3().setWS_ERR_CNT(SQLCODE);
            dto.getERR_LOG_AREADto().setERR_DESCRIPTION("JOIN CURSOR FETCH ERROR");
            DB_ERROR(dto);
            dto.getWS_FLAGSDto().setWS_JOIN_EOF_FLAG(dto.getWS_FLAGSDto().WS_JOIN_EOF);
        }
    }

    private void INSERT_NET_SUMMARY(PGM_PHASE3Dto dto) {
        try {
            dao.insert_03(dto);

            if (SQLCODE == 0) {
                dto.getWS_COUNTERSDto_3().setWS_SUMMARY_INS_CNT(dto.getWS_COUNTERSDto_3().getWS_SUMMARY_INS_CNT() + 1);
            } else {
                dto.getWS_COUNTERSDto_3().setWS_ERR_CNT(SQLCODE);
                dto.getERR_LOG_AREADto().setERR_DESCRIPTION("NET_SUMMARY INSERT ERROR");
                DB_ERROR(dto);
            }
        } catch (Exception e) {

        }
    }

    private void CLOSE_JOIN_CURSOR(PGM_PHASE3Dto dto) {
        // EXEC SQL CLOSE C-DAILY-STAT-JOIN END-EXEC.

        if (SQLCODE != 0) {
            // IF SQLCODE NOT = 0 THEN
            dto.getWS_COUNTERSDto_3().setWS_ERR_CNT(SQLCODE);
            dto.getERR_LOG_AREADto().setERR_DESCRIPTION("JOIN CURSOR CLOSE ERROR");
            DB_ERROR(dto);
        } else {
            // CONTINUE
        }
    }

    private void BATCHLOG_START(PGM_PHASE3Dto dto) {
        dto.getDCL_TB_BATCH_LOGDto().setBLG_PGM_ID(dto.getWS_PROG_NAME());
        dto.getDCL_TB_BATCH_LOGDto().setBLG_BIZ_DATE(dto.getSYS_COMMON_AREADto().getSYS_BIZ_DATE());
        dto.getDCL_TB_BATCH_LOGDto().setBLG_START_DT(dto.getWS_START_DATETIME());
        dto.getDCL_TB_BATCH_LOGDto().setBLG_REMARK("PHASE3 STARTED");
        dto.getDCL_TB_BATCH_LOGDto().setBLG_ACTION("START");

        PGM_BLOGSVR.MAIN(PGM_BLOGSVRDto);

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

        PGM_BLOGSVR.MAIN(PGM_BLOGSVRDto);

        if (dto.getDCL_TB_BATCH_LOGDto().getBLG_RETURN_CODE() != 0) {
            log.info(" > [WARN] BLOGSVR END FAILED. RC=" + dto.getDCL_TB_BATCH_LOGDto().getBLG_RETURN_CODE());
        } else {
            // CONTINUE
        }
    }

    private void PROGRESS_LOG(PGM_PHASE3Dto dto) {
        log.info(" >... " + dto.getWS_COUNTERSDto_3().getWS_TOTAL_READ() + " RECORDS PROCESSED / DETAIL: "
                + dto.getWS_COUNTERSDto_3().getWS_DETAIL_INS_CNT());
    }

    private void SYSTEM_ERROR(PGM_PHASE3Dto dto) {
        dto.getERR_LOG_AREADto().setERR_PGM_ID(dto.getWS_PROG_NAME());
        dto.getERR_LOG_AREADto().setERR_SEVERITY(dto.getERR_LOG_AREADto().ERR_FATAL);
        dto.getSYS_COMMON_AREADto().setSYS_RET_CODE(dto.getSYS_COMMON_AREADto().BATCH_ERROR);
        log.info("*** SYSTEM FATAL ERROR ***");
        log.info("PGM: " + dto.getERR_LOG_AREADto().getERR_PGM_ID() + " SQLCODE: "
                + dto.getERR_LOG_AREADto().getERR_SQLCODE());
        log.info("MSG: " + dto.getERR_LOG_AREADto().getERR_DESCRIPTION());
    }

    private void DB_ERROR(PGM_PHASE3Dto dto) {
        dto.getERR_LOG_AREADto().setERR_PGM_ID(dto.getWS_PROG_NAME());
        dto.getERR_LOG_AREADto().setERR_SEVERITY(dto.getERR_LOG_AREADto().ERR_WARN);
        dto.getSYS_COMMON_AREADto().setSYS_RET_CODE(dto.getSYS_COMMON_AREADto().BATCH_WARNING);
        log.info("*** DB ERROR ***");
        log.info("PGM: " + dto.getERR_LOG_AREADto().getERR_PGM_ID() + " SQLCODE: "
                + dto.getERR_LOG_AREADto().getERR_SQLCODE());
        log.info("MSG: " + dto.getERR_LOG_AREADto().getERR_DESCRIPTION());
    }

    private void DB_WARN(PGM_PHASE3Dto dto) {
        dto.getERR_LOG_AREADto().setERR_PGM_ID(dto.getWS_PROG_NAME());
        dto.getERR_LOG_AREADto().setERR_SEVERITY(dto.getERR_LOG_AREADto().ERR_INFO);
        log.info("> [WARN] INST=[" + dto.getDCL_TB_STG_TRXDto().getSTG_INST_CD() + "] "
                + dto.getERR_LOG_AREADto().getERR_DESCRIPTION());
    }
}