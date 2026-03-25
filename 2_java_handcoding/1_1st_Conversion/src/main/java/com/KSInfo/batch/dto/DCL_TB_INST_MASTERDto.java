package com.KSInfo.batch.dto;

import lombok.Data;
import java.math.BigDecimal;

@Data
public class DCL_TB_INST_MASTERDto {
    private String INST_MAST_CD = "";
    private String INST_MAST_NAME = "";
    private String INST_MAST_STAT = "";
    private BigDecimal INST_MAST_FEE_RATE = BigDecimal.ZERO;

}