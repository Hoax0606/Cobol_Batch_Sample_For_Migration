package com.KSInfo.batch.dto;

import lombok.Data;
import java.util.ArrayList;
import java.util.List;

@Data
public class PGM_PHASE3Dto{

    private WS_DB_CONNDto WS_DB_CONNDto = new WS_DB_CONNDto(); //!!PHASE2와 동일
    //COPY
    private SYS_COMMON_AREADto SYS_COMMON_AREADto = new SYS_COMMON_AREADto();
    private ERR_LOG_AREADto ERR_LOG_AREADto = new ERR_LOG_AREADto();

    private DCL_TB_STG_TRXDto DCL_TB_STG_TRXDto = new DCL_TB_STG_TRXDto(); //!! PHASE1과 동일
    private DCL_TB_INST_MASTERDto DCL_TB_INST_MASTERDto = new DCL_TB_INST_MASTERDto(); // !! PHASE1과 동일
    private DCL_TB_NET_SUMMARYDto DCL_TB_NET_SUMMARYDto = new DCL_TB_NET_SUMMARYDto(); //!! PHASE1과 동일
    private DCL_TB_TRX_DETAILDto DCL_TB_TRX_DETAILDto = new DCL_TB_TRX_DETAILDto(); //!! PHASE1과 동일
    private DCL_TB_INST_DAILY_STATDto DCL_TB_INST_DAILY_STATDto = new DCL_TB_INST_DAILY_STATDto();//!! PHASE1과 동일
    private DCL_TB_BATCH_LOGDto DCL_TB_BATCH_LOGDto = new DCL_TB_BATCH_LOGDto(); //!! PHASE1과 동일
    private WS_FLAGSDto WS_FLAGSDto = new WS_FLAGSDto(); //!! PHASE1과 동일
    private WS_COUNTERSDto_3 WS_COUNTERSDto_3 = new WS_COUNTERSDto_3(); // !! PHASE2와 DTO이름만 같음()
    private WS_WORK_AREASDto_2 WS_WORK_AREASDto_2 = new WS_WORK_AREASDto_2(); // !! PHASE2와 동일 
    private String WS_START_DATETIME = "";
    private NETTING_TABLEDto NETTING_TABLEDto = new NETTING_TABLEDto();

    private String WS_PROG_NAME = "PGM_PHASE3";
    private String WS_PHASE_ID = "PHASE3";
    private int WS_COMMIT_INTERVAL = 1000;
    private String WS_PROC_STAT_DONE = "9";
}