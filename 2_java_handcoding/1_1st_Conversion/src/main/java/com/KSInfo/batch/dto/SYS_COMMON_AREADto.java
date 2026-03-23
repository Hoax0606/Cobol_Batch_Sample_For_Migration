import java.util.Arrays;

public class SYS_COMMON_AREADto {
    private String SYS_JOB_ID = "";
    private String SYS_BIZ_DATE = "";
    private SYS_RET_CODEReturnCode SYS_RET_CODE = SYS_RET_CODEReturnCode.NORMAL;

    private enum SYS_RET_CODEReturnCode {
        NORMAL(0),
        BATCH_WARNING(4),
        BATCH_ERROR(8);

        private final int value;

        SYS_RET_CODEReturnCode(int value) {
            this.value = value;
        }

        private int getValue() {
            return value;
        }

        private static SYS_RET_CODEReturnCode of(int value) {
            return Arrays.stream(values())
                    .filter(code -> code.value == value)
                    .findFirst()
                    .orElseThrow(() -> new IllegalArgumentException("Unknown return code: " + value));
        }
    }
    
    
}