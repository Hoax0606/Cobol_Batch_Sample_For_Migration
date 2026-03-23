package com.KSInfo.batch.dto;

import lombok.Data;
import java.util.Arrays;
import java.util.Objects;

@Data
public class WS_FLAGSDto_2 {
    private WS_EOF_FLAGReturnCode WS_EOF_FLAG = WS_EOF_FLAGReturnCode.NORMAL;
    public enum WS_EOF_FLAGReturnCode {
        NORMAL("N"),
        WS_EOF("Y"),
        WS_NOT_EOF("N");

        private final String value;

        WS_EOF_FLAGReturnCode(String value) {
            this.value = value;
        }

        public String getValue() {
            return value;
        }

        public static WS_EOF_FLAGReturnCode of(String value) {
             return Arrays.stream(values())
                    .filter(code -> Objects.equals(code.value, value))
                    .findFirst()
                    .orElseThrow(() -> new IllegalArgumentException("Unknown return code: " + value));
        }
    }
    
}
