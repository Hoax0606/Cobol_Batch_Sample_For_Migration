      *================================================================*
      * PGM-PHASE2.cbl - File to DB
      * 1. 공통 COPYBOOK (SYS-COM, ERR-LOG) 적용
      * 2. Header/Trailer 레코드 식별 및 Skip (데이터 무결성 확보)
      * 3. DB Insert 시 SQLCODE 에러를 공통 에러 로그 체계로 연동
      * 4. UPDATE 후 INSERT (UPSERT) 처리로 중복 키 에러 방지
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
      * --- Phase 1에서 생성된 CLEANSED_DATA.txt 파일을 입력으로 사용
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
      * --- 시스템 공통 영역 및 에러 로그 Include ---
       COPY SYS-COM.
       COPY ERR-LOG.
       COPY FILE-CTRL.
       COPY TRX-REC.

      * --- SQLCA 및 DB DCLGEN Include ---
       EXEC SQL INCLUDE SQLCA END-EXEC.
       EXEC SQL INCLUDE SQL-DCLGEN END-EXEC.

      * --- 파일 상태 및 제어 플래그 ---
       01  WS-IN-STAT                 PIC X(2).
       01  WS-EOF-FLAG                PIC X(1) VALUE 'N'.
       
      * --- 처리 건수 집계 변수 ---
       01  WS-COUNTERS.
           05 WS-READ-CNT             PIC 9(10) VALUE 0.
           05 WS-INSERT-CNT           PIC 9(10) VALUE 0.
           05 WS-SKIP-CNT             PIC 9(10) VALUE 0.
           05 WS-COMMIT-CNT           PIC 9(5)  VALUE 0.
           05 WS-ERR-CNT              PIC 9(5)  VALUE 0.
       
       01  WS-CONSTANTS.
           05 WS-COMMIT-INTERVAL      PIC 9(5)  VALUE 1000.
       
      * --- DB 접속 정보 호스트 변수 ---
       01 WS-DATASRC                  PIC X(30) 
                                      VALUE 'SB_VaF_Education_JP.db'.
       01 WS-USER                     PIC X(10) VALUE 'gixsql'.
       01 WS-PWD                      PIC X(10) VALUE 'gixsql'.

       01  WS-FEE-AMT-COMP            PIC S9(12) COMP.

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
      *     DISPLAY '-- 4. [WORKING] Inserting to TB_STG_TRX'
           PERFORM PROCESS-000 UNTIL WS-EOF-FLAG = 'Y'.
      *     DISPLAY '-- 4. [SUCCESS] Inserted to TB_STG_TRX'
           PERFORM FINALIZE-000.
       MAIN-999.
           STOP RUN.
      *----------------------------------------------------------------*
      * INIT                          SECTION.
      *----------------------------------------------------------------*
       INIT                           SECTION.
       INIT-000.
      * 시스템 공통 변수 초기화
           MOVE 'PHASE2'         TO SYS-JOB-ID.
           MOVE '20260306'       TO SYS-BIZ-DATE.
           
      *     DISPLAY '-- 1. [WORKING] Opening File ...'

           OPEN INPUT IN-FILE.
           IF WS-IN-STAT NOT = '00'
               MOVE 'INPUT FILE OPEN ERROR' TO ERR-DESCRIPTION
               PERFORM SYSTEM-ERROR-000
               STOP RUN
           END-IF.

      *    DISPLAY '-- 1. [SUCCESS] File Opened'

      *    DISPLAY '-- 2. [WORKING] Connecting to DB ...'
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

      *    DISPLAY '-- 2. [SUCCESS] Connected to DB'
           
      *    DISPLAY '-- 3. [WORKING] Deleting from TB_STG_TRX ...'
      * 매 실행 시 스테이징 비운 뒤 적재 (재실행 시 덮어쓰기)
      *    DISPLAY '-- 3. [SUCCESS] Deleted from TB_STG_TRX'
           EXEC SQL DELETE FROM TB_STG_TRX END-EXEC.
           EXEC SQL COMMIT END-EXEC.

           PERFORM READ-IN-FILE-000.
       INIT-999.
           EXIT.

      *----------------------------------------------------------------*
      * DATA-PROCESS                  SECTION.
      *----------------------------------------------------------------*
       DATA-PROCESS                   SECTION.
       PROCESS-000.
      * 레코드 타입(H/D/T) 식별을 위한 버퍼 매핑
           MOVE IN-REC TO FILE-CONTROL-REC.

           EVALUATE REC-TYPE
               WHEN 'H'
               WHEN 'T'
                   ADD 1 TO WS-SKIP-CNT
                   DISPLAY '>>> HEADER/TRAILER SKIPPED'
               WHEN OTHER
                   MOVE IN-REC TO TRX-RECORD
                   PERFORM INSERT-DB-000
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
           COMPUTE WS-FEE-AMT-COMP = STG-TRX-AMT * 0.01.
           MOVE WS-FEE-AMT-COMP  TO STG-FEE-AMT.
           MOVE '0'              TO STG-PROC-STAT.
       
      *   DELETE로 이미 비웠으므로 UPDATE 없이 바로 INSERT
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
      *    DISPLAY ' > [PHASE 2] FILE TO DB BATCH COMPLETED'.
      *    DISPLAY ' > JOB ID       : ' SYS-JOB-ID.
           DISPLAY ' > TOTAL READ   : ' WS-READ-CNT.
           DISPLAY ' > TOTAL INSERT : ' WS-INSERT-CNT.
           DISPLAY ' > SKIPPED(H/T) : ' WS-SKIP-CNT.
           DISPLAY ' > DB ERRORS    : ' WS-ERR-CNT.
           DISPLAY ' > ====================================='.
        FINALIZE-999.
           EXIT.
      *----------------------------------------------------------------*
      * SYSTEM-ERROR                  SECTION.
      *----------------------------------------------------------------*
       SYSTEM-ERROR                   SECTION.
       SYSTEM-ERROR-000.
           MOVE 'PGM-PHASE2' TO ERR-PGM-ID.
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
           MOVE 'PGM-PHASE2' TO ERR-PGM-ID.
           SET ERR-WARN TO TRUE.
           SET BATCH-WARNING TO TRUE.
           DISPLAY '*** DB INSERT WARNING *** SEQ: ' STG-TRX-SEQ.
           DISPLAY 'SQLCODE: ' ERR-SQLCODE ' | MSG: ' ERR-DESCRIPTION.
       DB-ERROR-999.
           EXIT.
      *================================================================*
      * END OF PGM-PHASE2
      *================================================================*