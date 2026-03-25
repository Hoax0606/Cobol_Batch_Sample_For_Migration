package com.KSInfo.batch.dto;

import lombok.Data;
import java.math.BigDecimal;

@Data
public class NET_ENTRYDto {

    private String NET_INST_CD = "";
    private BigDecimal NET_TOT_IN = BigDecimal.ZERO;
    private BigDecimal NET_TOT_OUT = BigDecimal.ZERO;
    private BigDecimal NET_TOT_FEE = BigDecimal.ZERO;
    private long NET_CNT = 0L;

}
