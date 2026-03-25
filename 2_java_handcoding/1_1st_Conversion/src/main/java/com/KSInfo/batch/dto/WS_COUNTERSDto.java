package com.KSInfo.batch.dto;

import lombok.Data;

@Data
public class WS_COUNTERSDto {
    private long WS_READ_CNT = 0L;
    private long WS_INSERT_CNT = 0L;
    private long WS_SKIP_CNT = 0L;
    private long WS_INST_SKIP_CNT = 0L;
    private int WS_COMMIT_CNT = 0;
    private int WS_ERR_CNT = 0;
}