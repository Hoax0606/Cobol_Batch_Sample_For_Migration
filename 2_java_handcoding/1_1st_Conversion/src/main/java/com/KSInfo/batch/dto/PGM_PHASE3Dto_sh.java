// package com.KSInfo.batch.dto;

// import lombok.Data;
// import java.math.BigDecimal;
// import java.util.ArrayList;
// import java.util.List;

// @Data
// public class PGM_PHASE3Dto_sh{
//     private WS_DB_CONN wS_DB_CONN;
//     private WS_SYS_COMMON_AREA wS_SYS_COMMON_AREA;
//     private ERR_LOG_AREA eRR_LOG_AREA;
//     private WS_FLAGS wS_FLAGS;
//     private WS_COUNTERS wS_COUNTERS;
//     private WS_WORK_AREAS wS_WORK_AREAS;
//     private String wS_START_DATETIME = "";
//     private List<NET_ENTRY> nETTING_TABLE = new ArrayList<>(1000);
//     private int wS_NET_MAX_IDX = 0;
//     private String wS_PROG_NAME = "PGM_PHASE3";
//     private String wS_PHASE_ID = "PHASE3";
//     private int wS_COMMIT_INTERVAL = 1000;
//     private String wS_PROC_STAT_DONE = "9";

//     @Data
//     public static class WS_DB_CONN {
//         private String WS_DATASRC = "";
//         private String WS_USER = "";
//         private String WS_PWD = "";
//     }

//     @Data
//     public static class SYS_COMMON_AREA {
//         private String SYS_JOB_ID = "";
//         private String SYS_BIZ_DATE = "";
//         private SYS_RET_CODE sYS_RET_CODE = null;

//         public boolean isBATCH_WARNING() { return this.sYS_RET_CODE == SYS_RET_CODE.BATCH_WARNING; }
//         public boolean isBATCH_ERROR()   { return this.sYS_RET_CODE == SYS_RET_CODE.BATCH_ERROR; }
//         public void setBATCH_WARNING()   { this.sYS_RET_CODE = SYS_RET_CODE.BATCH_WARNING; }
//         public void setBATCH_ERROR()     { this.sYS_RET_CODE = SYS_RET_CODE.BATCH_ERROR; }   
//         }

//     public enum SYS_RET_CODE {
//         BATCH_NORMAL (0),
//         BATCH_WARNING (4),
//         BATCH_ERROR (8);

//         private final int value;

//         SYS_RET_CODE(int value) {
//             this.value = value;
//         }

//         public int getValue() {
//             return value;
//         }

//         public static SYS_RET_CODE from(int code) {
//             for (SYS_RET_CODE type : values()) {
//             if (type.value == code) return type;
//             }
//             throw new IllegalArgumentException("Unknown SYS_RET_CODE: [" + code + "]");
//         }
//     }

//     @Data
//     public static class ERR_LOG_AREA {
//         private String ERR_PGM_ID = "";
//         private long ERR_SQLCODE = 0;
//         private ERR_SEVERITY eRR_SEVERITY = null;
//         private String ERR_DESCRIPTION = "";
//     }

//     public enum ERR_SEVERITY {
//         ERR_INFO ("I"),
//         ERR_WARN ("W"),
//         ERR_FATAL ("F");

//         private final String value;

//         ERR_SEVERITY(String value) {
//             this.value = value;
//         }

//         public String getValue() {
//             return value;
//         }

//         public static ERR_SEVERITY from(String raw) {
//             if (raw == null || raw.isEmpty()) {
//                 throw new IllegalArgumentException("ERR_SEVERITY is null or empty");
//             }
//             String code = raw.substring(0, 1);
//             for (ERR_SEVERITY type : values()) {
//                 if (type.value.equals(code)) return type;
                
                
//             }
//             throw new IllegalArgumentException("Unknown ERR_SEVERITY: [" + code + "]");
//         }
//     }
    
