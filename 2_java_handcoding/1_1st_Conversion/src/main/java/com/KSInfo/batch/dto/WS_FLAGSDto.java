package com.KSInfo.batch.dto;

import lombok.Data;
import java.util.Arrays;

@Data
public class WS_FLAGSDto {
    private WS_EOF_FLAGReturnCode WS_EOF_FLAG = WS_EOF_FLAGReturnCode.NORMAL;
    private WS_VALID_FLAGReturnCode WS_VALID_FLAG = WS_VALID_FLAGReturnCode.NORMAL;
    private WS_SORT_EOF_FLAGReturnCode WS_SORT_EOF_FLAG = WS_SORT_EOF_FLAGReturnCode.NORMAL;

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
                    .filter(code -> code.value == value)
                    .findFirst()
                    .orElseThrow(() -> new IllegalArgumentException("Unknown return code: " + value));
        }
    }   

    
    public enum WS_VALID_FLAGReturnCode {
        NORMAL("Y"),
        WS_VALID("Y"),
        WS_INVALID("N");

        private final String value;

        WS_VALID_FLAGReturnCode(String value) {
            this.value = value;
        }

        public String getValue() {
            return value;
        }

        public static WS_VALID_FLAGReturnCode of(String value) {
            return Arrays.stream(values())
                    .filter(code -> code.value == value)
                    .findFirst()
                    .orElseThrow(() -> new IllegalArgumentException("Unknown return code: " + value));
        }
    } 


        public enum WS_SORT_EOF_FLAGReturnCode {
        NORMAL("N"),
        WS_SORT_EOF("Y");

        private final String value;

        WS_SORT_EOF_FLAGReturnCode(String value) {
            this.value = value;
        }

        public String getValue() {
            return value;
        }

        public static WS_SORT_EOF_FLAGReturnCode of(String value) {
            return Arrays.stream(values())
                    .filter(code -> code.value == value)
                    .findFirst()
                    .orElseThrow(() -> new IllegalArgumentException("Unknown return code: " + value));
        }
    } 
    
}