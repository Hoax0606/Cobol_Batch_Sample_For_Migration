      *================================================================*
      * PGM-PHASE3.cbl - DB to DB
      * 1. 공통 COPYBOOK (SYS-COM, ERR-LOG) 적용
      * 2. OOM Test Point: 대량의 Cursor 데이터를 인메모리 배열에 적재 및 집계
      * 3. DB Error Handling 및 Chunk Commit 제어
      *================================================================*
      * IDENTIFICATION                DIVISION.
      *================================================================*
       IDENTIFICATION                 DIVISION.
       PROGRAM-ID.                    PGM-PHASE3.
       AUTHOR.                        Hoax.
      *================================================================*
      * ENVIRONMENT                   DIVISION.
      *================================================================*
       ENVIRONMENT                    DIVISION.
       CONFIGURATION                  SECTION.
      *================================================================*
      * DATA                          DIVISION.
      *================================================================*
       DATA                           DIVISION.
       WORKING-STORAGE                SECTION.
      *EXEC SQL BEGIN DECLARE SECTION END-EXEC.
      *> SQLite 데이터베이스 식별자 또는 연결 문자열
       01 DB-NAME           PIC X(22) VALUE "SB_VaF_Education_JP.db".
       01 WS-USER           PIC X(6)  VALUE 'gixsql'.
       01 WS-PWD            PIC X(6)  VALUE 'gixsql'.

      * --- 시스템 공통 영역 및 에러 로그 Include ---
           COPY SYS-COM.
           COPY ERR-LOG.

      * --- SQLCA 및 COPYBOOK Include ---
GIXSQL*    EXEC SQL INCLUDE SQLCA END-EXEC.
           COPY SQLCA.
GIXSQL*    EXEC SQL INCLUDE SQL-DCLGEN END-EXEC.
           COPY SQL-DCLGEN.

      * --- 프로그램 제어 변수 ---
       01  WS-VARIABLES.
           05 WS-EOF-FLAG         PIC X(1) VALUE 'N'.
           05 WS-COMMIT-INTERVAL  PIC 9(5) VALUE 10000.
           05 WS-COMMIT-CNT       PIC 9(5) VALUE 0.
           05 WS-TOTAL-READ       PIC 9(10) VALUE 0.

      * --- OOM 테스트를 위한 인메모리 집계 테이블 (배열) ---
       01  NETTING-TABLE.
           05 NET-ENTRY OCCURS 1000 TIMES INDEXED BY NET-IDX.
              10 NET-INST-CD      PIC X(4).
              10 NET-TOT-IN       PIC 9(15) VALUE 0.
              10 NET-TOT-OUT      PIC 9(15) VALUE 0.
              10 NET-CNT          PIC 9(10) VALUE 0.
       01  WS-NET-MAX-IDX         PIC 9(4) VALUE 0.
       01  WS-FOUND-FLAG          PIC X(1) VALUE 'N'.

      * --- SQL CURSOR 선언 ---
GIXSQL*    EXEC SQL
GIXSQL*        DECLARE C-STG-TRX CURSOR FOR
GIXSQL*        SELECT TRX_DATE, TRX_SEQ, INST_CD, TRX_TYPE, TRX_AMT
GIXSQL*          FROM TB_STG_TRX
GIXSQL*         WHERE PROC_STAT = '0'
GIXSQL*         ORDER BY INST_CD ASC
GIXSQL*    END-EXEC.
      *EXEC SQL END DECLARE SECTION END-EXEC.
      *=================================================================
      * PROCEDURE                     DIVISION.