//     @Data
//     public static class WS_FLAGS {
//         private WS_EOF_FLAG wS_EOF_FLAG = WS_EOF_FLAG.WS_NOT_EOF;
//         private WS_JOIN_EOF_FLAG wS_JOIN_EOF_FLAG = WS_JOIN_EOF_FLAG.WS_JOIN_NOT_EOF;
//         private WS_FOUND_FLAG wS_FOUND_FLAG = WS_FOUND_FLAG.WS_NOT_FOUND;
//     }

//     public enum WS_EOF_FLAG {
//         WS_EOF ("Y"),
//         WS_NOT_EOF ("N");

//         private final String value;

//         WS_EOF_FLAG(String value) {
//             this.value = value;
//         }

//         public String getValue() {
//             return value;
//         }

//         public static WS_EOF_FLAG from(String raw) {
//             if (raw == null || raw.isEmpty()) {
//                 throw new IllegalArgumentException("WS_EOF_FLAG is null or empty");
//             }
//             String code = raw.substring(0, 1);
//             for (WS_EOF_FLAG type : values()) {
//                 if (type.value.equals(code)) return type;
                
                
//             }
//             throw new IllegalArgumentException("Unknown WS_EOF_FLAG: [" + code + "]");
//         }
//     }

//     public enum WS_JOIN_EOF_FLAG {
//         WS_JOIN_EOF ("Y"),
//         WS_JOIN_NOT_EOF ("N");

//         private final String value;

//         WS_JOIN_EOF_FLAG(String value) {
//             this.value = value;
//         }

//         public String getValue() {
//             return value;
//         }

//         public static WS_JOIN_EOF_FLAG from(String raw) {
//             if (raw == null || raw.isEmpty()) {
//                 throw new IllegalArgumentException("WS_JOIN_EOF_FLAG is null or empty");
//             }
//             String code = raw.substring(0, 1);
//             for (WS_JOIN_EOF_FLAG type : values()) {
//                 if (type.value.equals(code)) return type;
                
                
//             }
//             throw new IllegalArgumentException("Unknown WS_JOIN_EOF_FLAG: [" + code + "]");
//         }
//     }

//     public enum WS_FOUND_FLAG {
//         WS_FOUND ("Y"),
//         WS_NOT_FOUND ("N");

//         private final String value;

//         WS_FOUND_FLAG(String value) {
//             this.value = value;
//         }

//         public String getValue() {
//             return value;
//         }

//         public static WS_FOUND_FLAG from(String raw) {
//             if (raw == null || raw.isEmpty()) {
//                 throw new IllegalArgumentException("WS_FOUND_FLAG is null or empty");
//             }
//             String code = raw.substring(0, 1);
//             for (WS_FOUND_FLAG type : values()) {
//                 if (type.value.equals(code)) return type;
                
                
//             }
//             throw new IllegalArgumentException("Unknown WS_FOUND_FLAG: [" + code + "]");
//         }
//     }

//     @Data
//     public static class WS_COUNTERS {
//         private long WS_TOTAL_READ = 0;
//         private long WS_DETAIL_INS_CNT = 0;
//         private long WS_STAT_UPD_CNT = 0;
//         private long WS_SUMMARY_INS_CNT = 0;
//         private long WS_ERR_CNT = 0;
//         private int WS_COMMIT_CNT = 0;
//     }
    
//     @Data
//     public static class WS_WORK_AREAS {
//         private BigDecimal WS_FEE_WORK = BigDecimal.ZERO;
//     }

//     @Data
//     public static class NET_ENTRY {
//         private String NET_INST_CD;
//         private BigDecimal NET_TOT_IN = BigDecimal.ZERO;
//         private BigDecimal NET_TOT_OUT = BigDecimal.ZERO;
//         private BigDecimal NET_TOT_FEE = BigDecimal.ZERO;
//         private long NET_CNT = 0;
//     }

// }