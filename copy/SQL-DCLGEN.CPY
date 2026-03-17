      *================================================================*
      * SQL-DCLGEN.cpy - 호스트 변수 선언
      * 기존 : TB_STG_TRX / TB_INST_MASTER / TB_NET_SUMMARY
      * 신규 : TB_TRX_DETAIL / TB_INST_DAILY_STAT / TB_BATCH_LOG
      *================================================================*

      *----------------------------------------------------------------*
      * TB_STG_TRX (기존)
      *----------------------------------------------------------------*
       01  DCL-TB-STG-TRX.
           05 STG-TRX-DATE            PIC X(8).
           05 STG-TRX-SEQ             PIC S9(10) COMP-3.
           05 STG-INST-CD             PIC X(4).
           05 STG-ACC-NO              PIC X(15).
           05 STG-TRX-TYPE            PIC X(1).
           05 STG-TRX-AMT             PIC S9(12) COMP-3.
           05 STG-FEE-AMT             PIC S9(12) COMP-3.
           05 STG-PROC-STAT           PIC X(1).

      *----------------------------------------------------------------*
      * TB_INST_MASTER (기존)
      *----------------------------------------------------------------*
       01  DCL-TB-INST-MASTER.
           05 INST-MAST-CD            PIC X(4).
           05 INST-MAST-NAME          PIC X(20).
           05 INST-MAST-STAT          PIC X(1).
           05 INST-MAST-FEE-RATE      PIC S9(3)V9(4) COMP-3.

      *----------------------------------------------------------------*
      * TB_NET_SUMMARY (기존 + INST_NAME / FEE_RATE / TOT_FEE_AMT 추가)
      * DDL 변경:
      *   ALTER TABLE TB_NET_SUMMARY ADD COLUMN INST_NAME   TEXT(20);
      *   ALTER TABLE TB_NET_SUMMARY ADD COLUMN FEE_RATE    NUMERIC(7,4);
      *   ALTER TABLE TB_NET_SUMMARY ADD COLUMN TOT_FEE_AMT NUMERIC(15,0);
      *
      * PHASE3 FINALIZE 에서 TB_INST_DAILY_STAT + TB_INST_MASTER JOIN
      * 커서(C-DAILY-STAT-JOIN)로 SELECT 후 이 구조체에 받아 INSERT
      *----------------------------------------------------------------*
       01  DCL-TB-NET-SUMMARY.
           05 SUM-SETTLE-DATE         PIC X(8).
           05 SUM-INST-CD             PIC X(4).
           05 SUM-INST-NAME           PIC X(20).
           05 SUM-FEE-RATE            PIC S9(3)V9(4) COMP-3.
           05 SUM-TOT-IN              PIC S9(15) COMP-3.
           05 SUM-TOT-OUT             PIC S9(15) COMP-3.
           05 SUM-NET-AMT             PIC S9(15) COMP-3.
           05 SUM-TOT-FEE             PIC S9(15) COMP-3.
           05 SUM-TOT-CNT             PIC S9(10) COMP-3.

      *----------------------------------------------------------------*
      * TB_TRX_DETAIL (신규)
      * TB_STG_TRX + TB_INST_MASTER 를 JOIN 한 결과를 건별로 저장
      * INST_NAME / FEE_RATE 는 INST_MASTER SELECT 결과에서 받아 SET
      *----------------------------------------------------------------*
       01  DCL-TB-TRX-DETAIL.
           05 DTL-SETTLE-DATE         PIC X(8).
           05 DTL-TRX-SEQ             PIC S9(10) COMP-3.
           05 DTL-INST-CD             PIC X(4).
           05 DTL-INST-NAME           PIC X(20).
           05 DTL-ACC-NO              PIC X(15).
           05 DTL-TRX-TYPE            PIC X(1).
           05 DTL-TRX-AMT             PIC S9(12) COMP-3.
           05 DTL-STG-FEE-AMT         PIC S9(12) COMP-3.
           05 DTL-FEE-RATE            PIC S9(3)V9(4) COMP-3.
           05 DTL-CALC-FEE-AMT        PIC S9(12) COMP-3.
           05 DTL-PROC-STAT           PIC X(1).

      *----------------------------------------------------------------*
      * TB_INST_DAILY_STAT (신규)
      * COBOL 인메모리 집계 → INSERT
      * FINALIZE 시 TB_INST_MASTER JOIN 커서의 FROM 대상
      *----------------------------------------------------------------*
       01  DCL-TB-INST-DAILY-STAT.
           05 IDS-SETTLE-DATE         PIC X(8).
           05 IDS-INST-CD             PIC X(4).
           05 IDS-TOT-IN              PIC S9(15) COMP-3.
           05 IDS-TOT-OUT             PIC S9(15) COMP-3.
           05 IDS-NET-AMT             PIC S9(15) COMP-3.
           05 IDS-TOT-FEE             PIC S9(15) COMP-3.
           05 IDS-TOTAL-CNT           PIC S9(10) COMP-3.

      *----------------------------------------------------------------*
      * TB_BATCH_LOG (신규)
      *----------------------------------------------------------------*
       01  DCL-TB-BATCH-LOG.
           05 BLG-ACTION              PIC X(5).
              88 BLG-START            VALUE 'START'.
              88 BLG-END              VALUE 'END  '.
           05 BLG-PGM-ID              PIC X(10).
           05 BLG-BIZ-DATE            PIC X(8).
           05 BLG-START-DT            PIC X(14).
           05 BLG-END-DT              PIC X(14).
           05 BLG-STAT                PIC X(1).
           05 BLG-PROC-CNT            PIC 9(10).
           05 BLG-ERR-CNT             PIC 9(10).
           05 BLG-REMARK              PIC X(100).
           05 BLG-BATCH-ID            PIC S9(10) COMP-3.
           05 BLG-RETURN-CODE         PIC 9(4).
           