GIXSQL*=================================================================
GIXSQL 01  SQ0001.
GIXSQL     02  FILLER PIC X(0115) VALUE "SELECT TRX_DATE , TRX_SEQ , I"
GIXSQL  &  "NST_CD , TRX_TYPE , TRX_AMT FROM TB_STG_TRX WHERE PROC_STAT"
GIXSQL  &  " = '0' ORDER BY INST_CD ASC".
GIXSQL     02  FILLER PIC X(1) VALUE X"00".
GIXSQL 01  SQ0002.
GIXSQL     02  FILLER PIC X(0026) VALUE "DELETE FROM TB_NET_SUMMARY".
GIXSQL     02  FILLER PIC X(1) VALUE X"00".
GIXSQL 01  SQ0003.
GIXSQL     02  FILLER PIC X(0138) VALUE "INSERT INTO TB_NET_SUMMARY (S"
GIXSQL  &  "ETTLE_DATE , INST_CD , TOT_IN_AMT , TOT_OUT_AMT , NET_AMT ,"
GIXSQL  &  " TOTAL_CNT) VALUES ( $1 , $2 , $3 , $4 , $5 , $6 )".
GIXSQL     02  FILLER PIC X(1) VALUE X"00".
GIXSQL*   ESQL CURSOR INIT FLAGS (START)
GIXSQL 01  GIXSQL-CI-F-PGM-PHASE3-C-STG-TRX PIC X.
GIXSQL*   ESQL CURSOR INIT FLAGS (END)
       PROCEDURE                      DIVISION.
      *----------------------------------------------------------------*
      * MAIN                          SECTION.
      *----------------------------------------------------------------*
       MAIN                           SECTION.
       MAIN-000.
           PERFORM INIT-000.
           PERFORM PROCESS-000 UNTIL WS-EOF-FLAG = 'Y'.
           PERFORM FINALIZE-000.
       MAIN-999.
           STOP RUN.
      *----------------------------------------------------------------*
      * INIT                          SECTION.
      *----------------------------------------------------------------*
       INIT                           SECTION.
       INIT-000.
      * 시스템 공통 변수 초기화
           MOVE 'PHASE3'         TO SYS-JOB-ID.
      *    MOVE '20260306'       TO SYS-BIZ-DATE.
      *> 시스템 날짜
           MOVE FUNCTION CURRENT-DATE(1:8) TO SYS-BIZ-DATE.
      *    DISPLAY "date : "SYS-BIZ-DATE.
           INITIALIZE NETTING-TABLE.
      * SQLite 연결
      *    DISPLAY "--- DB CONNECTION START ---".
GIXSQL*    EXEC SQL 
GIXSQL*        CONNECT :WS-USER IDENTIFIED BY :WS-PWD USING :DB-NAME
GIXSQL*    END-EXEC.
GIXSQL     CALL "GIXSQLConnect" USING
GIXSQL         BY REFERENCE SQLCA
GIXSQL         BY REFERENCE DB-NAME
GIXSQL         BY VALUE 22
GIXSQL         BY REFERENCE x"00"
GIXSQL         BY VALUE 0
GIXSQL         BY REFERENCE x"00"
GIXSQL         BY VALUE 0
GIXSQL         BY REFERENCE WS-USER
GIXSQL         BY VALUE 6
GIXSQL         BY REFERENCE WS-PWD
GIXSQL         BY VALUE 6
GIXSQL     END-CALL.

           IF SQLCODE NOT = 0
               MOVE SQLCODE TO ERR-SQLCODE
               MOVE 'DB CONNECT ERROR' TO ERR-DESCRIPTION
               PERFORM SYSTEM-ERROR-000
           END-IF.

