      *================================================================*
      * PGM-BLOGSVR.cbl - 배치 이력 서비스 서브프로그램
      * 기능 : TB_BATCH_LOG 테이블에 배치 이력을 기록한다.
      *        호출 시 BLG-ACTION 값에 따라 START/END 처리를 분기한다.
      * 호출 : CALL 'PGM-BLOGSVR' USING BLG-PARAMS
      * 반환 : BLG-BATCH-ID (START 시 채번된 ID를 반환)
      *        BLG-RETURN-CODE (0=정상, 8=오류)
      *================================================================*
      *================================================================*
      * IDENTIFICATION                DIVISION.
      *================================================================*
       IDENTIFICATION                 DIVISION.
       PROGRAM-ID.                    PGM-BLOGSVR.
       AUTHOR.                        Hoax.
      *================================================================*
      * ENVIRONMENT                   DIVISION.
      *================================================================*
       ENVIRONMENT                    DIVISION.
      *================================================================*
      * DATA                          DIVISION.
      *================================================================*
       DATA                           DIVISION.
       WORKING-STORAGE                SECTION.
      * --- SQLCA ---
           EXEC SQL INCLUDE SQLCA      END-EXEC.

      * --- DB 접속 정보 (환경변수에서 직접 취득) ---
       01  WS-DB-CONN.
           05 WS-DATASRC              PIC X(50) VALUE SPACES.
           05 WS-USER                 PIC X(30) VALUE SPACES.
           05 WS-PWD                  PIC X(30) VALUE SPACES.

      * --- DB 접속 상태 플래그 ---
       01  WS-CONN-FLAG               PIC X(1)  VALUE 'N'.
           88 WS-CONNECTED            VALUE 'Y'.
           88 WS-NOT-CONNECTED        VALUE 'N'.

      * --- 내부 작업용 변수 ---
       01  WS-WORK-AREAS.
           05 WS-CURRENT-DT           PIC X(14) VALUE SPACES.
           05 WS-SQLCODE-DISP         PIC S9(9) VALUE 0.

      *================================================================*
      * LINKAGE                       SECTION.
      *================================================================*
       LINKAGE                        SECTION.

      * --- 호출 파라미터 블록 ---
       01  BLG-PARAMS.
      *    액션 코드: 'START' / 'END  '
           05 BLG-ACTION              PIC X(5).
              88 BLG-START            VALUE 'START'.
              88 BLG-END              VALUE 'END  '.
      *    배치 식별 정보
           05 BLG-PGM-ID              PIC X(10).
           05 BLG-BIZ-DATE            PIC X(8).
           05 BLG-START-DT            PIC X(14).
           05 BLG-END-DT              PIC X(14).
           05 BLG-STAT                PIC X(1).
           05 BLG-PROC-CNT            PIC 9(10).
           05 BLG-ERR-CNT             PIC 9(10).
           05 BLG-REMARK              PIC X(100).
      *    채번된 BATCH_ID (START 후 반환값)
           05 BLG-BATCH-ID            PIC S9(10) COMP-3.
      *    처리 결과 코드 (0=정상, 8=오류)
           05 BLG-RETURN-CODE         PIC 9(4).
      *================================================================*
      * PROCEDURE                     DIVISION.
      *================================================================*
       PROCEDURE                      DIVISION USING BLG-PARAMS.
      *----------------------------------------------------------------*
      * MAIN                          SECTION.
      *----------------------------------------------------------------*
       MAIN                           SECTION.
       MAIN-000.
           MOVE 0 TO BLG-RETURN-CODE.

           PERFORM DB-CONNECT-000.

           IF BLG-RETURN-CODE NOT = 0 THEN
               GO TO MAIN-999
           ELSE
               CONTINUE
           END-IF.

           EVALUATE TRUE
               WHEN BLG-START
                   PERFORM BATCHLOG-START-000
               WHEN BLG-END
                   PERFORM BATCHLOG-END-000
               WHEN OTHER
                   DISPLAY '> [BLOGSVR] UNKNOWN ACTION: ' BLG-ACTION
                   MOVE 8 TO BLG-RETURN-CODE
           END-EVALUATE.

           IF BLG-RETURN-CODE = 0 THEN
               EXEC SQL COMMIT            END-EXEC
           ELSE
               CONTINUE
           END-IF.

           EXEC SQL DISCONNECT CURRENT    END-EXEC.
       MAIN-999.
           EXIT PROGRAM.

      *----------------------------------------------------------------*
      * DB-CONNECT                    SECTION.
      *----------------------------------------------------------------*
       DB-CONNECT                     SECTION.
       DB-CONNECT-000.
           ACCEPT WS-DATASRC      FROM ENVIRONMENT 'GIXSQL_DB_CONN'.
           ACCEPT WS-USER         FROM ENVIRONMENT 'GIXSQL_USER'.
           ACCEPT WS-PWD          FROM ENVIRONMENT 'GIXSQL_PWD'.

           IF WS-DATASRC = SPACES THEN
               DISPLAY '> [BLOGSVR] GIXSQL_DB_CONN NOT SET, SKIP'
               MOVE 8 TO BLG-RETURN-CODE
           ELSE
               EXEC SQL
                   CONNECT :WS-USER IDENTIFIED BY :WS-PWD
                           USING :WS-DATASRC
               END-EXEC

               IF SQLCODE = 0 THEN
                   SET WS-CONNECTED TO TRUE
               ELSE
                   MOVE SQLCODE TO WS-SQLCODE-DISP
                   DISPLAY '> [BLOGSVR] DB CONNECT FAILED. SQLCODE='
                           WS-SQLCODE-DISP
                   MOVE 8 TO BLG-RETURN-CODE
               END-IF
           END-IF.
       DB-CONNECT-999.
           EXIT.

      *----------------------------------------------------------------*
      * BATCHLOG-START                SECTION.
      *----------------------------------------------------------------*
       BATCHLOG-START                 SECTION.
       BATCHLOG-START-000.
           MOVE FUNCTION CURRENT-DATE(1:14) TO BLG-START-DT.
           MOVE SPACES                TO BLG-END-DT.
           MOVE 'R'                   TO BLG-STAT.
           MOVE 0                     TO BLG-PROC-CNT.
           MOVE 0                     TO BLG-ERR-CNT.

           EXEC SQL
               INSERT INTO TB_BATCH_LOG
                      (PGM_ID,        BIZ_DATE,      START_DT,
                       END_DT,        STAT,          PROC_CNT,
                       ERR_CNT,       REMARK)
               VALUES (:BLG-PGM-ID,   :BLG-BIZ-DATE, :BLG-START-DT,
                       :BLG-END-DT,   :BLG-STAT,     :BLG-PROC-CNT,
                       :BLG-ERR-CNT,  :BLG-REMARK)
           END-EXEC.

           IF SQLCODE NOT = 0 THEN
               MOVE SQLCODE TO WS-SQLCODE-DISP
               DISPLAY '> [BLOGSVR] START INSERT ERROR. SQLCODE='
                       WS-SQLCODE-DISP
               MOVE 8 TO BLG-RETURN-CODE
           ELSE
               EXEC SQL COMMIT            END-EXEC

               EXEC SQL
                   SELECT MAX(BATCH_ID)
                     INTO :BLG-BATCH-ID
                     FROM TB_BATCH_LOG
                    WHERE PGM_ID   = :BLG-PGM-ID
                      AND BIZ_DATE = :BLG-BIZ-DATE
               END-EXEC

               IF SQLCODE NOT = 0 THEN
                   MOVE SQLCODE TO WS-SQLCODE-DISP
                   DISPLAY '> [BLOGSVR] BATCH_ID SELECT ERROR. SQLCODE='
                           WS-SQLCODE-DISP
                   MOVE 8 TO BLG-RETURN-CODE
               ELSE
                   CONTINUE
               END-IF
           END-IF.
       BATCHLOG-START-999.
           EXIT.

      *----------------------------------------------------------------*
      * BATCHLOG-END                  SECTION.
      *----------------------------------------------------------------*
       BATCHLOG-END                   SECTION.
       BATCHLOG-END-000.
           MOVE FUNCTION CURRENT-DATE(1:14) TO BLG-END-DT.

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
               MOVE SQLCODE TO WS-SQLCODE-DISP
               DISPLAY '> [BLOGSVR] END UPDATE ERROR. SQLCODE='
                       WS-SQLCODE-DISP
               MOVE 8 TO BLG-RETURN-CODE
           ELSE
               CONTINUE
           END-IF.
       BATCHLOG-END-999.
           EXIT.
      *================================================================*
      * END OF PGM-BLOGSVR
      *================================================================*
      