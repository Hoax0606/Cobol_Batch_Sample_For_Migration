      *================================================================*
      * PGM-PHASE1.cbl - File to File
      * 1. ??? ?? ??(SYS-COM) ???
      * 2. Header/Trailer (FILE-CTRL) ??? ?? (??/??)
      * 3. Internal SORT (SORT/RELEASE/RETURN) ? ???? ? ??
      * 4. STRING/UNSTRING ? ??? ??? ?? ? ?? ??
      * 5. REDEFINES ? ?? ??(ERR-LOG) ??
      * 6. ?? ?? ??? PGM-BLOGSVR(??????)? ??
      *    EXEC SQL ?? → gixpp ???, cobc ?? ???
      *================================================================*
      *================================================================*
      * IDENTIFICATION                DIVISION.
      *================================================================*
       IDENTIFICATION                 DIVISION.
       PROGRAM-ID.                    PGM-PHASE1.
       AUTHOR.                        Hoax.
      *================================================================*
      * ENVIRONMENT                   DIVISION.
      *================================================================*
       ENVIRONMENT                    DIVISION.
       INPUT-OUTPUT                   SECTION.
       FILE-CONTROL.
           SELECT IN-FILE  ASSIGN TO 'INFILE_VAR'
                  ORGANIZATION IS LINE SEQUENTIAL
                  FILE STATUS IS WS-IN-STAT.
           SELECT OUT-FILE ASSIGN TO 'OUTFILE_VAR'
                  ORGANIZATION IS LINE SEQUENTIAL
                  FILE STATUS IS WS-OUT-STAT.
           SELECT ERR-FILE ASSIGN TO 'ERRFILE_VAR'
                  ORGANIZATION IS LINE SEQUENTIAL
                  FILE STATUS IS WS-ERR-STAT.
      *    Internal SORT ? ?? ??
           SELECT SORT-FILE ASSIGN TO 'SORTWORK'
                  ORGANIZATION IS LINE SEQUENTIAL.
      *================================================================*
      * DATA                          DIVISION.
      *================================================================*
       DATA                           DIVISION.
       FILE                           SECTION.
       FD  IN-FILE.
       01  IN-REC                     PIC X(57).

       FD  OUT-FILE.
       01  OUT-REC                    PIC X(57).

       FD  ERR-FILE.
       01  ERR-REC                    PIC X(57).

      *    SORT ???? SD ??
       SD  SORT-FILE.
       01  SORT-REC.
           05 SR-HEAD                 PIC X(22).
           05 SR-INST-CD              PIC X(4).
           05 SR-BODY                 PIC X(31).

       WORKING-STORAGE SECTION.
      *VAF Embedded Start=======================================================
      *    COPY SYS-COM.
      * System Common Area
       01  SYS-COMMON-AREA.
           05 SYS-JOB-ID         PIC X(8)  VALUE SPACES.
           05 SYS-BIZ-DATE       PIC X(8)  VALUE SPACES.
           05 SYS-RET-CODE       PIC 9(4)  VALUE ZERO.
              88 BATCH-WARNING   VALUE 4.
              88 BATCH-ERROR     VALUE 8.
      *VAF Embedded Finish======================================================
      *VAF Embedded Start=======================================================
      *    COPY ERR-LOG.
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
      *    COPY FILE-CTRL.
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
      *    COPY TRX-REC.
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

       01  WS-FILE-STATUS.
           05 WS-IN-STAT              PIC X(2).
           05 WS-OUT-STAT             PIC X(2).
           05 WS-ERR-STAT             PIC X(2).

       01  WS-FLAGS.
           05 WS-EOF-FLAG             PIC X(1) VALUE 'N'.
              88 WS-EOF               VALUE 'Y'.
              88 WS-NOT-EOF           VALUE 'N'.
           05 WS-VALID-FLAG           PIC X(1) VALUE 'Y'.
              88 WS-VALID             VALUE 'Y'.
              88 WS-INVALID           VALUE 'N'.
           05 WS-SORT-EOF-FLAG        PIC X(1) VALUE 'N'.
              88 WS-SORT-EOF          VALUE 'Y'.

       01  WS-CALC-TOTALS.
           05 WS-CALC-CNT             PIC 9(10)  VALUE 0.
           05 WS-ERR-CNT              PIC 9(10)  VALUE 0.
           05 WS-TRX-COUNT            PIC 9(2)   VALUE 0.

      *77  WS-TRX-COUNT            PIC 9(2)   VALUE 0.

       01  WS-CALC-AMT             PIC S9(11) COMP-3 VALUE 0.

      * --- ?? ??? ??? ??? ---
       01  WS-WORK-AREAS.
           05 WS-MOD-WORK             PIC 9(10) COMP     VALUE 0.
           05 WS-CNT-SEQ              PIC 9(2)           VALUE 0.
           05 WS-CNT-ACC              PIC 9(2)           VALUE 0.

      * --- STRING ??? ?? ?? ---
       01  WS-LOG-BUFFER              PIC X(80)  VALUE SPACES.
       01  WS-LOG-PTR                 PIC 9(3)   VALUE 1.
       01  WS-LOG-TRX-AMT             PIC X(12).

      * --- INSPECT ? ??? ---
       01  WS-INSPECT-CNT             PIC 9(5)   VALUE 0.
      *01  WS-TRX-COUNT            PIC 9(2)   VALUE 0.
      

      * --- 77 ??: ?? ?? ?? ---
       77  WS-PROG-NAME               PIC X(10)  VALUE 'PGM-PHASE1'.
       77  WS-PHASE-ID                PIC X(8)   VALUE 'PHASE1'.
       77  WS-HEADER-DATE             PIC ZZZZ/ZZ/ZZ.
       77  WS-TRAILER-COUNT           PIC ZZZZZZZZZZ. 
       77  WS-COMMIT-LIMIT            PIC 9(7)   VALUE 1000.

      * --- 78 ??: ?? ?? ---
       78  WS-REC-LENGTH              VALUE 50.
       78  WS-ERR-FIELD               VALUE 'E000'.
       78  WS-ERR-CODE-SEQ            VALUE 'E001'.
       78  WS-ERR-CODE-INST           VALUE 'E002'.
       78  WS-ERR-CODE-ACC            VALUE 'E003'.
       78  WS-ERR-CODE-TYPE           VALUE 'E004'.
       78  WS-ERR-CODE-AMT            VALUE 'E005'.
       78  WS-ERR-CODE-CTRL           VALUE 'E006'.
       78  WS-ERR-CODE-OVF            VALUE 'E007'.

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
      *    Internal SORT: INPUT/OUTPUT ?? PERFORM ??
           SORT SORT-FILE
               ASCENDING KEY SR-INST-CD
               INPUT  PROCEDURE IS INPUT-PROC-000
               OUTPUT PROCEDURE IS OUTPUT-PROC-000.
           PERFORM CHECK-COUNT-000
           PERFORM FINALIZE-000.
       MAIN-999.
           MOVE SYS-RET-CODE TO RETURN-CODE
           STOP RUN.
      *----------------------------------------------------------------*
      * INIT                          SECTION.
      *----------------------------------------------------------------*
       INIT                           SECTION.
       INIT-000.
           MOVE WS-PHASE-ID                 TO SYS-JOB-ID.
           MOVE FUNCTION CURRENT-DATE(1:8)  TO SYS-BIZ-DATE.

      * --- ?? ?? START ?? (PGM-BLOGSVR ??) ---
           PERFORM BLOGSVR-START-000.

           OPEN INPUT  IN-FILE
                OUTPUT OUT-FILE
                OUTPUT ERR-FILE.

           IF WS-IN-STAT NOT = '00'
               MOVE 'INPUT FILE OPEN ERROR' TO ERR-DESCRIPTION
               PERFORM ERROR-LOG-000
               SET BATCH-ERROR TO TRUE
               PERFORM FINALIZE-000
               MOVE SYS-RET-CODE TO RETURN-CODE
               STOP RUN
           ELSE
               CONTINUE
           END-IF.

           IF WS-OUT-STAT NOT = '00' OR WS-ERR-STAT NOT = '00'
              MOVE 'OUTPUT FILE OPEN ERROR' TO ERR-DESCRIPTION
              PERFORM ERROR-LOG-000
              SET BATCH-ERROR TO TRUE
              PERFORM FINALIZE-000
              MOVE SYS-RET-CODE TO RETURN-CODE
              STOP RUN
           ELSE
               CONTINUE
           END-IF.

       INIT-999.
           EXIT.

      *----------------------------------------------------------------*
      * INPUT-PROC                    SECTION.
      *----------------------------------------------------------------*
       INPUT-PROC                     SECTION.
       INPUT-PROC-000.
           MOVE 'N' TO WS-EOF-FLAG.
           READ IN-FILE
               AT END     MOVE 'Y' TO WS-EOF-FLAG
               NOT AT END CONTINUE
           END-READ.

           PERFORM INPUT-PROC-LOOP-000
               UNTIL WS-EOF.
       INPUT-PROC-999.
           EXIT.

      *----------------------------------------------------------------*
      * INPUT-PROC-LOOP               SECTION.
      *----------------------------------------------------------------*
       INPUT-PROC-LOOP                SECTION.
       INPUT-PROC-LOOP-000.
           MOVE IN-REC TO FILE-CONTROL-REC.

           EVALUATE TRUE
               WHEN IS-HEADER
                   PERFORM PROCESS-HEADER-000
               WHEN IS-TRAILER 
                   PERFORM PROCESS-TRAILER-000
               WHEN IS-DATA
                   MOVE IN-REC TO TRX-RECORD
                   PERFORM VALIDATE-DATA-000
                   IF WS-VALID
                       MOVE IN-REC   TO SORT-REC
                       RELEASE SORT-REC
                   END-IF 
           END-EVALUATE.

           READ IN-FILE
               AT END     MOVE 'Y' TO WS-EOF-FLAG
               NOT AT END CONTINUE
           END-READ.
       INPUT-PROC-LOOP-999.
           EXIT.

      *----------------------------------------------------------------*
      * OUTPUT-PROC                   SECTION.
      *----------------------------------------------------------------*
       OUTPUT-PROC                    SECTION.
       OUTPUT-PROC-000.
           MOVE 'N' TO WS-SORT-EOF-FLAG.
           RETURN SORT-FILE
               AT END     MOVE 'Y' TO WS-SORT-EOF-FLAG
               NOT AT END CONTINUE
           END-RETURN.

           PERFORM OUTPUT-PROC-LOOP-000
               UNTIL WS-SORT-EOF.
       OUTPUT-PROC-999.
           EXIT.

      *----------------------------------------------------------------*
      * OUTPUT-PROC-LOOP              SECTION.
      *----------------------------------------------------------------*
       OUTPUT-PROC-LOOP               SECTION.
       OUTPUT-PROC-LOOP-000.
           MOVE SORT-REC TO OUT-REC.
           WRITE OUT-REC.

           ADD 1 TO WS-CALC-CNT.

           COMPUTE WS-MOD-WORK = FUNCTION MOD(WS-CALC-CNT,
                                              WS-COMMIT-LIMIT).
           IF WS-MOD-WORK = 0
               PERFORM PROGRESS-LOG-000
           END-IF.

           RETURN SORT-FILE
               AT END     MOVE 'Y' TO WS-SORT-EOF-FLAG
               NOT AT END CONTINUE
           END-RETURN.
       OUTPUT-PROC-LOOP-999.
           EXIT.

      *----------------------------------------------------------------*
      * PROCESS-HEADER                SECTION.
      *----------------------------------------------------------------*
       PROCESS-HEADER                 SECTION.
       PROCESS-HEADER-000.
           MOVE IN-REC TO OUT-REC.
           WRITE OUT-REC.
           MOVE HDR-CREATE-DATE TO WS-HEADER-DATE.
           DISPLAY ' > HEADER  RECORD DETECTED: ' WS-HEADER-DATE.
       PROCESS-HEADER-999.
           EXIT.

      *----------------------------------------------------------------*
      * PROCESS-TRAILER               SECTION.
      *----------------------------------------------------------------*
       PROCESS-TRAILER                SECTION.
       PROCESS-TRAILER-000.

           MOVE IN-REC TO OUT-REC.
           WRITE OUT-REC.
           MOVE TRL-TOT-CNT TO WS-TRAILER-COUNT.
           DISPLAY ' > TRAILER RECORD DETECTED: ' WS-TRAILER-COUNT.     

       PROCESS-TRAILER-999.
           EXIT.

      *----------------------------------------------------------------*
      * VALIDATE-DATA                 SECTION.
      *----------------------------------------------------------------*
       VALIDATE-DATA                  SECTION.
       VALIDATE-DATA-000.
           SET WS-VALID TO TRUE.
           
           MOVE IN-REC TO TRX-RECORD.
      *    INSPECT: ????(TAB/CR/LF) ?? ???
           MOVE 0 TO WS-INSPECT-CNT.
           INSPECT TRX-RECORD
               TALLYING WS-INSPECT-CNT FOR ALL X'09'
                                            ALL X'0D'
                                            ALL X'0A'.

           IF WS-INSPECT-CNT > 0 THEN
              PERFORM VALIDATE-ERR-CTRL-CHAR-000
           ELSE
              MOVE SPACES TO TRX-RECORD
              MOVE 0 TO WS-TRX-COUNT
   
              UNSTRING IN-REC
                  DELIMITED BY SPACE
                  INTO TRX-HEADER
                       TRX-DATE
                       TRX-SEQ      COUNT IN WS-CNT-SEQ
                       INST-CD
                       ACC-NO       COUNT IN WS-CNT-ACC
                       TRX-TYPE
                       WS-LOG-TRX-AMT
                  TALLYING WS-TRX-COUNT
                  ON OVERFLOW
                      PERFORM VALIDATE-ERR-OVERFLOW-000
                  NOT ON OVERFLOW
      *       TRX-SEQ 数値チェック
                       IF WS-TRX-COUNT NOT = 7
                           PERFORM VALIDATE-ERR-FIELD-000
                       ELSE IF TRX-SEQ NOT NUMERIC 
                                           OR WS-CNT-SEQ NOT = 10
                           PERFORM VALIDATE-ERR-SEQ-000
                       ELSE IF INST-CD = SPACES
                          PERFORM  VALIDATE-ERR-INST-000
                       ELSE IF ACC-NO  = SPACES OR WS-CNT-ACC NOT = 15
                          PERFORM  VALIDATE-ERR-ACC-000
                       ELSE IF TRX-TYPE NOT EQUAL 'I' 
                               AND TRX-TYPE NOT EQUAL 'O'
                          PERFORM VALIDATE-ERR-TYPE-000
                       ELSE IF WS-LOG-TRX-AMT NOT NUMERIC
                          PERFORM VALIDATE-ERR-AMT-000
                       ELSE
                          IF TRX-TYPE = 'I'
                             MOVE WS-LOG-TRX-AMT TO TRX-AMT
                             ADD FUNCTION NUMVAL(WS-LOG-TRX-AMT) 
                                   TO WS-CALC-AMT
                          ELSE
                             MOVE WS-LOG-TRX-AMT TO TRX-AMT
                             SUBTRACT FUNCTION NUMVAL(WS-LOG-TRX-AMT) 
                                      FROM WS-CALC-AMT
                          END-IF
                       END-IF
              END-UNSTRING
           END-IF.
                 
       VALIDATE-DATA-999.
           EXIT.

      *----------------------------------------------------------------*
      * VALIDATE-ERR-FIELD            SECTION.
      *----------------------------------------------------------------*
       VALIDATE-ERR-FIELD             SECTION.
       VALIDATE-ERR-FIELD-000.
           SET WS-INVALID TO TRUE.
           ADD 1 TO WS-ERR-CNT.
           ADD 1 TO WS-INSPECT-CNT
           MOVE IN-REC TO ERR-REC.
           WRITE ERR-REC.
           DISPLAY ' > [' WS-ERR-FIELD '] FIELD COUNT INCORRECT : ['
                  WS-INSPECT-CNT']'.
       VALIDATE-ERR-FIELD-999.
           EXIT.

      *----------------------------------------------------------------*
      * VALIDATE-ERR-AMT              SECTION.
      *----------------------------------------------------------------*
       VALIDATE-ERR-AMT               SECTION.
       VALIDATE-ERR-AMT-000.
           SET WS-INVALID TO TRUE.
           ADD 1 TO WS-ERR-CNT.
           MOVE IN-REC TO ERR-REC.
           WRITE ERR-REC.
           STRING ' > [' WS-ERR-CODE-AMT '] AMOUNT NOT NUMERIC. SEQ = ['
                  TRX-SEQ'] / AMOUNT = ['WS-LOG-TRX-AMT']'
               DELIMITED BY SIZE
               INTO WS-LOG-BUFFER
               WITH POINTER WS-LOG-PTR
           END-STRING.
           DISPLAY WS-LOG-BUFFER.
           MOVE 1 TO WS-LOG-PTR.
           MOVE SPACES TO WS-LOG-BUFFER.
       VALIDATE-ERR-AMT-999.
           EXIT.

      *----------------------------------------------------------------*
      * VALIDATE-ERR-SEQ              SECTION.
      *----------------------------------------------------------------*
       VALIDATE-ERR-SEQ               SECTION.
       VALIDATE-ERR-SEQ-000.
           SET WS-INVALID TO TRUE.
           ADD 1 TO WS-ERR-CNT.
           MOVE IN-REC TO ERR-REC.
           WRITE ERR-REC.
           DISPLAY ' > [' WS-ERR-CODE-SEQ '] SEQ NOT NUMERIC. SEQ = ['
                    TRX-SEQ']'.
       VALIDATE-ERR-SEQ-999.
           EXIT.

      *----------------------------------------------------------------*
      * VALIDATE-ERR-TYPE             SECTION.
      *----------------------------------------------------------------*
       VALIDATE-ERR-TYPE              SECTION.
       VALIDATE-ERR-TYPE-000.
           SET WS-INVALID TO TRUE.
           ADD 1 TO WS-ERR-CNT.
           MOVE IN-REC TO ERR-REC.
           WRITE ERR-REC.
           DISPLAY ' > [' WS-ERR-CODE-TYPE '] TYPE INVALID. SEQ = ['
                   TRX-SEQ'] / TYPE = [' TRX-TYPE']'.
       VALIDATE-ERR-TYPE-999.
           EXIT.

      *----------------------------------------------------------------*
      * VALIDATE-ERR-INST             SECTION.
      *----------------------------------------------------------------*
       VALIDATE-ERR-INST              SECTION.
       VALIDATE-ERR-INST-000.
           SET WS-INVALID TO TRUE.
           ADD 1 TO WS-ERR-CNT.
           MOVE IN-REC TO ERR-REC.
           WRITE ERR-REC.
           DISPLAY ' > [' WS-ERR-CODE-INST  '] INSTITUTION INVALID.' 
                   'SEQ = ['TRX-SEQ'] / INST = [' INST-CD']'.
       VALIDATE-ERR-INST-999.
           EXIT.

      *----------------------------------------------------------------*
      * VALIDATE-ERR-ACC              SECTION.
      *----------------------------------------------------------------*
       VALIDATE-ERR-ACC               SECTION.
       VALIDATE-ERR-ACC-000.
           SET WS-INVALID TO TRUE.
           ADD 1 TO WS-ERR-CNT.
           MOVE IN-REC TO ERR-REC.
           WRITE ERR-REC.
           DISPLAY ' > [' WS-ERR-CODE-ACC   '] ACCOUNT INVALID.' 
                   'SEQ = ['TRX-SEQ'] / ACC = [' ACC-NO']'.
       VALIDATE-ERR-ACC-999.
           EXIT.

      *----------------------------------------------------------------*
      * VALIDATE-ERR-CTRL-CHAR        SECTION.
      *----------------------------------------------------------------*
       VALIDATE-ERR-CTRL-CHAR         SECTION.
       VALIDATE-ERR-CTRL-CHAR-000.
           SET WS-INVALID TO TRUE.
           ADD 1 TO WS-ERR-CNT.
           MOVE IN-REC TO ERR-REC.
           WRITE ERR-REC.
           DISPLAY ' > [' WS-ERR-CODE-CTRL
                   '] CTRL CHAR DETECTED : ['
                   WS-INSPECT-CNT '] CHARS'.
       VALIDATE-ERR-CTRL-CHAR-999.
           EXIT.

      *----------------------------------------------------------------*
      * VALIDATE-ERR-OVERFLOW         SECTION.
      *----------------------------------------------------------------*
       VALIDATE-ERR-OVERFLOW           SECTION.
       VALIDATE-ERR-OVERFLOW-000.
           SET WS-INVALID TO TRUE.
           ADD 1 TO WS-ERR-CNT.
           MOVE IN-REC TO ERR-REC.
           WRITE ERR-REC.
           DISPLAY ' > [' WS-ERR-CODE-OVF
                   '] UNSTRING OVERFLOW DETECTED'.
       VALIDATE-ERR-OVERFLOW-999.
           EXIT.

      *----------------------------------------------------------------*
      * PROGRESS-LOG                  SECTION.
      *----------------------------------------------------------------*
       PROGRESS-LOG                   SECTION.
       PROGRESS-LOG-000.
           DISPLAY ' > ... ' WS-CALC-CNT ' DATA RECORDS PROCESSED... <'.
       PROGRESS-LOG-999.
           EXIT.

      *----------------------------------------------------------------*
      * CHECK-COUNT                   SECTION.
      *----------------------------------------------------------------*
       CHECK-COUNT                    SECTION.
       CHECK-COUNT-000.

           DISPLAY ' [DEBUG] '
                    WS-CALC-CNT ' + ' WS-ERR-CNT ' = ' TRL-TOT-CNT.

           DISPLAY ' [DEBUG] '
                    WS-CALC-AMT ' = ' 
                    FUNCTION NUMVAL(TRL-TOT-AMT).      


           IF WS-CALC-CNT + WS-ERR-CNT NOT = TRL-TOT-CNT
           OR WS-CALC-AMT NOT = FUNCTION NUMVAL(TRL-TOT-AMT)
               MOVE 'TRAILER AMOUNT/COUNT MISMATCH' TO ERR-DESCRIPTION
               PERFORM ERROR-LOG-000
               SET BATCH-ERROR TO TRUE
           ELSE
               DISPLAY ' > TRAILER VALIDATION SUCCESS!'
           END-IF.

       CHECK-COUNT-999.
           EXIT.

      *----------------------------------------------------------------*
      * FINALIZE                      SECTION.
      *----------------------------------------------------------------*
       FINALIZE                       SECTION.
       FINALIZE-000.
           CLOSE IN-FILE OUT-FILE ERR-FILE.

           DISPLAY ' > ========= PGM-PHASE1 RESULT ========='.
           DISPLAY ' > VALID COUNT : ' WS-CALC-CNT.
           DISPLAY ' > VALID AMOUNT: ' WS-CALC-AMT.
           DISPLAY ' > ERROR COUNT : ' WS-ERR-CNT.
           DISPLAY ' > ====================================='.

      * --- ?? ?? END ?? (PGM-BLOGSVR ??) ---
           PERFORM BLOGSVR-END-000.
       FINALIZE-999.
           EXIT.

      *----------------------------------------------------------------*
      * ERROR-LOG                     SECTION.
      *----------------------------------------------------------------*
       ERROR-LOG                      SECTION.
       ERROR-LOG-000.
           MOVE WS-PROG-NAME TO ERR-PGM-ID.
           SET ERR-FATAL TO TRUE.
           DISPLAY '*** SYSTEM ERROR OCCURRED ***'.
           DISPLAY 'PGM: ' ERR-PGM-ID ' | MSG: ' ERR-DESCRIPTION.
       ERROR-LOG-999.
           EXIT.
      *----------------------------------------------------------------*
      * BLOGSVR-START                 SECTION.
      *----------------------------------------------------------------*
       BLOGSVR-START                  SECTION.
       BLOGSVR-START-000.
           MOVE WS-PROG-NAME          TO BLG-PGM-ID.
           MOVE SYS-BIZ-DATE          TO BLG-BIZ-DATE.
           MOVE 'PHASE1 STARTED'      TO BLG-REMARK.
           MOVE 'START'               TO BLG-ACTION.

           CALL 'PGM-BLOGSVR' USING DCL-TB-BATCH-LOG.

           IF BLG-RETURN-CODE NOT = 0 THEN
               DISPLAY '> [WARN] BLOGSVR START FAILED. RC='
                       BLG-RETURN-CODE
           ELSE
               CONTINUE
           END-IF.
       BLOGSVR-START-999.
           EXIT.

      *----------------------------------------------------------------*
      * BLOGSVR-END                   SECTION.
      *----------------------------------------------------------------*
       BLOGSVR-END                    SECTION.
       BLOGSVR-END-000.
           MOVE WS-CALC-CNT           TO BLG-PROC-CNT.
           MOVE WS-ERR-CNT            TO BLG-ERR-CNT.
           MOVE 'END  '               TO BLG-ACTION.

           IF WS-ERR-CNT > 0 THEN
               MOVE 'E'               TO BLG-STAT
               MOVE 'PHASE1 COMPLETED WITH ERRORS' TO BLG-REMARK
           ELSE
               MOVE 'S'               TO BLG-STAT
               MOVE 'PHASE1 COMPLETED SUCCESSFULLY' TO BLG-REMARK
           END-IF.

           CALL 'PGM-BLOGSVR' USING DCL-TB-BATCH-LOG.

           IF BLG-RETURN-CODE NOT = 0 THEN
               DISPLAY '> [WARN] BLOGSVR END FAILED. RC='
                       BLG-RETURN-CODE
           ELSE
               CONTINUE
           END-IF.
       BLOGSVR-END-999.
           EXIT.
      *================================================================*
      * END OF PGM-PHASE1
      *================================================================*
           