GIXSQL*    EXEC SQL OPEN C-STG-TRX END-EXEC.
GIXSQL     IF GIXSQL-CI-F-PGM-PHASE3-C-STG-TRX = ' ' THEN
GIXSQL         PERFORM GIXSQL-CI-P-PGM-PHASE3-C-STG-TRX
GIXSQL         IF SQLCODE = 0
GIXSQL           MOVE 'X' TO GIXSQL-CI-F-PGM-PHASE3-C-STG-TRX
GIXSQL         END-IF
GIXSQL     END-IF
GIXSQL     IF GIXSQL-CI-F-PGM-PHASE3-C-STG-TRX = 'X' THEN
GIXSQL         CALL "GIXSQLCursorOpen" USING
GIXSQL             BY REFERENCE SQLCA
GIXSQL             BY REFERENCE "PGM_PHASE3_C-STG-TRX" & x"00"
GIXSQL         END-CALL
GIXSQL     END-IF.
           IF SQLCODE NOT = 0
               MOVE SQLCODE TO ERR-SQLCODE
               MOVE 'CURSOR OPEN ERROR' TO ERR-DESCRIPTION
               PERFORM SYSTEM-ERROR-000
           END-IF.
       INIT-999.
           EXIT.
      *----------------------------------------------------------------*
      * DATA-PROCESS                  SECTION.
      *----------------------------------------------------------------*
       DATA-PROCESS                   SECTION.
       PROCESS-000.
GIXSQL*    EXEC SQL
GIXSQL*        FETCH C-STG-TRX
GIXSQL*         INTO :STG-TRX-DATE, :STG-TRX-SEQ, :STG-INST-CD,
GIXSQL*              :STG-TRX-TYPE, :STG-TRX-AMT
GIXSQL*    END-EXEC.
GIXSQL     CALL "GIXSQLStartSQL"
GIXSQL     END-CALL
GIXSQL     CALL "GIXSQLSetResultParams" USING
GIXSQL         BY VALUE 16
GIXSQL         BY VALUE 8
GIXSQL         BY VALUE 0
GIXSQL         BY VALUE 0
GIXSQL         BY REFERENCE STG-TRX-DATE
GIXSQL         BY REFERENCE 0
GIXSQL     END-CALL
GIXSQL     CALL "GIXSQLSetResultParams" USING
GIXSQL         BY VALUE 9
GIXSQL         BY VALUE 10
GIXSQL         BY VALUE 0
GIXSQL         BY VALUE 0
GIXSQL         BY REFERENCE STG-TRX-SEQ
GIXSQL         BY REFERENCE 0
GIXSQL     END-CALL
GIXSQL     CALL "GIXSQLSetResultParams" USING
GIXSQL         BY VALUE 16
GIXSQL         BY VALUE 4
GIXSQL         BY VALUE 0
GIXSQL         BY VALUE 0
GIXSQL         BY REFERENCE STG-INST-CD
GIXSQL         BY REFERENCE 0
GIXSQL     END-CALL
GIXSQL     CALL "GIXSQLSetResultParams" USING
GIXSQL         BY VALUE 16
GIXSQL         BY VALUE 1
GIXSQL         BY VALUE 0
GIXSQL         BY VALUE 0
GIXSQL         BY REFERENCE STG-TRX-TYPE
GIXSQL         BY REFERENCE 0
GIXSQL     END-CALL
GIXSQL     CALL "GIXSQLSetResultParams" USING
GIXSQL         BY VALUE 9
GIXSQL         BY VALUE 12
GIXSQL         BY VALUE 0
GIXSQL         BY VALUE 0
GIXSQL         BY REFERENCE STG-TRX-AMT
GIXSQL         BY REFERENCE 0
GIXSQL     END-CALL
GIXSQL     CALL "GIXSQLCursorFetchOne" USING
GIXSQL         BY REFERENCE SQLCA
GIXSQL         BY REFERENCE "PGM_PHASE3_C-STG-TRX" & x"00"
GIXSQL     END-CALL
GIXSQL     CALL "GIXSQLEndSQL"
GIXSQL     END-CALL.

           EVALUATE SQLCODE
               WHEN 0
                   ADD 1 TO WS-TOTAL-READ
                   PERFORM AGGREGATE-MEMORY-000
               WHEN 100
                   MOVE 'Y' TO WS-EOF-FLAG
               WHEN OTHER
                   MOVE SQLCODE TO ERR-SQLCODE
                   MOVE 'CURSOR FETCH ERROR' TO ERR-DESCRIPTION
                   PERFORM DB-ERROR-000
                   MOVE 'Y' TO WS-EOF-FLAG
           END-EVALUATE.
           PROCESS-999.
           EXIT.
      *----------------------------------------------------------------*
      * AGGREGATE-MEMORY              SECTION.
      *----------------------------------------------------------------*
       AGGREGATE-MEMORY               SECTION.
       AGGREGATE-MEMORY-000.
           MOVE 'N' TO WS-FOUND-FLAG.
           PERFORM VARYING NET-IDX FROM 1 BY 1 
                     UNTIL NET-IDX > WS-NET-MAX-IDX 
                           OR WS-FOUND-FLAG = 'Y'
               IF NET-INST-CD(NET-IDX) = STG-INST-CD
                   MOVE 'Y' TO WS-FOUND-FLAG
                   IF STG-TRX-TYPE = 'I'
                       ADD STG-TRX-AMT TO NET-TOT-IN(NET-IDX)
                   ELSE
                       ADD STG-TRX-AMT TO NET-TOT-OUT(NET-IDX)
                   END-IF
                   ADD 1 TO NET-CNT(NET-IDX)
               END-IF
           END-PERFORM.

           IF WS-FOUND-FLAG = 'N'
               ADD 1 TO WS-NET-MAX-IDX
               MOVE STG-INST-CD TO NET-INST-CD(WS-NET-MAX-IDX)
               IF STG-TRX-TYPE = 'I'
                   ADD STG-TRX-AMT TO NET-TOT-IN(WS-NET-MAX-IDX)
               ELSE
                   ADD STG-TRX-AMT TO NET-TOT-OUT(WS-NET-MAX-IDX)
               END-IF
               ADD 1 TO NET-CNT(WS-NET-MAX-IDX)
           END-IF.
       AGGREGATE-MEMORY-999.
           EXIT.
      *----------------------------------------------------------------*
      * FINALIZE                      SECTION.
      *----------------------------------------------------------------*
       FINALIZE                      SECTION.
       FINALIZE-000.
      *> 기존 데이터 삭제 (중복 방지용)
