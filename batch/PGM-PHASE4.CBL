      *================================================================*
      * PGM-PHASE4.cbl - DB to File
      * 1. 공통 COPYBOOK (SYS-COM, ERR-LOG) 적용
      * 2. 환경변수(GIXSQL_DB_CONN/USER/PWD)에서 DB 접속 정보 취득
      * 3. TB_NET_SUMMARY CURSOR 로 정산 집계를 순차 FETCH
      * 4. FILE-CTRL (REDEFINES) 활용한 Header/Trailer 동적 생성
      * 5. 서식형변수(Edited Data Item)로 금액/날짜 편집 출력
      * 6. TB_NET_SUMMARY.INST_NAME 을 FETCH 하여 기관명으로 출력
      * 7. BATCHLOG (TB_BATCH_LOG) 시작/종료 이력 기록
      *================================================================*
      *================================================================*
      * IDENTIFICATION                DIVISION.
      *================================================================*
       IDENTIFICATION                 DIVISION.
       PROGRAM-ID.                    PGM-PHASE4.
       AUTHOR.                        Hoax.
      *================================================================*
      * ENVIRONMENT                   DIVISION.
      *================================================================*
       ENVIRONMENT                    DIVISION.
       INPUT-OUTPUT                   SECTION.
       FILE-CONTROL.
           SELECT OUT-FILE ASSIGN TO 'OUTFILE_VAR'
                  ORGANIZATION IS LINE SEQUENTIAL
                  FILE STATUS IS WS-OUT-STAT.
      *================================================================*
      * DATA                          DIVISION.
      *================================================================*
       DATA                           DIVISION.
       FILE                           SECTION.
       FD  OUT-FILE.
       01  OUT-REC                    PIC X(71).

      * --- 출력 파일 데이터 레이아웃 (71 Bytes) ---
      *     SETTLE-DATE(8) + INST-NAME(20) + TOT-IN(15)
      *     + TOT-OUT(15) + NET-AMT(13) = 71
       01  DATA-REC REDEFINES OUT-REC.
           05 OUT-SETTLE-DATE         PIC X(8).
           05 OUT-INST-NAME           PIC X(13).
           05 OUT-TOT-IN              PIC 9(15).
           05 OUT-TOT-OUT             PIC 9(15).
           05 OUT-NET-AMT             PIC -9(12).

       WORKING-STORAGE                SECTION.
      * --- 시스템 공통 영역 및 에러 로그 Include ---
           COPY SYS-COM.
           COPY ERR-LOG.
           COPY FILE-CTRL.

      * --- SQLCA 및 DB DCLGEN Include ---
           EXEC SQL INCLUDE SQLCA      END-EXEC.
           EXEC SQL INCLUDE SQL-DCLGEN END-EXEC.

      * --- DB 접속 정보 (환경변수로 취득) ---
       01  WS-DB-CONN.
           05 WS-DATASRC              PIC X(50) VALUE SPACES.
           05 WS-USER                 PIC X(30) VALUE SPACES.
           05 WS-PWD                  PIC X(30) VALUE SPACES.

      * --- 파일 상태 ---
       01  WS-OUT-STAT                PIC X(2).

      * --- 제어 플래그 ---
       01  WS-FLAGS.
           05 WS-EOF-FLAG             PIC X(1) VALUE 'N'.
              88 WS-EOF               VALUE 'Y'.
              88 WS-NOT-EOF           VALUE 'N'.

      * --- 처리 건수 집계 ---
       01  WS-COUNTERS.
           05 WS-CALC-CNT             PIC 9(10) VALUE 0.
           05 WS-ERR-CNT              PIC 9(10) VALUE 0.

      * --- 대사 합계 ---
       01  WS-CALC-TOTALS.
           05 WS-CALC-AMT             PIC S9(15) COMP-3 VALUE 0.
           05 WS-CALC-IN              PIC S9(15) COMP-3 VALUE 0.
           05 WS-CALC-OUT             PIC S9(15) COMP-3 VALUE 0.

      * --- 작업 영역 ---
       01  WS-WORK-AREAS.
           05 WS-NET-WORK             PIC S9(15) COMP-3 VALUE 0.
           05 WS-MOD-WORK             PIC 9(10)  COMP   VALUE 0.

      * --- 배치 시작일시 ---
       01  WS-START-DATETIME          PIC X(14) VALUE SPACES.

      * --- 비즈니스 날짜 (커서 WHERE 조건용) ---
       01  WS-BIZ-DATE-W              PIC X(8).

      * --- 서식형변수 (Edited Data Item) ---
       01  WS-EDIT-AREA.
           05 ED-TOT-IN               PIC -Z,ZZZ,ZZZ,ZZ9.
           05 ED-TOT-OUT              PIC -Z,ZZZ,ZZZ,ZZ9.
           05 ED-NET-AMT              PIC -Z,ZZZ,ZZZ,ZZ9.
           05 ED-SETTLE-DATE          PIC 9999/99/99.
           05 ED-CALC-AMT             PIC -$,$$$,$$$,$$$,$$9.

      * --- 77 레벨: 독립 단일 항목 ---
       77  WS-PROG-NAME               PIC X(10) VALUE 'PGM-PHASE4'.
       77  WS-PHASE-ID                PIC X(8)  VALUE 'PHASE4'.

      * --- 78 레벨: 상수 정의 ---
       78  WS-PROGRESS-INTERVAL       VALUE 10.

      * --- SQL CURSOR 선언 ---
           EXEC SQL
               DECLARE C-NET-SUMMARY CURSOR FOR
               SELECT SETTLE_DATE, INST_CD,
                      INST_NAME,
                      TOT_IN_AMT, TOT_OUT_AMT, NET_AMT
                 FROM TB_NET_SUMMARY
                WHERE SETTLE_DATE = :WS-BIZ-DATE-W
                ORDER BY INST_CD ASC
           END-EXEC.

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
           MOVE WS-PHASE-ID                  TO SYS-JOB-ID.
           MOVE FUNCTION CURRENT-DATE(1:8)   TO SYS-BIZ-DATE.
           MOVE FUNCTION CURRENT-DATE(1:14)  TO WS-START-DATETIME.
           MOVE SYS-BIZ-DATE                 TO WS-BIZ-DATE-W.

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

      * --- 출력 파일 오픈 ---
           OPEN OUTPUT OUT-FILE.

           IF WS-OUT-STAT NOT = '00' THEN
               MOVE 'OUTPUT FILE OPEN ERROR' TO ERR-DESCRIPTION
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

      * --- CURSOR OPEN ---
           EXEC SQL OPEN C-NET-SUMMARY END-EXEC.

           IF SQLCODE NOT = 0 THEN
               MOVE SQLCODE               TO ERR-SQLCODE
               MOVE 'CURSOR OPEN ERROR'   TO ERR-DESCRIPTION
               PERFORM SYSTEM-ERROR-000
               STOP RUN
           ELSE
               CONTINUE
           END-IF.

      * --- Header レコード出力 ---
           PERFORM WRITE-HEADER-000.

       INIT-999.
           EXIT.

      *----------------------------------------------------------------*
      * DATA-PROCESS                  SECTION.
      *----------------------------------------------------------------*
       DATA-PROCESS                   SECTION.
       PROCESS-000.
           EXEC SQL
               FETCH C-NET-SUMMARY
                INTO :SUM-SETTLE-DATE, :SUM-INST-CD,
                     :SUM-INST-NAME,
                     :SUM-TOT-IN,      :SUM-TOT-OUT,
                     :SUM-NET-AMT
           END-EXEC.

           EVALUATE SQLCODE
               WHEN 0
                   PERFORM WRITE-DATA-000
               WHEN 100
                   SET WS-EOF             TO TRUE
               WHEN OTHER
                   MOVE SQLCODE           TO ERR-SQLCODE
                   MOVE 'CURSOR FETCH ERROR' TO ERR-DESCRIPTION
                   PERFORM SYSTEM-ERROR-000
                   STOP RUN
           END-EVALUATE.
       PROCESS-999.
           EXIT.

      *----------------------------------------------------------------*
      * WRITE-HEADER                  SECTION.
      *----------------------------------------------------------------*
       WRITE-HEADER                   SECTION.
       WRITE-HEADER-000.
      * --- FILE-CTRL (REDEFINES) 를 활용한 Header 동적 생성 ---
           MOVE 'H'                   TO REC-TYPE.
           MOVE SYS-BIZ-DATE          TO HDR-CREATE-DATE.
           MOVE FILE-CONTROL-REC      TO OUT-REC.
           WRITE OUT-REC.
       WRITE-HEADER-999.
           EXIT.

      *----------------------------------------------------------------*
      * WRITE-DATA                    SECTION.
      *----------------------------------------------------------------*
       WRITE-DATA                     SECTION.
       WRITE-DATA-000.
      * --- 기관명 MOVE 후 INSPECT CONVERTING 으로 대문자 정규화 ---
           MOVE SUM-INST-NAME         TO OUT-INST-NAME.
           INSPECT OUT-INST-NAME
               CONVERTING 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
                        TO 'abcdefghijklmnopqrstuvwxyz'.

      * --- 파일 출력: 수치형 그대로 OUT-REC(REDEFINES)에 MOVE ---
           MOVE SUM-SETTLE-DATE       TO OUT-SETTLE-DATE.
           MOVE SUM-TOT-IN            TO OUT-TOT-IN.
           MOVE SUM-TOT-OUT           TO OUT-TOT-OUT.
           MOVE SUM-NET-AMT           TO OUT-NET-AMT.
           WRITE OUT-REC.

      * --- DISPLAY 출력: 서식형변수로 편집된 값 표시 ---
           MOVE SUM-SETTLE-DATE       TO ED-SETTLE-DATE.
           MOVE SUM-TOT-IN            TO ED-TOT-IN.
           MOVE SUM-TOT-OUT           TO ED-TOT-OUT.
           MOVE SUM-NET-AMT           TO ED-NET-AMT.
           DISPLAY ' > [DATA]'
                   ' DATE='   ED-SETTLE-DATE
                   ' NAME='   OUT-INST-NAME
                   ' IN='     ED-TOT-IN
                   ' OUT='    ED-TOT-OUT
                   ' NET='    ED-NET-AMT.

      * --- 대사용 건수·금액 누적 ---
           ADD 1                      TO WS-CALC-CNT.
           ADD SUM-TOT-IN             TO WS-CALC-IN.
           ADD SUM-TOT-OUT            TO WS-CALC-OUT.
           ADD SUM-NET-AMT            TO WS-CALC-AMT.

      * --- 진행 로그 (WS-PROGRESS-INTERVAL 건마다) ---
           COMPUTE WS-MOD-WORK = FUNCTION MOD(WS-CALC-CNT,
                                              WS-PROGRESS-INTERVAL).
           IF WS-MOD-WORK = 0 THEN
               PERFORM PROGRESS-LOG-000
           ELSE
               CONTINUE
           END-IF.
       WRITE-DATA-999.
           EXIT.

      *----------------------------------------------------------------*
      * FINALIZE                      SECTION.
      *----------------------------------------------------------------*
       FINALIZE                       SECTION.
       FINALIZE-000.
      * --- CURSOR CLOSE ---
           EXEC SQL CLOSE C-NET-SUMMARY END-EXEC.

      * --- Trailer レコード出力 ---
           PERFORM WRITE-TRAILER-000.

      * --- 출력 파일 CLOSE ---
           CLOSE OUT-FILE.

      * --- 배치 이력 종료 기록 ---
           PERFORM BATCHLOG-END-000.
           EXEC SQL COMMIT            END-EXEC.

      * --- DB 접속 해제 ---
           EXEC SQL DISCONNECT CURRENT END-EXEC.

      * --- 최종 결과 DISPLAY ---
           MOVE WS-CALC-AMT           TO ED-CALC-AMT.
           DISPLAY ' > ========= PGM-PHASE4 RESULT ========='.
           DISPLAY ' > DATA WRITTEN : '  WS-CALC-CNT.
           DISPLAY ' > TOTAL IN AMT : '  WS-CALC-IN.
           DISPLAY ' > TOTAL OUT AMT: '  WS-CALC-OUT.
           DISPLAY ' > TOTAL NET AMT: '  ED-CALC-AMT.
           DISPLAY ' > DB ERRORS    : '  WS-ERR-CNT.
           DISPLAY ' > ====================================='.
       FINALIZE-999.
           EXIT.

      *----------------------------------------------------------------*
      * WRITE-TRAILER                 SECTION.
      *----------------------------------------------------------------*
       WRITE-TRAILER                  SECTION.
       WRITE-TRAILER-000.
      * --- FILE-CTRL (REDEFINES) 를 활용한 Trailer 동적 생성 ---
           MOVE 'T'                   TO REC-TYPE.
           MOVE WS-CALC-CNT           TO TRL-TOT-CNT.
           MOVE WS-CALC-AMT           TO TRL-TOT-AMT.
           MOVE FILE-CONTROL-REC      TO OUT-REC.
           WRITE OUT-REC.
       WRITE-TRAILER-999.
           EXIT.

      *----------------------------------------------------------------*
      * PROGRESS-LOG                  SECTION.
      *----------------------------------------------------------------*
       PROGRESS-LOG                   SECTION.
       PROGRESS-LOG-000.
           DISPLAY ' > ... ' WS-CALC-CNT ' RECORDS WRITTEN... <'.
       PROGRESS-LOG-999.
           EXIT.

      *----------------------------------------------------------------*
      * BATCHLOG-START                SECTION.
      *----------------------------------------------------------------*
      * TB_BATCH_LOG : 배치 시작 이력 INSERT (STAT='R')
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
           MOVE 'PHASE4 STARTED'      TO BLG-REMARK.

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
      * TB_BATCH_LOG : 배치 종료 이력 UPDATE (STAT='S'/'E')
      *----------------------------------------------------------------*
       BATCHLOG-END                   SECTION.
       BATCHLOG-END-000.
           MOVE FUNCTION CURRENT-DATE(1:14) TO BLG-END-DT.
           MOVE WS-CALC-CNT           TO BLG-PROC-CNT.
           MOVE WS-ERR-CNT            TO BLG-ERR-CNT.

           IF WS-ERR-CNT > 0 THEN
               MOVE 'E'               TO BLG-STAT
               MOVE 'PHASE4 COMPLETED WITH ERRORS' TO BLG-REMARK
           ELSE
               MOVE 'S'               TO BLG-STAT
               MOVE 'PHASE4 COMPLETED SUCCESSFULLY' TO BLG-REMARK
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

      *----------------------------------------------------------------*
      * SYSTEM-ERROR                  SECTION.
      *----------------------------------------------------------------*
       SYSTEM-ERROR                   SECTION.
       SYSTEM-ERROR-000.
           MOVE WS-PROG-NAME          TO ERR-PGM-ID.
           SET ERR-FATAL              TO TRUE.
           SET BATCH-ERROR            TO TRUE.
           DISPLAY '*** SYSTEM FATAL ERROR ***'.
           DISPLAY 'PGM: '      ERR-PGM-ID
                   ' SQLCODE: ' ERR-SQLCODE.
           DISPLAY 'MSG: '      ERR-DESCRIPTION.
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
           ADD 1                      TO WS-ERR-CNT.
           DISPLAY '*** DB ERROR ***'.
           DISPLAY 'PGM: '      ERR-PGM-ID
                   ' SQLCODE: ' ERR-SQLCODE.
           DISPLAY 'MSG: '      ERR-DESCRIPTION.
       DB-ERROR-999.
           EXIT.
      *================================================================*
      * END OF PGM-PHASE4
      *================================================================*
      