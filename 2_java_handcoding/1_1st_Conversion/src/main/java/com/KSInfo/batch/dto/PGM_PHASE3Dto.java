package com.KSInfo.batch.dto;

import lombok.Data;
import java.util.ArrayList;
import java.util.List;

@Data
public class PGM_PHASE3Dto{
    private WS_DB_CONNDto WS_DB_CONN; //!!PHASE2와 동일
    //COPY
    private SYS_COMMON_AREADto SYS_COMMON_AREA;
    private ERR_LOG_AREADto ERR_LOG_AREA;


    private DCL_TB_STG_TRXDto DCL_TB_STG_TRX; //!! PHASE1과 동일
    private DCL_TB_INST_MASTERDto DCL_TB_INST_MASTER; // !! PHASE1과 동일
    private DCL_TB_NET_SUMMARYDto DCL_TB_NET_SUMMARY; //!! PHASE1과 동일
    private DCL_TB_TRX_DETAILDto DCL_TB_TRX_DETAIL; //!! PHASE1과 동일
    private DCL_TB_INST_DAILY_STATDto DCL_TB_INST_DAILY_STAT;//!! PHASE1과 동일
    private DCL_TB_BATCH_LOGDto DCL_TB_BATCH_LOG; //!! PHASE1과 동일
    private WS_FLAGSDto WS_FLAGS; //!! PHASE1과 동일
    private WS_COUNTERSDto_3 WS_COUNTERS; // !! PHASE2와 DTO이름만 같음()
    private WS_WORK_AREASDto_2 WS_WORK_AREAS; // !! PHASE2와 동일 
    private String WS_START_DATETIME = "";
    private List<NET_ENTRYDto> NETTING_TABLE = new ArrayList<>(1000);

    private String WS_PROG_NAME = "PGM_PHASE3";
    private String WS_PHASE_ID = "PHASE3";
    private int WS_COMMIT_INTERVAL = 1000;
    private String WS_PROC_STAT_DONE = "9";
}