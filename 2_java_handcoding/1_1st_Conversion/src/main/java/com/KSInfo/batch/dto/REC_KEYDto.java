package com.KSInfo.batch.dto;

import lombok.Data;

@Data
public class REC_KEYDto extends CobolRecord {

    // ── 필드 크기 선언 ──────────────────────────────────────────
    private static final int LEN_DATA_TYPE   = 1;
    private static final int LEN_SETTLE_DATE = 8;
    private static final int LEN_CREATE_DT   = 14;
    private static final int LEN_INST_CD     = 4;

    // ── offset 자동 계산 ─────────────────────────────────────────
    private static final int OFF_DATA_TYPE;
    private static final int OFF_SETTLE_DATE;
    private static final int OFF_CREATE_DT;
    private static final int OFF_INST_CD;

    // ── 66 RENAMES 범위 ──────────────────────────────────────────
    private static final int OFF_REC_KEY;
    private static final int LEN_REC_KEY;

    /** 레코드 전체 크기 (자동 계산) */
    public static final int SIZE;

    static {
        int pos = 0;
        OFF_DATA_TYPE   = pos; pos += LEN_DATA_TYPE;
        OFF_SETTLE_DATE = pos; pos += LEN_SETTLE_DATE;
        OFF_CREATE_DT   = pos; pos += LEN_CREATE_DT;
        OFF_INST_CD     = pos; pos += LEN_INST_CD;
        SIZE            = pos; // 27

        // 66 REC-KEY RENAMES OUT-DATA-TYPE THRU OUT-INST-CD
        OFF_REC_KEY = pos;
        LEN_REC_KEY = SIZE;
    }

    // ── 생성자 ───────────────────────────────────────────────────

    public REC_KEYDto() {
        super(SIZE);
    }

    public REC_KEYDto(byte[] data) {
        super(data);
    }

    // ── getter / setter ──────────────────────────────────────────

    /** OUT-DATA-TYPE  PIC X(1) */
    public String getDataType()           { return asAlphanumeric(OFF_DATA_TYPE,   LEN_DATA_TYPE);   }
    public void   setDataType(String v)   { putAlphanumeric(OFF_DATA_TYPE,   LEN_DATA_TYPE,   v); }

    /** OUT-SETTLE-DATE  PIC X(8) */
    public String getSettleDate()         { return asAlphanumeric(OFF_SETTLE_DATE, LEN_SETTLE_DATE); }
    public void   setSettleDate(String v) { putAlphanumeric(OFF_SETTLE_DATE, LEN_SETTLE_DATE, v); }

    /** OUT-CREATE-DT  PIC X(14) */
    public String getCreateDt()           { return asAlphanumeric(OFF_CREATE_DT,   LEN_CREATE_DT);   }
    public void   setCreateDt(String v)   { putAlphanumeric(OFF_CREATE_DT,   LEN_CREATE_DT,   v); }

    /** OUT-INST-CD  PIC X(4) */
    public String getInstCd()             { return asAlphanumeric(OFF_INST_CD,     LEN_INST_CD);     }
    public void   setInstCd(String v)     { putAlphanumeric(OFF_INST_CD,     LEN_INST_CD,     v); }

    // ── 66 RENAMES ───────────────────────────────────────────────

    /**
     * 66 REC-KEY RENAMES OUT-DATA-TYPE THRU OUT-INST-CD
     * = DATA_TYPE(1) + SETTLE_DATE(8) + CREATE_DT(14) + INST_CD(4) = 27bytes
     */
    public String getRecKey()           { return asAlphanumeric(OFF_REC_KEY, LEN_REC_KEY); }
    public void   setRecKey(String v)   { putAlphanumeric(OFF_REC_KEY, LEN_REC_KEY, v); }
}