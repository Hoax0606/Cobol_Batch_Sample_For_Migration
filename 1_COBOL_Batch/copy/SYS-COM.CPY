      * System Common Area
       01  SYS-COMMON-AREA.
           05 SYS-JOB-ID         PIC X(8)  VALUE SPACES.
           05 SYS-BIZ-DATE       PIC X(8)  VALUE SPACES.
           05 SYS-RET-CODE       PIC 9(4)  VALUE ZERO.
              88 BATCH-WARNING   VALUE 4.
              88 BATCH-ERROR     VALUE 8.
