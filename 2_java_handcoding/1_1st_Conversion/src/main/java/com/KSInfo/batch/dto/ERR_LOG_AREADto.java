package com.KSInfo.batch.dto;

import lombok.Data;
import java.util.Arrays;

@Data
public class ERR_LOG_AREADto {
    private String ERR_PGM_ID = "";
    private int ERR_SQLCODE = 0;
    private ERR_SEVERITYReturnCode ERR_SEVERITY = ERR_SEVERITYReturnCode.NORMAL;
    private String ERR_DESCRIPTION = "";
        
    
    public enum ERR_SEVERITYReturnCode {
        NORMAL(""),
        ERR_INFO("I"),
        ERR_WARN("W"),
        ERR_FATAL("F");

        private final String value;

        ERR_SEVERITYReturnCode(String value) {
            this.value = value;
        }

        public String getValue() {
            return value;
        }

        public static ERR_SEVERITYReturnCode of(String value) {
            return Arrays.stream(values())
                    .filter(code -> code.value == value)
                    .findFirst()
                    .orElseThrow(() -> new IllegalArgumentException("Unknown return code: " + value));
        }
    }

    
}