GIXSQL*    EXEC SQL DELETE FROM TB_NET_SUMMARY END-EXEC.
GIXSQL     CALL "GIXSQLStartSQL"
GIXSQL     END-CALL
GIXSQL     CALL "GIXSQLExec" USING
GIXSQL         BY REFERENCE SQLCA
GIXSQL         BY REFERENCE x"00"
GIXSQL         BY VALUE 0
GIXSQL         BY REFERENCE SQ0002
GIXSQL     END-CALL
GIXSQL     CALL "GIXSQLEndSQL"
GIXSQL     END-CALL.
      *    EXEC SQL
      *        DELETE FROM TB_NET_SUMMARY
      *        WHERE SETTLE_DATE = '20260306'
      *    END-EXEC.
      *> 삭제 직후 COMMIT
GIXSQL*    EXEC SQL COMMIT WORK END-EXEC.
GIXSQL     CALL "GIXSQLStartSQL"
GIXSQL     END-CALL
GIXSQL     CALL "GIXSQLExec" USING
GIXSQL         BY REFERENCE SQLCA
GIXSQL         BY REFERENCE x"00"
GIXSQL         BY VALUE 0
GIXSQL         BY REFERENCE "COMMIT" & x"00"
GIXSQL     END-CALL
GIXSQL     CALL "GIXSQLEndSQL"
GIXSQL     END-CALL.
GIXSQL*    EXEC SQL CLOSE C-STG-TRX END-EXEC.
GIXSQL     CALL "GIXSQLCursorClose" USING
GIXSQL         BY REFERENCE SQLCA
GIXSQL         BY REFERENCE "PGM_PHASE3_C-STG-TRX" & x"00"
GIXSQL     END-CALL.
           
           PERFORM INSERT-SUMMARY-000 VARYING NET-IDX FROM 1 BY 1
                     UNTIL NET-IDX > WS-NET-MAX-IDX.

