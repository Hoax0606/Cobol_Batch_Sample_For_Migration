package com.KSInfo.batch.dto;

import lombok.Data;
import java.util.Arrays;
import java.util.Objects;

@Data
public class FILE_CONTROL_RECDto {
    private REC_TYPEReturnCode REC_TYPE;
    private String REC_CONTENT = "";

    public enum REC_TYPEReturnCode {
        IS_HEADER("H"),
        IS_DATA("D"),
        IS_TRAILER("T");

        private final String value;

        REC_TYPEReturnCode(String value) {
            this.value = value;
        }

        public String getValue() {
            return value;
        }

        public static REC_TYPEReturnCode of(String value) {
            return Arrays.stream(values())
                    .filter(code -> Objects.equals(code.value, value))
                    .findFirst()
                    .orElseThrow(() -> new IllegalArgumentException("Unknown return code: " + value));
        }
    }

    
}