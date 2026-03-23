package com.KSInfo.batch.dto;

import lombok.Data;

@Data
public class PGM_PHASE2Dto{
    private String IN_REC;

    //COPY
    private SYS_COMMON_AREADto SYS_COMMON_AREA;     //COPY SYS-COM.
    private ERR_LOG_AREADto ERR_LOG_AREA; //COPY ERR-LOG.

    private DCL_TB_STG_TRXDto DCL_TB_STG_TRX ;// PHASE1과 같음 
    private DCL_TB_INST_MASTERDto DCL_TB_INST_MASTER ;// PHASE1과 같음 
    private DCL_TB_BATCH_LOGDto DCL_TB_BATCH_LOG ;// PHASE1과 같음 
    private WS_FILE_STATUSDto_2 WS_FILE_STATUS ; // !!PHASE1 // PHASE1 과 같은 class인데 필드가 2개 없음
    private WS_FLAGSDto_2 WS_FLAGS ; // !!PHASE1 // PHASE1 과 같은 class인데 필드가 2개 없음
    private WS_COUNTERSDto WS_COUNTERS ;
    private WS_WORK_AREASDto_2 WS_WORK_AREAS ; // !! PHASE1 DTO이름은 같은데 안의 변수는 다 다름
    private WS_DB_CONNDto WS_DB_CONN ; // BLOGSVR과 같음 

    private String WS_START_DATETIME = "";
    private String WS_PROG_NAME = "PGM_PHASE2";
    private String WS_PHASE_ID = "PHASE2";
    private int WS_COMMIT_INTERVAL = 1000;
    private String WS_PROC_STAT_INIT = "0";
}

