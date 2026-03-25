package com.KSInfo.batch.dto;

import lombok.Data;
import java.math.BigDecimal;

@Data
public class DCL_TB_BATCH_LOGDto {

    private String BLG_ACTION = "";
    private String BLG_PGM_ID = "";
    private String BLG_BIZ_DATE = "";
    private String BLG_START_DT = "";
    private String BLG_END_DT = "";
    private String BLG_STAT = "";
    private long BLG_PROC_CNT = 0L;
    private long BLG_ERR_CNT = 0L;
    private String BLG_REMARK = "";
    private BigDecimal BLG_BATCH_ID = BigDecimal.ZERO;
    private int BLG_RETURN_CODE = 0;

    // 88 BLG-START VALUE 'START'
    public static final String BLG_START = "START";
    public boolean checkBLG_START() { return BLG_ACTION == BLG_START; }

    // 88 BATCH-ERROR VALUE 'END'
    public static final String BLG_END  = "END";
    public boolean checkBLG_END () { return BLG_ACTION == BLG_END ; }
    
}
