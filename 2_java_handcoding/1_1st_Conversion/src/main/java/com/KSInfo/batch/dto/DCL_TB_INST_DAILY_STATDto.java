package com.KSInfo.batch.dto;

import lombok.Data;
import java.math.BigDecimal;

@Data
public class DCL_TB_INST_DAILY_STATDto {
    private String IDS_SETTLE_DATE = "";
    private String IDS_INST_CD = "";
    private BigDecimal IDS_TOT_IN = BigDecimal.ZERO;
    private BigDecimal IDS_TOT_OUT = BigDecimal.ZERO;
    private BigDecimal IDS_NET_AMT = BigDecimal.ZERO;
    private BigDecimal IDS_TOT_FEE = BigDecimal.ZERO;
    private BigDecimal IDS_TOTAL_CNT = BigDecimal.ZERO;
 
}