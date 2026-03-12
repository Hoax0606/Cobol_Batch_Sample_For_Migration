      *================================================================*
      * PGM-PHASE1.cbl - File to File
      * 1. 시스템 공통 변수(SYS-COM) 초기화
      * 2. Header/Trailer (FILE-CTRL) 정합성 대사 (건수/금액)
      * 3. Internal SORT (SORT/RELEASE/RETURN) 로 기관코드 순 정렬
      * 4. STRING/UNSTRING 을 활용한 레코드 파싱 및 로그 조립
      * 5. REDEFINES 및 공통 로그(ERR-LOG) 처리
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
      *    Internal SORT 용 워크 파일
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

      *    SORT 워크파일 SD 정의
       SD  SORT-FILE.
       01  SORT-REC.
           05 SR-HEAD                 PIC X(22).
           05 SR-INST-CD              PIC X(4).
           05 SR-BODY                 PIC X(31).

       WORKING-STORAGE SECTION.
           COPY SYS-COM.
           COPY ERR-LOG.
           COPY FILE-CTRL.
           COPY TRX-REC.

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
           05 WS-CALC-AMT             PIC 9(15)  VALUE 0.
           05 WS-ERR-CNT              PIC 9(10)  VALUE 0.

      * --- COMP 계열 다양한 타입 사용 예시 ---
       01  WS-WORK-AREAS.
           05 WS-MOD-WORK             PIC 9(10) COMP     VALUE 0.
           05 WS-FEE-WORK             PIC S9(12) COMP-3  VALUE 0.
           05 WS-FLOAT-WORK           COMP-1             VALUE 0.
           05 WS-DOUBLE-WORK          COMP-2             VALUE 0.
           05 WS-BIN-WORK             PIC 9(9)  COMP-4   VALUE 0.
           05 WS-NATIVE-WORK          PIC 9(9)  COMP-5   VALUE 0.

      * --- STRING 조립용 로그 버퍼 ---
       01  WS-LOG-BUFFER              PIC X(80)  VALUE SPACES.
       01  WS-LOG-PTR                 PIC 9(3)   VALUE 1.
       01  WS-LOG-TRX-AMT             PIC X(12).

      * --- INSPECT 용 카운터 ---
       01  WS-INSPECT-CNT             PIC 9(5)   VALUE 0.

      * --- 77 레벨: 독립 단일 항목 ---
       77  WS-PROG-NAME               PIC X(10)  VALUE 'PGM-PHASE1'.
       77  WS-PHASE-ID                PIC X(8)   VALUE 'PHASE1'.
       77  WS-HEADER-DATE             PIC ZZZZ/ZZ/ZZ.
       77  WS-TRAILER-COUNT           PIC ZZZZZZZZZZ. 
       77  WS-COMMIT-LIMIT            PIC 9(7)   VALUE 1000.

      * --- 78 레벨: 상수 정의 ---
       78  WS-REC-LENGTH              VALUE 50.
       78  WS-ERR-FIELD               VALUE 'E000'.
       78  WS-ERR-CODE-SEQ            VALUE 'E001'.
       78  WS-ERR-CODE-INST           VALUE 'E002'.
       78  WS-ERR-CODE-ACC            VALUE 'E003'.
       78  WS-ERR-CODE-TYPE           VALUE 'E004'.
       78  WS-ERR-CODE-AMT            VALUE 'E005'.

      *================================================================*
      * PROCEDURE                     DIVISION.
      *================================================================*
       PROCEDURE DIVISION.
      *----------------------------------------------------------------*
      * MAIN                          SECTION.
      *----------------------------------------------------------------*
       MAIN                           SECTION.
       MAIN-000.
           PERFORM INIT-000.
      *    Internal SORT: INPUT/OUTPUT 절에 PERFORM 지정
           SORT SORT-FILE
               ASCENDING KEY SR-INST-CD
               INPUT  PROCEDURE IS INPUT-PROC-000
               OUTPUT PROCEDURE IS OUTPUT-PROC-000.
           PERFORM CHECK-COUNT-000
           PERFORM FINALIZE-000.
           STOP RUN.
       MAIN-999.
           EXIT.
      *----------------------------------------------------------------*
      * INIT                          SECTION.
      *----------------------------------------------------------------*
       INIT                           SECTION.
       INIT-000.
           MOVE WS-PHASE-ID         TO SYS-JOB-ID.
           MOVE FUNCTION CURRENT-DATE(1:8) TO SYS-BIZ-DATE.

           OPEN INPUT  IN-FILE
                OUTPUT OUT-FILE
                OUTPUT ERR-FILE.

           IF WS-IN-STAT NOT = '00'
               MOVE 'INPUT FILE OPEN ERROR' TO ERR-DESCRIPTION
               PERFORM ERROR-LOG-000
               PERFORM FINALIZE-000
               STOP RUN
           ELSE
               CONTINUE
           END-IF.

           IF WS-OUT-STAT NOT = '00' OR WS-ERR-STAT NOT = '00'
              MOVE 'OUTPUT FILE OPEN ERROR' TO ERR-DESCRIPTION
              PERFORM ERROR-LOG-000
              PERFORM FINALIZE-000
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

           EVALUATE REC-TYPE
               WHEN 'H'
                   PERFORM PROCESS-HEADER-000
               WHEN 'T'
                   PERFORM PROCESS-TRAILER-000
               WHEN OTHER
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
      *    INSPECT: スペース個数カウント (문자열 품질 확인 예시)
           MOVE 0 TO WS-INSPECT-CNT.
           INSPECT TRX-RECORD
               TALLYING WS-INSPECT-CNT FOR ALL SPACES.

           IF WS-INSPECT-CNT NOT EQUAL 6 THEN
              PERFORM VALIDATE-ERR-FIELD-000
           ELSE
              MOVE SPACES TO TRX-RECORD
   
              UNSTRING IN-REC
                  DELIMITED BY SPACE
                  INTO TRX-HEADER
                       TRX-DATE
                       TRX-SEQ
                       INST-CD
                       ACC-NO
                       TRX-TYPE
                       WS-LOG-TRX-AMT
                  TALLYING TRX-COUNT
              END-UNSTRING
          
      *       TRX-SEQ 数値チェック
              IF TRX-SEQ NOT NUMERIC
                  PERFORM VALIDATE-ERR-SEQ-000
              ELSE IF INST-CD = SPACES
                 PERFORM  VALIDATE-ERR-INST-000
              ELSE IF ACC-NO  = SPACES
                 PERFORM  VALIDATE-ERR-ACC-000
              ELSE IF TRX-TYPE NOT EQUAL 'I' AND TRX-TYPE NOT EQUAL 'O'
                 PERFORM VALIDATE-ERR-TYPE-000
              ELSE IF WS-LOG-TRX-AMT NOT NUMERIC
                 PERFORM VALIDATE-ERR-AMT-000
              ELSE
                 IF TRX-TYPE = 'I'
                    MOVE WS-LOG-TRX-AMT TO TRX-AMT
                    ADD TRX-AMT TO WS-CALC-AMT
              END-IF
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
                  TRX-SEQ'] / AMOUNT = ['WS-ERR-CODE-AMT']'
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
       VALIDATE-ERR-INST-999.
           EXIT.

      *----------------------------------------------------------------*
      * PROGRESS-LOG                  SECTION.
      *----------------------------------------------------------------*
       PROGRESS-LOG                   SECTION.
       PROGRESS-LOG-000.
           DISPLAY ' >... ' WS-CALC-CNT ' DATA RECORDS PROCESSED...<'.
       PROGRESS-LOG-999.
           EXIT.

      *----------------------------------------------------------------*
      * CHECK-COUNT                   SECTION.
      *----------------------------------------------------------------*
       CHECK-COUNT                    SECTION.
       CHECK-COUNT-000.

      *    DISPLAY " > " WS-CALC-CNT " + " WS-ERR-CNT " = " TRL-TOT-CNT
      *    DISPLAY " > " WS-CALC-AMT " = " TRL-TOT-AMT

           IF WS-CALC-CNT + WS-ERR-CNT NOT = TRL-TOT-CNT
           OR WS-CALC-AMT NOT = TRL-TOT-AMT
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
      *================================================================*
      * END OF PGM-PHASE1
      *================================================================*
      