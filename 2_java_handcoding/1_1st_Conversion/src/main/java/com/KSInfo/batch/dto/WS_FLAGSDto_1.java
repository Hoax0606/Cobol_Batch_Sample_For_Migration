package com.KSInfo.batch.dto;

import lombok.Data;

@Data
public class WS_FLAGSDto_1 {
    private String WS_EOF_FLAG = "N";
    private String WS_VALID_FLAG = "Y";
    private String WS_SORT_EOF_FLAG = "N";

    // 88 WS_EOF VALUE 'Y'
    public static final String WS_EOF = "Y";
    public boolean checkWS_EOF() { return WS_EOF_FLAG == WS_EOF; }

    // 88 WS_NOT_EOF VALUE 'N'
    public static final String WS_NOT_EOF = "N";
    public boolean checkWS_NOT_EOF() { return WS_EOF_FLAG == WS_NOT_EOF; }

    // 88 WS_VALID_FLAGF VALUE 'Y'
    public static final String WS_VALID = "Y";
    public boolean checkWS_JOIN_EOF() { return WS_VALID_FLAG == WS_VALID; }

    // 88 WS_VALID_FLAG VALUE 'N'
    public static final String WS_INVALID = "N";
    public boolean checkWS_JOIN_NOT_EOF() { return WS_VALID_FLAG == WS_INVALID; }

    // 88 WS_SORT_EOF_FLAG VALUE 'Y'
    public static final String WS_SORT_EOF = "Y";
    public boolean checkWS_FOUND() { return WS_SORT_EOF_FLAG == WS_SORT_EOF; }

}