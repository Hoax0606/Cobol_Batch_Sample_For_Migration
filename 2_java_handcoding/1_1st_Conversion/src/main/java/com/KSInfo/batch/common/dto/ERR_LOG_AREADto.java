package com.KSInfo.batch.common.dto;

import lombok.Data;

@Data
public class ERR_LOG_AREADto {
    private String ERR_PGM_ID = "";
    private int ERR_SQLCODE = 0;
    private String ERR_SEVERITY = "";
    private String ERR_DESCRIPTION = "";
    
    // 88 ERR-INFO VALUE 'I'
    public static final String ERR_INFO = "I";
    public boolean checkERR_INFO() { return ERR_SEVERITY == ERR_INFO; }

    // 88 ERR-WARN VALUE 'W'
    public static final String ERR_WARN = "W";
    public boolean checkERR_WARN() { return ERR_SEVERITY == ERR_WARN; }

    // 88 ERR-FATAL VALUE 'F'
    public static final String ERR_FATAL = "F";
    public boolean checkERR_FATAL() { return ERR_SEVERITY == ERR_FATAL; }
}
