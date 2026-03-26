package com.KSInfo.batch.dto;

import lombok.Data;

@Data
public class PGM_PHASE2Dto{
    private String IN_REC;

    //COPY
    private SYS_COMMON_AREADto SYS_COMMON_AREADto = new SYS_COMMON_AREADto();     //COPY SYS-COM.
    private ERR_LOG_AREADto ERR_LOG_AREADto = new ERR_LOG_AREADto(); //COPY ERR-LOG.
    private FILE_CONTROL_RECDto FILE_CONTROL_RECDto = new FILE_CONTROL_RECDto(); //COPY FILE-CTRL.
    private TRX_RECORDDto TRX_RECORDDto = new TRX_RECORDDto(); //COPY TRX-REC.
    private DCL_TB_STG_TRXDto DCL_TB_STG_TRXDto = new DCL_TB_STG_TRXDto();// PHASE1과 같음 
    private DCL_TB_INST_MASTERDto DCL_TB_INST_MASTERDto = new DCL_TB_INST_MASTERDto();// PHASE1과 같음 
    private DCL_TB_BATCH_LOGDto DCL_TB_BATCH_LOGDto = new DCL_TB_BATCH_LOGDto();// PHASE1과 같음 
    private WS_FILE_STATUSDto_2 WS_FILE_STATUSDto_2 = new WS_FILE_STATUSDto_2(); // !!PHASE1 // PHASE1 과 같은 class인데 필드가 2개 없음
    private WS_FLAGSDto WS_FLAGSDto_2 = new WS_FLAGSDto(); // !!PHASE1 // PHASE1 과 같은 class인데 필드가 2개 없음
    private WS_COUNTERSDto WS_COUNTERSDto = new WS_COUNTERSDto();
    private WS_WORK_AREASDto_2 WS_WORK_AREASDto_2 = new WS_WORK_AREASDto_2(); // !! PHASE1 DTO이름은 같은데 안의 변수는 다 다름
    private WS_DB_CONNDto WS_DB_CONNDto = new WS_DB_CONNDto(); // BLOGSVR과 같음 

    private String WS_START_DATETIME = "";
    private String WS_PROG_NAME = "PGM_PHASE2";
    private String WS_PHASE_ID = "PHASE2";
    private int WS_COMMIT_INTERVAL = 1000;
    private String WS_PROC_STAT_INIT = "0";
}

