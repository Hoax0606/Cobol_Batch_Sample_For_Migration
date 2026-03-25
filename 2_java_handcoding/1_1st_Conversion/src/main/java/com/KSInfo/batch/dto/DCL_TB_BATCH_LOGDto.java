package com.KSInfo.batch.dto;

import lombok.Data;
import java.math.BigDecimal;

@Data
public class DCL_TB_BATCH_LOG {

    private BLG_ACTION BLG_ACTION;
    private String BLG_PGM_ID = "";
    private String BLG_BIZ_DATE = "";
    private String BLG_START_DT = "";
    private String BLG_END_DT = "";
    private String BLG_STAT = "";
    private long BLG_PROC_CNT = 0L;
    private long BLG_ERR_CNT = 0L;
    private String BLG_REMARK = "";
    private BigDecimal BLG_BATCH_ID = BigDecimal.ZERO;
    private int BLG_RETURN_CODE = 0;

    private enum BLG_ACTION {

        BLG_START ("START"),
        BLG_END   ("END  ");

        private final String value;
    
        BLG_ACTION(String value) {
            this.value = value;
        }

        public String getValue() {
            return value;
        }

        public static BLG_ACTION from(String raw) {
            if (raw == null || raw.isEmpty()) {
                throw new IllegalArgumentException("Record is null or empty");
            }
            String code = raw.substring(0, 5); 
            for (BLG_ACTION type : values()) {
                if (type.value.equals(code)) return type;
                
                
            }
            throw new IllegalArgumentException("Unknown RecordType: [" + code + "]");
        }
    }
    
}
