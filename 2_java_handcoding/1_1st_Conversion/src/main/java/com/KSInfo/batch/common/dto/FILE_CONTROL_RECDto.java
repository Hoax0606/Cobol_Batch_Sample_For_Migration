package com.KSInfo.batch.common.dto;

import lombok.Data;

@Data
public class FILE_CONTROL_RECDto {
    private String REC_TYPE = "";
    private String REC_CONTENT = "";

    // 88 IS-HEADER VALUE 'H'
    public static final String IS_HEADER = "H";
    public boolean checkIS_HEADER() { return REC_TYPE == IS_HEADER; }

    // 88 IS-DATA VALUE 'D'
    public static final String IS_DATA = "D";
    public boolean checkIS_DATA() { return REC_TYPE == IS_DATA; }

    // 88 IS-TRAILER VALUE 'T'
    public static final String IS_TRAILER = "T";
    public boolean checkIS_TRAILER() { return REC_TYPE == IS_TRAILER; }
}