GIXSQL*    EXEC SQL COMMIT END-EXEC.
GIXSQL     CALL "GIXSQLStartSQL"
GIXSQL     END-CALL
GIXSQL     CALL "GIXSQLExec" USING
GIXSQL         BY REFERENCE SQLCA
GIXSQL         BY REFERENCE x"00"
GIXSQL         BY VALUE 0
GIXSQL         BY REFERENCE "COMMIT" & x"00"
GIXSQL     END-CALL
GIXSQL     CALL "GIXSQLEndSQL"
GIXSQL     END-CALL.
           DISPLAY ' > ========= PGM-PHASE3 RESULT ========='.
      *    DISPLAY ' > [PHASE 3] DB TO DB NETTING COMPLETED'.
           DISPLAY ' > TOTAL READ : ' WS-TOTAL-READ.
           DISPLAY ' > INST COUNT : ' WS-NET-MAX-IDX.
           DISPLAY ' > ====================================='.
GIXSQL*    EXEC SQL DISCONNECT CURRENT END-EXEC.
GIXSQL     CALL "GIXSQLConnectReset" USING
GIXSQL         BY REFERENCE SQLCA
GIXSQL         BY REFERENCE "CURRENT" & x"00"
GIXSQL         BY VALUE 0
GIXSQL     END-CALL.
       FINALIZE-999.
           EXIT.
      *----------------------------------------------------------------*
      * INSERT-SUMMARY                SECTION.
      *----------------------------------------------------------------*     
       INSERT-SUMMARY                SECTION.
       INSERT-SUMMARY-000.
           MOVE SYS-BIZ-DATE             TO SUM-SETTLE-DATE.
           MOVE NET-INST-CD(NET-IDX)     TO SUM-INST-CD.
           MOVE NET-TOT-IN(NET-IDX)      TO SUM-TOT-IN.
           MOVE NET-TOT-OUT(NET-IDX)     TO SUM-TOT-OUT.
           COMPUTE SUM-NET-AMT = NET-TOT-IN(NET-IDX) 
                               - NET-TOT-OUT(NET-IDX).
           MOVE NET-CNT(NET-IDX)         TO SUM-TOT-CNT.

