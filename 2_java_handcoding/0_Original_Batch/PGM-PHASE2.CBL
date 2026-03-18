      *================================================================*
      * PGM-PHASE2.cbl - File to DB
      * 1. ?? COPYBOOK (SYS-COM, ERR-LOG, FILE-CTRL, TRX-REC) ??
      * 2. INSPECT REPLACING ? ?? ??? ??? (???¨???)
      * 3. Header/Trailer ??? ?? ? Skip (H/T ?? ?? ??)
      * 4. TB_INST_MASTER ??? ?? ???? ?? ? ???? ??
      * 5. TB_STG_TRX ?? DELETE ? ?? INSERT (??? ??? ??)
      * 6. COMMIT INTERVAL ?? ?? ?? ??
      * 7. DB ?? ??? ????(GIXSQL_DB_CONN/USER/PWD)? ??
      *================================================================*
      *================================================================*
      * IDENTIFICATION                DIVISION.
      *================================================================*
       IDENTIFICATION                 DIVISION.
       PROGRAM-ID.                    PGM-PHASE2.
       AUTHOR.                        Hoax.
      *================================================================*
      * ENVIRONMENT                   DIVISION.
      *================================================================*
       ENVIRONMENT                    DIVISION.
       INPUT-OUTPUT                   SECTION.
       FILE-CONTROL.
      * --- Phase 1?? ??? CLEANSED_DATA.txt ??? ???? ?? ---
           SELECT IN-FILE ASSIGN TO 'INFILE_VAR'
                  ORGANIZATION IS LINE SEQUENTIAL
                  FILE STATUS IS WS-IN-STAT.
      *================================================================*
      * DATA                          DIVISION.
      *================================================================*
       DATA                           DIVISION.
       FILE                           SECTION.
       FD  IN-FILE.
       01  IN-REC                     PIC X(57).

       WORKING-STORAGE                SECTION.
      * --- ?? COPYBOOK ---
      *VAF Embedded Start=======================================================
      *COPY SYS-COM.
      * System Common Area
       01  SYS-COMMON-AREA.
           05 SYS-JOB-ID         PIC X(8)  VALUE SPACES.
           05 SYS-BIZ-DATE       PIC X(8)  VALUE SPACES.
           05 SYS-RET-CODE       PIC 9(4)  VALUE ZERO.
              88 BATCH-WARNING   VALUE 4.
              88 BATCH-ERROR     VALUE 8.
      *VAF Embedded Finish======================================================
      *VAF Embedded Start=======================================================
      *COPY ERR-LOG.
      *================================================================*
      * [ERR-LOG.cpy] 
      *================================================================*
       01  ERR-LOG-AREA.
           05 ERR-PGM-ID         PIC X(10) VALUE SPACES.
           05 ERR-SQLCODE        PIC S9(9) VALUE ZERO.
           05 ERR-SEVERITY       PIC X(1)  VALUE SPACES.
              88 ERR-INFO        VALUE 'I'.
              88 ERR-WARN        VALUE 'W'.
              88 ERR-FATAL       VALUE 'F'.
           05 ERR-DESCRIPTION    PIC X(200) VALUE SPACES.
      *    
      *VAF Embedded Finish======================================================
      *VAF Embedded Start=======================================================
      *COPY FILE-CTRL.
      *================================================================*
      * [FILE-CTRL.cpy]  Header/Trailer (57 Bytes)
      *================================================================*
       01  FILE-CONTROL-REC.
           05 REC-TYPE           PIC X(1).
              88 IS-HEADER       VALUE 'H'.
              88 IS-DATA         VALUE 'D'.
              88 IS-TRAILER      VALUE 'T'.
           05 REC-CONTENT        PIC X(56).
      *
      * --- Header Record  ---
       01  HEADER-REC REDEFINES FILE-CONTROL-REC.
           05 HDR-TYPE           PIC X(1).
           05 FILLER             PIC X(1).
           05 HDR-CREATE-DATE    PIC X(8).
      *
      * --- Trailer Record ---
       01  TRAILER-REC REDEFINES FILE-CONTROL-REC.
           05 TRL-TYPE           PIC X(1).
           05 FILLER             PIC X(1).
           05 TRL-TOT-CNT        PIC 9(10).
      *    05 FILLER             PIC X(1).
      *    05 TRL-IN-AMT         PIC 9(15).
      *    05 FILLER             PIC X(1).
      *    05 TRL-OUT-AMT        PIC 9(15).
      *    05 FILLER             PIC X(1).
           05 FILLER             PIC X(33).
           05 TRL-TOT-AMT        PIC 9(12).
      *    
      *VAF Embedded Finish======================================================
      *VAF Embedded Start=======================================================
      *COPY TRX-REC.
       01  TRX-RECORD.
           05 TRX-HEADER        PIC X(1).
           05 FILLER            PIC X(1).
           05 TRX-DATE          PIC X(8).
           05 FILLER            PIC X(1).
           05 TRX-SEQ           PIC X(10).
           05 FILLER            PIC X(1).
           05 INST-CD           PIC X(4).
           05 FILLER            PIC X(1).
           05 ACC-NO            PIC X(15).
           05 FILLER            PIC X(1).
           05 TRX-TYPE          PIC X(1).
           05 FILLER            PIC X(1).
           05 TRX-AMT           PIC 9(12).
      *    
      *VAF Embedded Finish======================================================

      * --- SQLCA ? DB DCLGEN ---
       EXEC SQL INCLUDE SQLCA END-EXEC.

      *----------------------------------------------------------------*
      * TB_STG_TRX (??)
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
      * TB_INST_MASTER (??)
      *----------------------------------------------------------------*
       01  DCL-TB-INST-MASTER.
           05 INST-MAST-CD            PIC X(4).
           05 INST-MAST-NAME          PIC X(20).
           05 INST-MAST-STAT          PIC X(1).
           05 INST-MAST-FEE-RATE      PIC S9(3)V9(4) COMP-3.

      *----------------------------------------------------------------*
      * TB_BATCH_LOG (??)
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
           
      * --- ?? ?? ---
       01  WS-FILE-STATUS.
           05 WS-IN-STAT              PIC X(2).

      * --- ?? ??? ---
       01  WS-FLAGS.
           05 WS-EOF-FLAG             PIC X(1) VALUE 'N'.
              88 WS-EOF               VALUE 'Y'.
              88 WS-NOT-EOF           VALUE 'N'.
       
      * --- ?? ?? ?? ---
       01  WS-COUNTERS.
           05 WS-READ-CNT             PIC 9(10) VALUE 0.
           05 WS-INSERT-CNT           PIC 9(10) VALUE 0.
           05 WS-SKIP-CNT             PIC 9(10) VALUE 0.
           05 WS-INST-SKIP-CNT        PIC 9(10) VALUE 0.
           05 WS-COMMIT-CNT           PIC 9(5)  VALUE 0.
           05 WS-ERR-CNT              PIC 9(5)  VALUE 0.
       
      * --- ?? ?? ---
       01  WS-WORK-AREAS.
           05 WS-FEE-AMT-COMP         PIC S9(12) COMP-3 VALUE 0.
       
      * --- DB ?? ?? (????? ??) ---
       01  WS-DB-CONN.
           05 WS-DATASRC              PIC X(50)  VALUE SPACES.
           05 WS-USER                 PIC X(30)  VALUE SPACES.
           05 WS-PWD                  PIC X(30)  VALUE SPACES.

      * --- ?? ???? ---
       01  WS-START-DATETIME          PIC X(14)  VALUE SPACES.

      * --- 77 ??: ?? ?? ?? ---
       77  WS-PROG-NAME               PIC X(10)  VALUE 'PGM-PHASE2'.
       77  WS-PHASE-ID                PIC X(8)   VALUE 'PHASE2'.

      * --- 78 ??: ?? ?? ---
       78  WS-COMMIT-INTERVAL         VALUE 1000.
       78  WS-PROC-STAT-INIT          VALUE '0'.

      *================================================================*
      * PROCEDURE                     DIVISION.
      *================================================================*
       PROCEDURE                      DIVISION.
      *----------------------------------------------------------------*
      * MAIN                          SECTION.
      *----------------------------------------------------------------*
       MAIN                           SECTION.
       MAIN-000.
           PERFORM INIT-000.
           PERFORM PROCESS-000
               UNTIL WS-EOF.
           PERFORM FINALIZE-000.
       MAIN-999.
           MOVE SYS-RET-CODE TO RETURN-CODE
           STOP RUN.

      *----------------------------------------------------------------*
      * INIT                          SECTION.
      *----------------------------------------------------------------*
       INIT                           SECTION.
       INIT-000.
      * --- ??? ?? ?? ??? ---
           MOVE WS-PHASE-ID                 TO SYS-JOB-ID.
           MOVE FUNCTION CURRENT-DATE(1:8)  TO SYS-BIZ-DATE.
           MOVE FUNCTION CURRENT-DATE(1:14) TO WS-START-DATETIME.

      * --- ?????? DB ?? ?? ?? ---
           ACCEPT WS-DATASRC      FROM ENVIRONMENT 'GIXSQL_DB_CONN'.
           ACCEPT WS-USER         FROM ENVIRONMENT 'GIXSQL_USER'.
           ACCEPT WS-PWD          FROM ENVIRONMENT 'GIXSQL_PWD'.

           IF WS-DATASRC = SPACES THEN
               MOVE 'GIXSQL_DB_CONN NOT SET' TO ERR-DESCRIPTION
               PERFORM SYSTEM-ERROR-000
               SET BATCH-ERROR TO TRUE
               MOVE SYS-RET-CODE TO RETURN-CODE
               STOP RUN
           ELSE
               CONTINUE
           END-IF.  

      * --- ?? ?? ?? ---
           OPEN INPUT IN-FILE.

           IF WS-IN-STAT NOT = '00' THEN
               MOVE 'INPUT FILE OPEN ERROR' TO ERR-DESCRIPTION
               PERFORM SYSTEM-ERROR-000
               SET BATCH-ERROR TO TRUE
               MOVE SYS-RET-CODE TO RETURN-CODE
               STOP RUN
           ELSE
               CONTINUE
           END-IF.

      * --- DB ?? ---
           EXEC SQL
               CONNECT :WS-USER IDENTIFIED BY :WS-PWD
                       USING :WS-DATASRC
           END-EXEC.

           IF SQLCODE NOT = 0 THEN
               MOVE SQLCODE            TO ERR-SQLCODE
               MOVE 'DB CONNECT ERROR' TO ERR-DESCRIPTION
               PERFORM SYSTEM-ERROR-000
               SET BATCH-ERROR TO TRUE
               MOVE SYS-RET-CODE TO RETURN-CODE
               STOP RUN
           ELSE
               CONTINUE
           END-IF.

      * --- ?? ?? ?? ?? ---
           PERFORM BATCHLOG-START-000.

      * --- ???? ??? ?? ??? (??? ???) ---
           EXEC SQL DELETE FROM TB_STG_TRX END-EXEC.
           EXEC SQL COMMIT END-EXEC.

      * --- ?? ??? ?? ---
           PERFORM READ-IN-FILE-000.
       INIT-999.
           EXIT.

      *----------------------------------------------------------------*
      * DATA-PROCESS                  SECTION.
      *----------------------------------------------------------------*
       DATA-PROCESS                   SECTION.
       PROCESS-000.
      * --- INSPECT REPLACING: ???? ???? ??? ---
           INSPECT IN-REC
               CONVERTING 'abcdefghijklmnopqrstuvwxyz'
                       TO 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.

      * --- ??? ??(H/D/T) ??? ?? ?? ?? ---
           MOVE IN-REC TO FILE-CONTROL-REC.

           EVALUATE REC-TYPE
               WHEN 'H'
                   ADD 1              TO WS-SKIP-CNT
                   DISPLAY ' > HEADER  RECORD SKIPPED'
               WHEN 'T'
                   ADD 1              TO WS-SKIP-CNT
                   DISPLAY ' > TRAILER RECORD SKIPPED'
               WHEN OTHER
                   MOVE IN-REC        TO TRX-RECORD
                   PERFORM CHECK-INST-000
           END-EVALUATE.

           PERFORM READ-IN-FILE-000.
       PROCESS-999.
           EXIT.

      *----------------------------------------------------------------*
      * READ-IN-FILE                  SECTION.
      *----------------------------------------------------------------*
       READ-IN-FILE                   SECTION.
       READ-IN-FILE-000.
           READ IN-FILE
               AT END
                   SET WS-EOF         TO TRUE
               NOT AT END
                   ADD 1              TO WS-READ-CNT
           END-READ.
       READ-IN-FILE-999.
           EXIT.

      *----------------------------------------------------------------*
      * CHECK-INST                    SECTION.
      *----------------------------------------------------------------*
       CHECK-INST                     SECTION.
       CHECK-INST-000.
      * --- TB_INST_MASTER ??: ???? ??? ?? ? ???? ?? ---
           MOVE INST-CD               TO INST-MAST-CD.

           EXEC SQL
               SELECT INST_CD,
                      INST_STAT,      FEE_RATE
                 INTO :INST-MAST-CD,
                      :INST-MAST-STAT,     :INST-MAST-FEE-RATE
                 FROM TB_INST_MASTER
                WHERE INST_CD = :INST-MAST-CD
           END-EXEC.

           EVALUATE SQLCODE
               WHEN 0
                   PERFORM INSERT-DB-000
               WHEN 100
                   ADD 1              TO WS-INST-SKIP-CNT
                   DISPLAY ' > INST NOT FOUND SKIP: [' INST-CD ']'
               WHEN OTHER
                   MOVE SQLCODE       TO ERR-SQLCODE
                   MOVE 'INST MASTER SELECT ERROR' TO ERR-DESCRIPTION
                   PERFORM DB-ERROR-000
           END-EVALUATE.
       CHECK-INST-999.
           EXIT.

      *----------------------------------------------------------------*
      * INSERT-DB                     SECTION.
      *----------------------------------------------------------------*
       INSERT-DB                      SECTION.  
       INSERT-DB-000.
      * --- ??? ??? ?? ---
           MOVE TRX-DATE              TO STG-TRX-DATE.
           MOVE TRX-SEQ               TO STG-TRX-SEQ.
           MOVE INST-CD               TO STG-INST-CD.
           MOVE ACC-NO                TO STG-ACC-NO.
           MOVE TRX-TYPE              TO STG-TRX-TYPE.
           MOVE TRX-AMT               TO STG-TRX-AMT.

      * --- ??? ????? ??? ?? (COMP-3?? ?? ??? ??) ---
           COMPUTE WS-FEE-AMT-COMP
                       = STG-TRX-AMT * INST-MAST-FEE-RATE.
           MOVE WS-FEE-AMT-COMP       TO STG-FEE-AMT.
           MOVE WS-PROC-STAT-INIT     TO STG-PROC-STAT.

      * --- ?? INSERT (INIT ???? DELETE? ?? ??? ??) ---
           EXEC SQL
               INSERT INTO TB_STG_TRX
                      (TRX_DATE,    TRX_SEQ,     INST_CD,
                       ACC_NO,      TRX_TYPE,    TRX_AMT,
                       FEE_AMT,     PROC_STAT)
               VALUES (:STG-TRX-DATE, :STG-TRX-SEQ,
                       :STG-INST-CD,  :STG-ACC-NO,
                       :STG-TRX-TYPE, :STG-TRX-AMT,
                       :STG-FEE-AMT,  :STG-PROC-STAT)
           END-EXEC.
       
           IF SQLCODE = 0 THEN
               ADD 1              TO WS-INSERT-CNT
               ADD 1              TO WS-COMMIT-CNT
           ELSE
               ADD 1              TO WS-ERR-CNT
               MOVE SQLCODE       TO ERR-SQLCODE
               MOVE 'DB INSERT ERROR' TO ERR-DESCRIPTION
               PERFORM DB-ERROR-000
           END-IF.
       
      * --- ?? COMMIT ? ?? ?? ?? ---
           IF WS-COMMIT-CNT >= WS-COMMIT-INTERVAL THEN
               EXEC SQL COMMIT END-EXEC
               MOVE 0             TO WS-COMMIT-CNT
               PERFORM PROGRESS-LOG-000
           ELSE
               CONTINUE
           END-IF.
        INSERT-DB-999.
           EXIT.

      *----------------------------------------------------------------*
      * PROGRESS-LOG                  SECTION.
      *----------------------------------------------------------------*
       PROGRESS-LOG                   SECTION.
       PROGRESS-LOG-000.
           DISPLAY ' > ... ' WS-INSERT-CNT ' RECORDS INSERTED... <'.
       PROGRESS-LOG-999.
           EXIT.

      *----------------------------------------------------------------*
      * FINALIZE                      SECTION.
      *----------------------------------------------------------------*
       FINALIZE                       SECTION.
       FINALIZE-000.
      * --- ?? ???? ?? ---
           IF WS-COMMIT-CNT > 0 THEN
               EXEC SQL COMMIT END-EXEC
           ELSE
               CONTINUE
           END-IF.

           CLOSE IN-FILE.

      * --- ?? ?? ?? ?? ---
           PERFORM BATCHLOG-END-000.
           EXEC SQL COMMIT            END-EXEC.

           EXEC SQL DISCONNECT CURRENT END-EXEC.

           DISPLAY ' > ========= PGM-PHASE2 RESULT ========='.
           DISPLAY ' > TOTAL READ   : ' WS-READ-CNT.
           DISPLAY ' > TOTAL INSERT : ' WS-INSERT-CNT.
           DISPLAY ' > SKIPPED(H/T) : ' WS-SKIP-CNT.
           DISPLAY ' > INST  SKIP   : ' WS-INST-SKIP-CNT.
           DISPLAY ' > DB ERRORS    : ' WS-ERR-CNT.
           DISPLAY ' > ====================================='.
        FINALIZE-999.
           EXIT.

      *----------------------------------------------------------------*
      * SYSTEM-ERROR                  SECTION.
      *----------------------------------------------------------------*
       SYSTEM-ERROR                   SECTION.
       SYSTEM-ERROR-000.
           MOVE WS-PROG-NAME          TO ERR-PGM-ID.
           SET ERR-FATAL              TO TRUE.
           DISPLAY '*** SYSTEM FATAL ERROR ***'.
           DISPLAY 'PGM: ' ERR-PGM-ID ' | SQLCODE: ' ERR-SQLCODE.
           DISPLAY 'MSG: ' ERR-DESCRIPTION.
       SYSTEM-ERROR-999.
           EXIT.

      *----------------------------------------------------------------*
      * DB-ERROR                      SECTION.
      *----------------------------------------------------------------*
       DB-ERROR                       SECTION.
       DB-ERROR-000.
           MOVE WS-PROG-NAME          TO ERR-PGM-ID.
           SET ERR-WARN               TO TRUE.
           SET BATCH-WARNING          TO TRUE.
           DISPLAY '*** DB ERROR *** SEQ: ' STG-TRX-SEQ.
           DISPLAY 'SQLCODE: ' ERR-SQLCODE ' | MSG: ' ERR-DESCRIPTION.
       DB-ERROR-999.
           EXIT.
      *----------------------------------------------------------------*
      * BATCHLOG-START                SECTION.
      *----------------------------------------------------------------*
       BATCHLOG-START                 SECTION.
       BATCHLOG-START-000.
           MOVE WS-PROG-NAME          TO BLG-PGM-ID.
           MOVE SYS-BIZ-DATE          TO BLG-BIZ-DATE.
           MOVE WS-START-DATETIME     TO BLG-START-DT.
           MOVE 'PHASE2 STARTED'      TO BLG-REMARK.
           MOVE 'START'               TO BLG-ACTION.

           CALL 'PGM-BLOGSVR' USING DCL-TB-BATCH-LOG.

           IF BLG-RETURN-CODE NOT = 0 THEN
               DISPLAY '> [WARN] BLOGSVR START FAILED. RC='
                       BLG-RETURN-CODE
           ELSE
               CONTINUE
           END-IF.

       BATCHLOG-START-999.
           EXIT.

      *----------------------------------------------------------------*
      * BATCHLOG-END                  SECTION.
      *----------------------------------------------------------------*
       BATCHLOG-END                   SECTION.
       BATCHLOG-END-000.
           MOVE WS-INSERT-CNT         TO BLG-PROC-CNT.
           MOVE WS-ERR-CNT            TO BLG-ERR-CNT.
           MOVE 'END  '               TO BLG-ACTION.

           IF WS-ERR-CNT > 0 THEN
               MOVE 'E'               TO BLG-STAT
               MOVE 'PHASE2 COMPLETED WITH ERRORS' TO BLG-REMARK
           ELSE
               MOVE 'S'               TO BLG-STAT
               MOVE 'PHASE2 COMPLETED SUCCESSFULLY' TO BLG-REMARK
           END-IF.

           CALL 'PGM-BLOGSVR' USING DCL-TB-BATCH-LOG.

           IF BLG-RETURN-CODE NOT = 0 THEN
               DISPLAY '> [WARN] BLOGSVR END FAILED. RC='
                       BLG-RETURN-CODE
           ELSE
               CONTINUE
           END-IF.

       BATCHLOG-END-999.
           EXIT.
      *================================================================*
      * END OF PGM-PHASE2
      *================================================================*
      
