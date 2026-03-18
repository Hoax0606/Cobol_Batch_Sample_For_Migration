package com.KSInfo.batch.dto;

import lombok.Data;

@Data
public class PGM_BLOGSVRDto {
    
    private WS_DB_CONNDto WS_DB_CONN;
    private WS_WORK_AREASDto WS_WORK_AREAS;
    private DCL_TB_BATCH_LOG DCL_TB_BATCH_LOG;
}