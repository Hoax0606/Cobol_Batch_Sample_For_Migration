       01  DCL-TB-STG-TRX.
           05 STG-TRX-DATE   PIC X(8).
           05 STG-TRX-SEQ    PIC S9(10) COMP-3.
           05 STG-INST-CD    PIC X(4).
           05 STG-ACC-NO     PIC X(15).
           05 STG-TRX-TYPE   PIC X(1).
           05 STG-TRX-AMT    PIC S9(12) COMP-3.
           05 STG-FEE-AMT    PIC S9(12) COMP-3.
           05 STG-PROC-STAT  PIC X(1).

       01  DCL-TB-INST-MASTER.
           05 INST-MAST-CD       PIC X(4).
           05 INST-MAST-NAME     PIC X(20).
           05 INST-MAST-STAT     PIC X(1).
           05 INST-MAST-FEE-RATE PIC S9(3)V9(4) COMP-3.

       01  DCL-TB-NET-SUMMARY.
           05 SUM-SETTLE-DATE PIC X(8).
           05 SUM-INST-CD     PIC X(4).
           05 SUM-TOT-IN      PIC S9(15) COMP-3.
           05 SUM-TOT-OUT     PIC S9(15) COMP-3.
           05 SUM-NET-AMT     PIC S9(15) COMP-3.
           05 SUM-TOT-CNT     PIC S9(10) COMP-3.
