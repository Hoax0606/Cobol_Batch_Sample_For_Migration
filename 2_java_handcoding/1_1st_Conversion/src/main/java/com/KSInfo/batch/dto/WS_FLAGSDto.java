package com.KSInfo.batch.dto;

import lombok.Data;

@Data
public class WS_FLAGSDto {
    private String WS_EOF_FLAG = "N";
    private String WS_JOIN_EOF_FLAG = "N";
    private String WS_FOUND_FLAG = "N";

    // 88 WS-EOF VALUE 'Y'
    public static final String WS_EOF = "Y";
    public boolean checkWS_EOF() { return WS_EOF_FLAG == WS_EOF; }

    // 88 WS-NOT-EOF VALUE 'N'
    public static final String WS_NOT_EOF = "N";
    public boolean checkWS_NOT_EOF() { return WS_EOF_FLAG == WS_NOT_EOF; }

    // 88 WS-JOIN-EOF VALUE 'Y'
    public static final String WS_JOIN_EOF = "Y";
    public boolean checkWS_JOIN_EOF() { return WS_JOIN_EOF_FLAG == WS_JOIN_EOF; }

    // 88 WS-JOIN-NOT-EOF VALUE 'N'
    public static final String WS_JOIN_NOT_EOF = "N";
    public boolean checkWS_JOIN_NOT_EOF() { return WS_JOIN_EOF_FLAG == WS_JOIN_NOT_EOF; }

    // 88 WS-FOUND VALUE 'Y'
    public static final String WS_FOUND = "Y";
    public boolean checkWS_FOUND() { return WS_FOUND_FLAG == WS_FOUND; }

    // 88 WS-NOT-FOUND VALUE 'N'
    public static final String WS_NOT_FOUND = "N";
    public boolean checkWS_NOT_FOUND() { return WS_FOUND_FLAG == WS_NOT_FOUND; }
}