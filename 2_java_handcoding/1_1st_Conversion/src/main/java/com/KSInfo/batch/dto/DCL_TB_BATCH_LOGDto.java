package com.KSInfo.batch.dto;

import lombok.Data;
import java.math.BigDecimal;
import java.util.Arrays;

@Data
public class DCL_TB_BATCH_LOGDto {
    private BLG_ACTIONReturnCode BLG_ACTION;
    private String BLG_PGM_ID;
    private String BLG_BIZ_DATE;
    private String BLG_START_DT;
    private String BLG_END_DT;
    private String BLG_STAT;
    private long BLG_PROC_CNT;
    private long BLG_ERR_CNT;
    private String BLG_REMARK;
    private BigDecimal BLG_BATCH_ID = BigDecimal.ZERO;;
    private int BLG_RETURN_CODE;

    public enum BLG_ACTIONReturnCode {
        BLG_START("START"),
        BLG_END("END");

        private final String value;

        BLG_ACTIONReturnCode(String value) {
            this.value = value;
        }

        public String getValue() {
            return value;
        }

        public static BLG_ACTIONReturnCode of(String value) {
            return Arrays.stream(values())
                    .filter(code -> code.value == value)
                    .findFirst()
                    .orElseThrow(() -> new IllegalArgumentException("Unknown return code: " + value));
        }
    }
    
}