      *================================================================*
      * PGM-PHASE2.cbl - File to DB
      * 1. 공통 COPYBOOK (SYS-COM, ERR-LOG) 적용
      * 2. TB_INST_MASTER 를 메모리 로드 후 SEARCH ALL 로 기관코드 검증
      * 3. 검증 실패 레코드는 DISPLAY 로그만 출력 후 스킵
      * 4. Header/Trailer 레코드 식별 및 Skip (데이터 무결성 확보)
      * 5. DB Insert 시 SQLCODE 에러를 공통 에러 로그 체계로 연동
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
      *    Phase 1에서 생성된 CLEANSED_DATA.txt 파일을 입력으로 사용
           SELECT IN-FILE ASSIGN TO 'INFILE_VAR'
                  ORGANIZATION IS LINE SEQUENTIAL
                  FILE STATUS IS WS-IN-STAT.
      *================================================================*
      * DATA                          DIVISION.
      *================================================================*
       DATA                           DIVISION.
       FILE                           SECTION.
       FD  IN-FILE.
       01  IN-REC                     PIC X(50).

       WORKING-STORAGE                SECTION.
      *    시스템 공통 영역 및 에러 로그 Include
       COPY SYS-COM.
       COPY ERR-LOG.
       COPY FILE-CTRL.
       COPY TRX-REC.

      *    SQLCA 및 DB DCLGEN Include
       EXEC SQL INCLUDE SQLCA END-EXEC.
       EXEC SQL INCLUDE SQL-DCLGEN END-EXEC.
       EXEC SQL INCLUDE INST-TBL END-EXEC.

      *    파일 상태 및 제어 플래그
       01  WS-IN-STAT                 PIC X(2).

       01  WS-FLAGS.
           05 WS-EOF-FLAG             PIC X(1) VALUE 'N'.
              88 WS-EOF               VALUE 'Y'.
              88 WS-NOT-EOF           VALUE 'N'.
           05 WS-INST-VALID           PIC X(1) VALUE 'Y'.
              88 INST-VALID-OK        VALUE 'Y'.
              88 INST-VALID-NG        VALUE 'N'.
       
      *    처리 건수 집계 변수
       01  WS-COUNTERS.
           05 WS-READ-CNT             PIC 9(10) VALUE 0.
           05 WS-INSERT-CNT           PIC 9(10) VALUE 0.
           05 WS-SKIP-CNT             PIC 9(5)  VALUE 0.
           05 WS-COMMIT-CNT           PIC 9(5)  VALUE 0.
           05 WS-ERR-CNT              PIC 9(5)  VALUE 0.
       
       01  WS-CONSTANTS.
           05 WS-COMMIT-INTERVAL      PIC 9(5)  VALUE 1000.
       
      *    DB 접속 정보 호스트 변수
       01 WS-DATASRC                  PIC X(30) 
                                      VALUE 'SB_VaF_Education_JP.db'.
       01 WS-USER                     PIC X(10) VALUE 'gixsql'.
       01 WS-PWD                      PIC X(10) VALUE 'gixsql'.

      *    COMP 계열 다양한 타입 사용
       01  WS-NUMERIC-WORK.
           05 WS-FEE-AMT-COMP         PIC S9(12) COMP-3.
           05 WS-SEQ-COMP             PIC S9(10) COMP.
           05 WS-AMT-COMP4            PIC S9(12) COMP-4.
           05 WS-IDX-WORK             PIC 9(4)   COMP-5.
           05 WS-FLOAT-RATE           COMP-1     VALUE 0.01.
           05 WS-DBL-WORK             COMP-2     VALUE 0.

      *    INSPECT 용 카운터
       01  WS-SPACE-CNT               PIC 9(5)   VALUE 0.

      *    77 레벨: 독립 단일 항목
       77  WS-PROG-NAME               PIC X(10)  VALUE 'PGM-PHASE2'.
       77  WS-PHASE-ID                PIC X(8)   VALUE 'PHASE2'.

      *    78 레벨: 오류코드 상수
       78  ERR-CD-DB                  VALUE 'E020'.

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
           PERFORM PROCESS-000 UNTIL WS-EOF.
           PERFORM FINALIZE-000.
       MAIN-999.
           STOP RUN.
      *----------------------------------------------------------------*
      * INIT                          SECTION.
      *----------------------------------------------------------------*
       INIT                           SECTION.
       INIT-000.
      *    시스템 공통 변수 초기화
           MOVE WS-PHASE-ID         TO SYS-JOB-ID.
           MOVE FUNCTION CURRENT-DATE(1:8) TO SYS-BIZ-DATE.

           OPEN INPUT IN-FILE.
           IF WS-IN-STAT NOT = '00'
               MOVE 'INPUT FILE OPEN ERROR' TO ERR-DESCRIPTION
               PERFORM SYSTEM-ERROR-000
               STOP RUN
           ELSE
               CONTINUE
           END-IF.

           EXEC SQL
               CONNECT :WS-USER IDENTIFIED BY :WS-PWD
                       USING :WS-DATASRC
           END-EXEC.

           IF SQLCODE NOT = 0
               MOVE SQLCODE TO ERR-SQLCODE
               MOVE 'DB CONNECT ERROR' TO ERR-DESCRIPTION
               PERFORM SYSTEM-ERROR-000
               STOP RUN
           END-IF.

           EXEC SQL DELETE FROM TB_STG_TRX END-EXEC.
           EXEC SQL COMMIT END-EXEC.

      *    TB_INST_MASTER 메모리 로드 (SEARCH ALL 용)
           PERFORM LOAD-INST-MASTER-000.

           PERFORM READ-IN-FILE-000.
       INIT-999.
           EXIT.

      *----------------------------------------------------------------*
      * LOAD-INST-MASTER              SECTION.
      * TB_INST_MASTER を全件メモリロードし SEARCH ALL の準備
      *----------------------------------------------------------------*
       LOAD-INST-MASTER               SECTION.
       LOAD-INST-MASTER-000.
           MOVE 0 TO INST-MAX-CNT.
           MOVE 1 TO WS-IDX-WORK.

           EXEC SQL
               DECLARE C-INST-MST CURSOR FOR
               SELECT INST_CD, INST_NAME, INST_STAT
                 FROM TB_INST_MASTER
                ORDER BY INST_CD ASC
           END-EXEC.

           EXEC SQL OPEN C-INST-MST END-EXEC.
           IF SQLCODE NOT = 0
               MOVE SQLCODE TO ERR-SQLCODE
               MOVE 'CURSOR OPEN: C-INST-MST' TO ERR-DESCRIPTION
               PERFORM SYSTEM-ERROR-000
               STOP RUN
           END-IF.

           PERFORM LOAD-INST-FETCH-000
               UNTIL WS-IDX-WORK > 100.

           EXEC SQL CLOSE C-INST-MST END-EXEC.
           MOVE WS-IDX-WORK TO INST-MAX-CNT.
           SUBTRACT 1 FROM INST-MAX-CNT.

           DISPLAY '>>> INST MASTER LOADED: ' INST-MAX-CNT ' RECORDS'.
       LOAD-INST-MASTER-999.
           EXIT.

       LOAD-INST-FETCH-000.
           EXEC SQL
               FETCH C-INST-MST
                INTO :MST-INST-CD, :MST-INST-NAME, :MST-INST-STAT
           END-EXEC.

           EVALUATE SQLCODE
               WHEN 0
                   SET INST-IDX TO WS-IDX-WORK
                   MOVE MST-INST-CD   TO INST-TBL-CD(INST-IDX)
                   MOVE MST-INST-NAME TO INST-TBL-NAME(INST-IDX)
                   MOVE MST-INST-STAT TO INST-TBL-STAT(INST-IDX)
                   ADD 1 TO WS-IDX-WORK
               WHEN 100
                   MOVE 101 TO WS-IDX-WORK
               WHEN OTHER
                   MOVE SQLCODE TO ERR-SQLCODE
                   MOVE 'FETCH ERROR: C-INST-MST' TO ERR-DESCRIPTION
                   PERFORM DB-ERROR-000
                   MOVE 101 TO WS-IDX-WORK
           END-EVALUATE.
       LOAD-INST-FETCH-999.
           EXIT.

      *----------------------------------------------------------------*
      * DATA-PROCESS                  SECTION.
      *----------------------------------------------------------------*
       DATA-PROCESS                   SECTION.
       PROCESS-000.
      *    レコードタイプ(H/D/T) 식별을 위한 버퍼 매핑
           MOVE IN-REC TO FILE-CONTROL-REC.

           EVALUATE REC-TYPE
               WHEN 'H'
               WHEN 'T'
                   ADD 1 TO WS-SKIP-CNT
               WHEN OTHER
                   MOVE IN-REC TO TRX-RECORD
                   PERFORM VALIDATE-INST-000
                   IF INST-VALID-OK
                   PERFORM INSERT-DB-000
                   ELSE
                       ADD 1 TO WS-ERR-CNT
      *                DISPLAY '>>> INST NG SKIP: SEQ=' TRX-SEQ
      *                        ' CD=' INST-CD
                   END-IF
           END-EVALUATE.

           PERFORM READ-IN-FILE-000.
       PROCESS-999.
           EXIT.

      *----------------------------------------------------------------*
      * VALIDATE-INST                 SECTION.
      * SEARCH ALL で기관코드를 검증
      *----------------------------------------------------------------*
       VALIDATE-INST                  SECTION.
       VALIDATE-INST-000.
           SET INST-NOT-FOUND TO TRUE.
           SET INST-VALID-OK  TO TRUE.

           SEARCH ALL INST-ENTRY
               AT END
                   SET INST-NOT-FOUND TO TRUE
               WHEN INST-TBL-CD(INST-IDX) = INST-CD
                   SET INST-FOUND TO TRUE
           END-SEARCH.

           IF INST-NOT-FOUND
               SET INST-VALID-NG TO TRUE
           ELSE
               IF INST-INACTIVE(INST-IDX)
                   SET INST-VALID-NG TO TRUE
               END-IF
           END-IF.
       VALIDATE-INST-999.
           EXIT.

      *----------------------------------------------------------------*
      * READ-IN-FILE                  SECTION.
      *----------------------------------------------------------------*
       READ-IN-FILE                   SECTION.
       READ-IN-FILE-000.
           READ IN-FILE
               AT END
                   SET WS-EOF TO TRUE
               NOT AT END
                   ADD 1 TO WS-READ-CNT
           END-READ.
       READ-IN-FILE-999.
           EXIT.

      *----------------------------------------------------------------*
      * INSERT-DB                     SECTION.
      *----------------------------------------------------------------*
       INSERT-DB                      SECTION.  
       INSERT-DB-000.
           MOVE TRX-DATE         TO STG-TRX-DATE.
           MOVE TRX-SEQ          TO STG-TRX-SEQ.
           MOVE INST-CD          TO STG-INST-CD.
           MOVE ACC-NO           TO STG-ACC-NO.
           MOVE TRX-TYPE         TO STG-TRX-TYPE.
           MOVE TRX-AMT          TO STG-TRX-AMT.
           COMPUTE WS-FEE-AMT-COMP = STG-TRX-AMT * WS-FLOAT-RATE.
           MOVE WS-FEE-AMT-COMP  TO STG-FEE-AMT.
           MOVE '0'              TO STG-PROC-STAT.
       
           EXEC SQL
               INSERT INTO TB_STG_TRX
                      (TRX_DATE, TRX_SEQ, INST_CD, ACC_NO,
                       TRX_TYPE, TRX_AMT, FEE_AMT, PROC_STAT)
               VALUES (:STG-TRX-DATE, :STG-TRX-SEQ,
                       :STG-INST-CD,  :STG-ACC-NO,
                       :STG-TRX-TYPE, :STG-TRX-AMT,
                       :STG-FEE-AMT,  :STG-PROC-STAT)
           END-EXEC.
       
           IF SQLCODE = 0
               ADD 1 TO WS-INSERT-CNT
               ADD 1 TO WS-COMMIT-CNT
           ELSE
               ADD 1 TO WS-ERR-CNT
               MOVE SQLCODE TO ERR-SQLCODE
               MOVE 'DB INSERT ERROR' TO ERR-DESCRIPTION
               PERFORM DB-ERROR-000
           END-IF.
       
           IF WS-COMMIT-CNT >= WS-COMMIT-INTERVAL
               EXEC SQL COMMIT END-EXEC
               MOVE 0 TO WS-COMMIT-CNT
           END-IF.
        INSERT-DB-999.
           EXIT.

      *----------------------------------------------------------------*
      * FINALIZE                      SECTION.
      *----------------------------------------------------------------*
       FINALIZE                       SECTION.
       FINALIZE-000.
           IF WS-COMMIT-CNT > 0
               EXEC SQL COMMIT END-EXEC
           END-IF.

           CLOSE IN-FILE.
           EXEC SQL DISCONNECT CURRENT END-EXEC.

           DISPLAY ' > ========= PGM-PHASE2 RESULT ========='.
           DISPLAY ' > TOTAL READ    : ' WS-READ-CNT.
           DISPLAY ' > TOTAL INSERT  : ' WS-INSERT-CNT.
           DISPLAY ' > SKIPPED (H/T) : ' WS-SKIP-CNT.
           DISPLAY ' > INST NG SKIP  : ' WS-ERR-CNT.
           DISPLAY ' > ====================================='.
        FINALIZE-999.
           EXIT.

      *----------------------------------------------------------------*
      * SYSTEM-ERROR                  SECTION.
      *----------------------------------------------------------------*
       SYSTEM-ERROR                   SECTION.
       SYSTEM-ERROR-000.
           MOVE WS-PROG-NAME TO ERR-PGM-ID.
           SET ERR-FATAL TO TRUE.
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
           MOVE WS-PROG-NAME TO ERR-PGM-ID.
           SET ERR-WARN TO TRUE.
           SET BATCH-WARNING TO TRUE.
           DISPLAY '*** DB WARNING *** SEQ: ' STG-TRX-SEQ.
           DISPLAY 'SQLCODE: ' ERR-SQLCODE ' | MSG: ' ERR-DESCRIPTION.
       DB-ERROR-999.
           EXIT.
      *================================================================*
      * END OF PGM-PHASE2
      *================================================================*
