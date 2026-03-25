package com.KSInfo.batch.dto;

import lombok.Data;
import java.math.BigDecimal;

@Data
public class DCL_TB_STG_TRXDto {
    private String STG_TRX_DATE = "";
    private BigDecimal STG_TRX_SEQ = BigDecimal.ZERO;
    private String STG_INST_CD = "";
    private String STG_ACC_NO = "";
    private String STG_TRX_TYPE = "";
    private BigDecimal STG_TRX_AMT = BigDecimal.ZERO;
    private BigDecimal STG_FEE_AMT = BigDecimal.ZERO;
    private String STG_PROC_STAT = ""; 
}