package com.KSInfo.batch.dto;

import lombok.Data;
import java.math.BigDecimal;

@Data
public class DCL_TB_TRX_DETAILDto {
    private String DTL_SETTLE_DATE = "";
    private BigDecimal DTL_TRX_SEQ = BigDecimal.ZERO;
    private String DTL_INST_CD = "";
    private String DTL_INST_NAME = "";
    private String DTL_ACC_NO = "";
    private String DTL_TRX_TYPE = "";
    private BigDecimal DTL_TRX_AMT = BigDecimal.ZERO;
    private BigDecimal DTL_STG_FEE_AMT = BigDecimal.ZERO;
    private BigDecimal DTL_FEE_RATE = BigDecimal.ZERO;
    private BigDecimal DTL_CALC_FEE_AMT = BigDecimal.ZERO;
    private String DTL_PROC_STAT = "";
    
}