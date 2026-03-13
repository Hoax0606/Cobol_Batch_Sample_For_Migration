      *================================================================*
      * PGM-PHASE2.cbl - File to DB
      * 1. 공통 COPYBOOK (SYS-COM, ERR-LOG, FILE-CTRL, TRX-REC) 적용
      * 2. INSPECT REPLACING 로 입력 레코드 정규화 (소문자→대문자)
      * 3. Header/Trailer 레코드 식별 및 Skip (H/T 건수 별도 집계)
      * 4. TB_INST_MASTER 조회로 유효 기관코드 검증 및 수수료율 취득
      * 5. TB_STG_TRX 사전 DELETE 후 직접 INSERT (재실행 멱등성 확보)
      * 6. COMMIT INTERVAL 단위 진행 로그 출력
      * 7. DB 접속 정보를 환경변수(GIXSQL_DB_CONN/USER/PWD)로 취득
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
      * --- Phase 1에서 생성된 CLEANSED_DATA.txt 파일을 입력으로 사용 ---
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
      * --- 공통 COPYBOOK ---
       COPY SYS-COM.
       COPY ERR-LOG.
       COPY FILE-CTRL.
       COPY TRX-REC.

      * --- SQLCA 및 DB DCLGEN ---
       EXEC SQL INCLUDE SQLCA END-EXEC.
       EXEC SQL INCLUDE SQL-DCLGEN END-EXEC.

      * --- 파일 상태 ---
       01  WS-FILE-STATUS.
           05 WS-IN-STAT              PIC X(2).

      * --- 제어 플래그 ---
       01  WS-FLAGS.
           05 WS-EOF-FLAG             PIC X(1) VALUE 'N'.
              88 WS-EOF               VALUE 'Y'.
              88 WS-NOT-EOF           VALUE 'N'.
       
      * --- 처리 건수 집계 ---
       01  WS-COUNTERS.
           05 WS-READ-CNT             PIC 9(10) VALUE 0.
           05 WS-INSERT-CNT           PIC 9(10) VALUE 0.
           05 WS-SKIP-CNT             PIC 9(10) VALUE 0.
           05 WS-INST-SKIP-CNT        PIC 9(10) VALUE 0.
           05 WS-COMMIT-CNT           PIC 9(5)  VALUE 0.
           05 WS-ERR-CNT              PIC 9(5)  VALUE 0.
       
      * --- 작업 영역 ---
       01  WS-WORK-AREAS.
           05 WS-FEE-AMT-COMP         PIC S9(12) COMP-3 VALUE 0.
           05 WS-MOD-WORK             PIC 9(10)  COMP   VALUE 0.
       
      * --- DB 접속 정보 (환경변수로 취득) ---
       01  WS-DB-CONN.
           05 WS-DATASRC              PIC X(50)  VALUE SPACES.
           05 WS-USER                 PIC X(30)  VALUE SPACES.
           05 WS-PWD                  PIC X(30)  VALUE SPACES.

      * --- 배치 시작일시 ---
       01  WS-START-DATETIME          PIC X(14)  VALUE SPACES.

      * --- 77 레벨: 독립 단일 항목 ---
       77  WS-PROG-NAME               PIC X(10)  VALUE 'PGM-PHASE2'.
       77  WS-PHASE-ID                PIC X(8)   VALUE 'PHASE2'.

      * --- 78 레벨: 상수 정의 ---
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
           STOP RUN.
       MAIN-999.
           EXIT.

      *----------------------------------------------------------------*
      * INIT                          SECTION.
      *----------------------------------------------------------------*
       INIT                           SECTION.
       INIT-000.
      * --- 시스템 공통 변수 초기화 ---
           MOVE WS-PHASE-ID                 TO SYS-JOB-ID.
           MOVE FUNCTION CURRENT-DATE(1:8)  TO SYS-BIZ-DATE.
           MOVE FUNCTION CURRENT-DATE(1:14) TO WS-START-DATETIME.

      * --- 환경변수에서 DB 접속 정보 취득 ---
           ACCEPT WS-DATASRC      FROM ENVIRONMENT 'GIXSQL_DB_CONN'.
           ACCEPT WS-USER         FROM ENVIRONMENT 'GIXSQL_USER'.
           ACCEPT WS-PWD          FROM ENVIRONMENT 'GIXSQL_PWD'.

           IF WS-DATASRC = SPACES THEN
               MOVE 'GIXSQL_DB_CONN NOT SET' TO ERR-DESCRIPTION
               PERFORM SYSTEM-ERROR-000
               STOP RUN
           ELSE
               CONTINUE
           END-IF.  

      * --- 입력 파일 오픈 ---
           OPEN INPUT IN-FILE.

           IF WS-IN-STAT NOT = '00' THEN
               MOVE 'INPUT FILE OPEN ERROR' TO ERR-DESCRIPTION
               PERFORM SYSTEM-ERROR-000
               STOP RUN
           ELSE
               CONTINUE
           END-IF.

      * --- DB 접속 ---
           EXEC SQL
               CONNECT :WS-USER IDENTIFIED BY :WS-PWD
                       USING :WS-DATASRC
           END-EXEC.

           IF SQLCODE NOT = 0 THEN
               MOVE SQLCODE            TO ERR-SQLCODE
               MOVE 'DB CONNECT ERROR' TO ERR-DESCRIPTION
               PERFORM SYSTEM-ERROR-000
               STOP RUN
           ELSE
               CONTINUE
           END-IF.

      * --- 배치 이력 시작 기록 ---
           PERFORM BATCHLOG-START-000.

      * --- 스테이징 테이블 사전 클리어 (재실행 멱등성) ---
           EXEC SQL DELETE FROM TB_STG_TRX END-EXEC.
           EXEC SQL COMMIT END-EXEC.

      * --- 초기 레코드 읽기 ---
           PERFORM READ-IN-FILE-000.
       INIT-999.
           EXIT.

      *----------------------------------------------------------------*
      * DATA-PROCESS                  SECTION.
      *----------------------------------------------------------------*
       DATA-PROCESS                   SECTION.
       PROCESS-000.
      * --- INSPECT REPLACING: 소문자를 대문자로 정규화 ---
           INSPECT IN-REC
               CONVERTING 'abcdefghijklmnopqrstuvwxyz'
                       TO 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.

      * --- 레코드 타입(H/D/T) 식별을 위한 버퍼 매핑 ---
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
      * --- TB_INST_MASTER 조회: 기관코드 유효성 검증 및 수수료율 취득 ---
           MOVE INST-CD               TO INST-MAST-CD.

           EXEC SQL
               SELECT INST_CD,        INST_NAME,
                      INST_STAT,      FEE_RATE
                 INTO :INST-MAST-CD,       :INST-MAST-NAME,
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
      * --- 호스트 변수로 이관 ---
           MOVE TRX-DATE              TO STG-TRX-DATE.
           MOVE TRX-SEQ               TO STG-TRX-SEQ.
           MOVE INST-CD               TO STG-INST-CD.
           MOVE ACC-NO                TO STG-ACC-NO.
           MOVE TRX-TYPE              TO STG-TRX-TYPE.
           MOVE TRX-AMT               TO STG-TRX-AMT.

      * --- 기관별 수수료율로 수수료 산출 (COMP-3으로 부호 안정성 확보) ---
           COMPUTE WS-FEE-AMT-COMP
                       = STG-TRX-AMT * INST-MAST-FEE-RATE.
           MOVE WS-FEE-AMT-COMP       TO STG-FEE-AMT.
           MOVE WS-PROC-STAT-INIT     TO STG-PROC-STAT.

      * --- 직접 INSERT (INIT 단계에서 DELETE로 사전 클리어 완료) ---
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
       
      * --- 청크 COMMIT 및 진행 로그 출력 ---
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
           DISPLAY ' >... ' WS-INSERT-CNT ' RECORDS INSERTED...'.
       PROGRESS-LOG-999.
           EXIT.

      *----------------------------------------------------------------*
      * FINALIZE                      SECTION.
      *----------------------------------------------------------------*
       FINALIZE                       SECTION.
       FINALIZE-000.
      * --- 잔여 트랜잭션 커밋 ---
           IF WS-COMMIT-CNT > 0 THEN
               EXEC SQL COMMIT END-EXEC
           ELSE
               CONTINUE
           END-IF.

           CLOSE IN-FILE.

      * --- 배치 이력 종료 기록 ---
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
           MOVE SPACES                TO BLG-END-DT.
           MOVE 'R'                   TO BLG-STAT.
           MOVE 0                     TO BLG-PROC-CNT.
           MOVE 0                     TO BLG-ERR-CNT.
           MOVE 'PHASE2 STARTED'      TO BLG-REMARK.

           EXEC SQL
               INSERT INTO TB_BATCH_LOG
                      (PGM_ID,    BIZ_DATE,    START_DT,
                       END_DT,    STAT,        PROC_CNT,
                       ERR_CNT,   REMARK)
               VALUES (:BLG-PGM-ID,   :BLG-BIZ-DATE, :BLG-START-DT,
                       :BLG-END-DT,   :BLG-STAT,     :BLG-PROC-CNT,
                       :BLG-ERR-CNT,  :BLG-REMARK)
           END-EXEC.

           IF SQLCODE = 0 THEN
               EXEC SQL COMMIT        END-EXEC
               EXEC SQL
                   SELECT MAX(BATCH_ID)
                     INTO :BLG-BATCH-ID
                     FROM TB_BATCH_LOG
                    WHERE PGM_ID   = :BLG-PGM-ID
                      AND BIZ_DATE = :BLG-BIZ-DATE
               END-EXEC
           ELSE
               MOVE SQLCODE           TO ERR-SQLCODE
               MOVE 'BATCH_LOG START INSERT ERROR' TO ERR-DESCRIPTION
               PERFORM DB-ERROR-000
           END-IF.

       BATCHLOG-START-999.
           EXIT.

      *----------------------------------------------------------------*
      * BATCHLOG-END                  SECTION.
      *----------------------------------------------------------------*
       BATCHLOG-END                   SECTION.
       BATCHLOG-END-000.
           MOVE FUNCTION CURRENT-DATE(1:14) TO BLG-END-DT.
           MOVE WS-INSERT-CNT         TO BLG-PROC-CNT.
           MOVE WS-ERR-CNT            TO BLG-ERR-CNT.

           IF WS-ERR-CNT > 0 THEN
               MOVE 'E'               TO BLG-STAT
               MOVE 'PHASE2 COMPLETED WITH ERRORS' TO BLG-REMARK
           ELSE
               MOVE 'S'               TO BLG-STAT
               MOVE 'PHASE2 COMPLETED SUCCESSFULLY' TO BLG-REMARK
           END-IF.

           EXEC SQL
               UPDATE TB_BATCH_LOG
                  SET END_DT   = :BLG-END-DT,
                      STAT     = :BLG-STAT,
                      PROC_CNT = :BLG-PROC-CNT,
                      ERR_CNT  = :BLG-ERR-CNT,
                      REMARK   = :BLG-REMARK
                WHERE BATCH_ID = :BLG-BATCH-ID
           END-EXEC.

           IF SQLCODE NOT = 0 THEN
               MOVE SQLCODE           TO ERR-SQLCODE
               MOVE 'BATCH_LOG END UPDATE ERROR' TO ERR-DESCRIPTION
               PERFORM DB-ERROR-000
           ELSE
               CONTINUE
           END-IF.

       BATCHLOG-END-999.
           EXIT.
      *================================================================*
      * END OF PGM-PHASE2
      *================================================================*
      