GIXSQL*    EXEC SQL
GIXSQL*        INSERT INTO TB_NET_SUMMARY
GIXSQL*               (SETTLE_DATE, INST_CD, TOT_IN_AMT, 
GIXSQL*                TOT_OUT_AMT, NET_AMT, TOTAL_CNT)
GIXSQL*        VALUES (:SUM-SETTLE-DATE, :SUM-INST-CD, :SUM-TOT-IN, 
GIXSQL*                :SUM-TOT-OUT, :SUM-NET-AMT, :SUM-TOT-CNT)
GIXSQL*    END-EXEC.
GIXSQL     CALL "GIXSQLStartSQL"
GIXSQL     END-CALL
GIXSQL     CALL "GIXSQLSetSQLParams" USING
GIXSQL         BY VALUE 16
GIXSQL         BY VALUE 8
GIXSQL         BY VALUE 0
GIXSQL         BY VALUE 0
GIXSQL         BY REFERENCE SUM-SETTLE-DATE
GIXSQL         BY REFERENCE 0
GIXSQL     END-CALL
GIXSQL     CALL "GIXSQLSetSQLParams" USING
GIXSQL         BY VALUE 16
GIXSQL         BY VALUE 4
GIXSQL         BY VALUE 0
GIXSQL         BY VALUE 0
GIXSQL         BY REFERENCE SUM-INST-CD
GIXSQL         BY REFERENCE 0
GIXSQL     END-CALL
GIXSQL     CALL "GIXSQLSetSQLParams" USING
GIXSQL         BY VALUE 9
GIXSQL         BY VALUE 15
GIXSQL         BY VALUE 0
GIXSQL         BY VALUE 0
GIXSQL         BY REFERENCE SUM-TOT-IN
GIXSQL         BY REFERENCE 0
GIXSQL     END-CALL
GIXSQL     CALL "GIXSQLSetSQLParams" USING
GIXSQL         BY VALUE 9
GIXSQL         BY VALUE 15
GIXSQL         BY VALUE 0
GIXSQL         BY VALUE 0
GIXSQL         BY REFERENCE SUM-TOT-OUT
GIXSQL         BY REFERENCE 0
GIXSQL     END-CALL
GIXSQL     CALL "GIXSQLSetSQLParams" USING
GIXSQL         BY VALUE 9
GIXSQL         BY VALUE 15
GIXSQL         BY VALUE 0
GIXSQL         BY VALUE 0
GIXSQL         BY REFERENCE SUM-NET-AMT
GIXSQL         BY REFERENCE 0
GIXSQL     END-CALL
GIXSQL     CALL "GIXSQLSetSQLParams" USING
GIXSQL         BY VALUE 9
GIXSQL         BY VALUE 10
GIXSQL         BY VALUE 0
GIXSQL         BY VALUE 0
GIXSQL         BY REFERENCE SUM-TOT-CNT
GIXSQL         BY REFERENCE 0
GIXSQL     END-CALL
GIXSQL     CALL "GIXSQLExecParams" USING
GIXSQL         BY REFERENCE SQLCA
GIXSQL         BY REFERENCE x"00"
GIXSQL         BY VALUE 0
GIXSQL         BY REFERENCE SQ0003
GIXSQL         BY VALUE 6
GIXSQL     END-CALL
GIXSQL     CALL "GIXSQLEndSQL"
GIXSQL     END-CALL.
           
           IF SQLCODE NOT = 0
               MOVE SQLCODE TO ERR-SQLCODE
               MOVE 'INSERT SUMMARY ERROR' TO ERR-DESCRIPTION
               PERFORM DB-ERROR-000
           END-IF.
       INSERT-SUMMARY-999.
           EXIT.
      *----------------------------------------------------------------*
      * SYSTEM-ERROR                  SECTION.
      *----------------------------------------------------------------*
       SYSTEM-ERROR                   SECTION.
       SYSTEM-ERROR-000.
           MOVE 'PGM-PHASE3' TO ERR-PGM-ID.
           SET ERR-FATAL TO TRUE.
           DISPLAY '*** SYSTEM FATAL ERROR *** MSG: ' ERR-DESCRIPTION.
       SYSTEM-ERROR-999.
           EXIT.
      *----------------------------------------------------------------*
      * DB-ERROR                      SECTION.
      *----------------------------------------------------------------*
       DB-ERROR                       SECTION.
       DB-ERROR-000.
       
           MOVE 'PGM-PHASE3' TO ERR-PGM-ID.
           SET BATCH-ERROR TO TRUE.
           DISPLAY '*** DB ERROR *** SQLCODE: ' ERR-SQLCODE 
                   ' MSG: ' ERR-DESCRIPTION.
       DB-ERROR-999.
           EXIT.
      *================================================================*
      * END OF PGM-PHASE3
      *================================================================*
GIXSQL*
GIXSQL*   ESQL CURSOR DECLARATIONS (START)
GIXSQL     GO TO GIX-SKIP-CRSR-INIT.
GIXSQL GIXSQL-CI-P-PGM-PHASE3-C-STG-TRX.
GIXSQL     CALL "GIXSQLCursorDeclare" USING
GIXSQL         BY REFERENCE SQLCA
GIXSQL         BY REFERENCE x"00"
GIXSQL         BY VALUE 0
GIXSQL         BY REFERENCE "PGM_PHASE3_C-STG-TRX" & x"00"
GIXSQL         BY VALUE 0
GIXSQL         BY REFERENCE SQ0001
GIXSQL         BY VALUE 0
GIXSQL     END-CALL.
GIXSQL GIX-SKIP-CRSR-INIT.
GIXSQL*
GIXSQL*   ESQL CURSOR DECLARATIONS (END)
