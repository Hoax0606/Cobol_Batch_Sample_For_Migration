package com.KSInfo.batch.dto;

import java.math.BigDecimal;
import java.nio.charset.StandardCharsets;

/**
 * CobolRecord - 범용 COBOL 레코드 엔진
 * offset + length 기반으로 byte[] 읽기/쓰기만 담당
 */

public class CobolRecord {

    protected final byte[] rawBytes;

    public CobolRecord(int size) {
        this.rawBytes = new byte[size];
    }

    public CobolRecord(byte[] data) {
        this.rawBytes = data.clone();
    }

    /** PIC X(n) 읽기 */
    public String asAlphanumeric(int offset, int length) {
        return new String(rawBytes, offset, length, StandardCharsets.ISO_8859_1);
    }

    /**
     * PIC 9(n) 읽기 - 9자리 이하 (최대 999,999,999)
     * ex) PIC 9(4), PIC 9(9)
     */
    public int asInt(int offset, int length) {
        return Integer.parseInt(asAlphanumeric(offset, length).trim());
    }

    /**
     * PIC 9(n) 읽기 - 10자리 이상 (최대 9,999,999,999,999,999,999)
     * ex) PIC 9(10), PIC 9(15)
     */
    public long asLong(int offset, int length) {
        return Long.parseLong(asAlphanumeric(offset, length).trim());
    }

    /** PIC 9(n)V9(m) 읽기 (묵시적 소수점) */
    public BigDecimal asDecimal(int offset, int length, int decimalPlaces) {
        String raw = asAlphanumeric(offset, length).trim();
        return new BigDecimal(raw).movePointLeft(decimalPlaces);
    }

    /** PIC X(n) 쓰기 (오른쪽 공백 패딩) */
    public void putAlphanumeric(int offset, int length, String value) {
        String padded = String.format("%-" + length + "s", value == null ? "" : value);
        if (padded.length() > length) padded = padded.substring(0, length);
        byte[] bytes = padded.getBytes(StandardCharsets.ISO_8859_1);
        System.arraycopy(bytes, 0, rawBytes, offset, length);
    }

    /**
     * PIC 9(n) 쓰기 - 9자리 이하 (앞쪽 0 패딩)
     * ex) PIC 9(4), PIC 9(9)
     */
    public void putInt(int offset, int length, int value) {
        String padded = String.format("%0" + length + "d", value);
        if (padded.length() > length) padded = padded.substring(0, length);
        byte[] bytes = padded.getBytes(StandardCharsets.ISO_8859_1);
        System.arraycopy(bytes, 0, rawBytes, offset, length);
    }

    /**
     * PIC 9(n) 쓰기 - 10자리 이상 (앞쪽 0 패딩)
     * ex) PIC 9(10), PIC 9(15)
     */
    public void putLong(int offset, int length, long value) {
        String padded = String.format("%0" + length + "d", value);
        if (padded.length() > length) padded = padded.substring(0, length);
        byte[] bytes = padded.getBytes(StandardCharsets.ISO_8859_1);
        System.arraycopy(bytes, 0, rawBytes, offset, length);
    }

    /** 레코드 전체를 raw 문자열로 반환 */
    public String getRaw() {
        return new String(rawBytes, StandardCharsets.ISO_8859_1);
    }
}
