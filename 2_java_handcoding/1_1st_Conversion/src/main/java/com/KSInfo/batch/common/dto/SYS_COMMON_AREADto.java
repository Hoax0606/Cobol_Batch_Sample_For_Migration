package com.KSInfo.batch.common.dto;

import lombok.Data;

@Data
public class SYS_COMMON_AREADto {
    private String SYS_JOB_ID = "";
    private String SYS_BIZ_DATE = "";
    private int SYS_RET_CODE = 0;

    // 88 BATCH-WARNING VALUE 4
    public static final int BATCH_WARNING = 4;
    public boolean checkBATCH_WARNING() { return SYS_RET_CODE == BATCH_WARNING; }

    // 88 BATCH-ERROR VALUE 8
    public static final int BATCH_ERROR = 8;
    public boolean checkBATCH_ERROR() { return SYS_RET_CODE == BATCH_ERROR; }
}