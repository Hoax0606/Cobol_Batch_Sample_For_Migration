      *================================================================*
      * PGM-PHASE1.cbl - File to File
      * 1. 시스템 공통 변수(SYS-COM) 초기화
      * 2. Header/Trailer (FILE-CTRL) 정합성 대사 (건수/금액)
      * 3. REDEFINES 및 공통 로그(ERR-LOG) 처리를 통한 Java 전환 테스트
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
      *================================================================*
      * DATA                          DIVISION.
      *================================================================*
       DATA                           DIVISION.
       FILE                           SECTION.
       FD  IN-FILE.
       01  IN-REC                     PIC X(50).

       FD  OUT-FILE.
       01  OUT-REC                    PIC X(50).

       FD  ERR-FILE.
       01  ERR-REC                    PIC X(50).

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
           05 WS-VALID-FLAG           PIC X(1) VALUE 'Y'.

       01  WS-CALC-TOTALS.
           05 WS-CALC-CNT             PIC 9(10) VALUE 0.
           05 WS-CALC-AMT             PIC 9(15) VALUE 0.
           
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
           PERFORM PROCESS-000 UNTIL WS-EOF-FLAG = 'Y'.
           PERFORM FINALIZE-000.
           STOP RUN.
       MAIN-999.
           EXIT.
      *----------------------------------------------------------------*
      * INIT                          SECTION.
      *----------------------------------------------------------------*
       INIT                           SECTION.
       INIT-000.
           MOVE 'PHASE1'         TO SYS-JOB-ID.
           MOVE '20260306'       TO SYS-BIZ-DATE.
           
      *    ファイルオープン
           OPEN INPUT IN-FILE
                OUTPUT OUT-FILE
                OUTPUT ERR-FILE.
                
           IF WS-IN-STAT NOT = '00'
               MOVE 'INPUT FILE OPEN ERROR' TO ERR-DESCRIPTION
               PERFORM ERROR-LOG-000
               PERFORM FINALIZE-000
               STOP RUN
           END-IF.
           
           PERFORM READ-IN-FILE-000.
       INIT-999.
           EXIT.

      *----------------------------------------------------------------*
      * DATA-PROCESS                  SECTION.
      *----------------------------------------------------------------*
       DATA-PROCESS                   SECTION.
       PROCESS-000.
           MOVE IN-REC TO FILE-CONTROL-REC.

           EVALUATE REC-TYPE
               WHEN 'H'
                   PERFORM PROCESS-HEADER-000
               WHEN 'T'
                   PERFORM 2300-PROCESS-TRAILER
               WHEN OTHER
                   MOVE IN-REC TO TRX-RECORD
                   PERFORM 2400-PROCESS-DATA
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
                   MOVE 'Y' TO WS-EOF-FLAG
               NOT AT END
                   CONTINUE
           END-READ.
       READ-IN-FILE-999.
           EXIT.
      *----------------------------------------------------------------*
      * PROCESS-HEADER                SECTION.
      *----------------------------------------------------------------*
       PROCESS-HEADER                 SECTION.  
       PROCESS-HEADER-000.
           MOVE IN-REC TO OUT-REC.
           WRITE OUT-REC.
           DISPLAY '>>> HEADER RECORD DETECTED: ' HDR-FILE-ID.
       PROCESS-HEADER-999.
           EXIT.

      *----------------------------------------------------------------*
      * PROCESS-TRAILER               SECTION.
      *----------------------------------------------------------------*
       PROCESS-TRAILER                SECTION. 
       2300-PROCESS-TRAILER.
           IF WS-CALC-CNT NOT = TRL-TOT-CNT OR WS-CALC-AMT NOT
            = TRL-TOT-AMT
               MOVE 'TRAILER AMOUNT/COUNT MISMATCH' TO ERR-DESCRIPTION
               PERFORM ERROR-LOG-000
               SET BATCH-ERROR TO TRUE
           ELSE
               DISPLAY '>>> TRAILER VALIDATION SUCCESS!'.
               
           MOVE IN-REC TO OUT-REC.
           WRITE OUT-REC.
       PROCESS-TRAILER-999.
           EXIT.

      *----------------------------------------------------------------*
      * PROCESS-DATA                  SECTION.
      *----------------------------------------------------------------*
       PROCESS-DATA                   SECTION. 
       2400-PROCESS-DATA.
           MOVE 'Y' TO WS-VALID-FLAG.
           
      *    TRX-AMTが数値かを調べる
           IF TRX-AMT NOT NUMERIC
               DISPLAY "ERR: AMT IS NOT NUMERIC. RECORD=" TRX-RECORD
               MOVE 'N' TO WS-VALID-FLAG
           END-IF
      *    TRX-SEQが数値かを調べる
           IF TRX-SEQ NOT NUMERIC
               display "ERR: SEQ IS NOT NUMERIC. RECORD=" TRX-RECORD
               MOVE 'N' TO WS-VALID-FLAG
           END-IF
      *    TRX-TYPEが'I'または'O'になっているかを調べる
           IF TRX-TYPE NOT = 'I' AND NOT = 'O'
               DISPLAY "ERR: TYPE IS NOT 'I' OR 'O'. RECORD=" TRX-RECORD
               MOVE 'N' TO WS-VALID-FLAG
           END-IF.
      *    INST-CD,ACC-NOのNULLチェック
           IF INST-CD = SPACES OR ACC-NO = SPACES
               MOVE 'N' TO WS-VALID-FLAG
           END-IF.

           IF WS-VALID-FLAG = 'Y'
      *        正常データの場合の処理
               ADD 1 TO WS-CALC-CNT
               ADD TRX-AMT TO WS-CALC-AMT
               
               MOVE IN-REC TO OUT-REC
               WRITE OUT-REC
               
               IF FUNCTION MOD(WS-CALC-CNT, 1000000) = 0
                   DISPLAY '... ' WS-CALC-CNT ' DATA RECORDS PROCESSED'
               END-IF
           ELSE
      *        異常データの場合の処理
               MOVE IN-REC TO ERR-REC
               WRITE ERR-REC
           END-IF.
       PROCESS-DATA-999.
           EXIT.

      *----------------------------------------------------------------*
      * FINALIZE                      SECTION.
      *----------------------------------------------------------------*
       FINALIZE                       SECTION.
       FINALIZE-000.
           CLOSE IN-FILE OUT-FILE ERR-FILE.
           
           DISPLAY ' > ========= PGM-PHASE1 RESULT ========='.
      *    DISPLAY ' > [PHASE 1] FILE TO FILE BATCH COMPLETED'.
      *    DISPLAY ' > JOB ID      : ' SYS-JOB-ID.
      *    DISPLAY ' > BIZ DATE    : ' SYS-BIZ-DATE.
           DISPLAY ' > VALID COUNT : ' WS-CALC-CNT.
           DISPLAY ' > VALID AMOUNT: ' WS-CALC-AMT.
           DISPLAY ' > ====================================='.
       FINALIZE-999.
           EXIT.

      *----------------------------------------------------------------*
      * ERROR-LOG                     SECTION.
      *----------------------------------------------------------------*
       ERROR-LOG                      SECTION.
       ERROR-LOG-000.
           MOVE 'PGM-PHASE1' TO ERR-PGM-ID.
           SET ERR-FATAL TO TRUE.
           DISPLAY '*** SYSTEM ERROR OCCURRED ***'.
           DISPLAY 'PGM: ' ERR-PGM-ID ' | MSG: ' ERR-DESCRIPTION.
       ERROR-LOG-999.
           EXIT.
      *================================================================*
      * END OF PGM-PHASE1
      *================================================================*
