package com.KSInfo.batch.dto;

import lombok.Data;

@Data
public class PGM_PHASE4Dto{
    private  String OUT_REC;
    //01  DATA_REC REDEFINES OUT_REC
    private REC_KEYDto REC_KEY; 
    //66  REC_KEY   RENAMES OUT_DATA_TYPE THRU OUT_INST_CD

    //COPY
    private ERR_LOG_AREADto ERR_LOG_AREA; //COPY ERR-LOG.
    private FILE_CONTROL_RECDto FILE_CONTROL_REC; //COPY ERR-LOG.
    //     01  HEADER-REC REDEFINES FILE-CONTROL-REC.
    //     01  TRAILER-REC REDEFINES FILE-CONTROL-REC.
    
    private  DCL_TB_NET_SUMMARYDto DCL_TB_NET_SUMMARY;
    private  DCL_TB_BATCH_LOGDto DCL_TB_BATCH_LOG;
    private  WS_DB_CONNDto WS_DB_CONN;
    private  int WS_OUT_STAT;
    private  WS_FLAGSDto_2 WS_FLAGS;
    private  WS_COUNTERSDto_4 WS_COUNTERS; // !!PHASE2 DTO와 이름은 같은데 필드가 다름(private int WS_ERR_CNT = 0;는 같음)
    private  WS_CALC_TOTALSDto_4 WS_CALC_TOTALS; //!!PHASE1과 DTO는 같은데 필드가 다름
    private  WS_WORK_AREASDto_4 WS_WORK_AREAS; //!!PHASE2 DTO와 이름은 같은데 필드가 다름
    private  String WS_START_DATETIME = "";
    private  String WS_BIZ_DATE_W;
    private  WS_EDIT_AREADto WS_EDIT_AREA;

    private  String WS_PROG_NAME = "PGM_PHASE4";
    private  String WS_PHASE_ID = "PHASE4";
    private  int WS_PROGRESS_INTERVAL = 10;

}

