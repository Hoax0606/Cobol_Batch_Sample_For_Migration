package com.KSInfo.batch.dto;

import lombok.Data;

@Data
public class TRX_RECORDDto {
    private String TRX_HEADER;
    private String FILLER_1;
    private String TRX_DATE;
    private String FILLER_2;
    private String TRX_SEQ;
    private String FILLER_3;
    private String INST_CD;
    private String FILLER_4;
    private String ACC_NO;
    private String FILLER_5;
    private String TRX_TYPE;
    private String FILLER_6;
    private long TRX_AMT;
    
}
