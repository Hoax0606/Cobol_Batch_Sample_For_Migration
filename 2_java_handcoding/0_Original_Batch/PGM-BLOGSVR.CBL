      *================================================================*
      * PGM-BLOGSVR.cbl - ?? ?? ??? ??????
      * ?? : TB_BATCH_LOG ???? ?? ??? ????.
      *        ?? ? BLG-ACTION ?? ?? START/END ??? ????.
      * ?? : CALL 'PGM-BLOGSVR' USING BLG-PARAMS
      * ?? : BLG-BATCH-ID (START ? ??? ID? ??)
      *        BLG-RETURN-CODE (0=??, 8=??)
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

      * --- DB ?? ?? (?????? ?? ??) ---
       01  WS-DB-CONN.
           05 WS-DATASRC              PIC X(50) VALUE SPACES.
           05 WS-USER                 PIC X(30) VALUE SPACES.
           05 WS-PWD                  PIC X(30) VALUE SPACES.

      * --- ?? ??? ?? ---
       01  WS-WORK-AREAS.
           05 WS-SQLCODE-DISP         PIC S9(9) VALUE 0.

      *================================================================*
      * LINKAGE                       SECTION.
      *================================================================*
       LINKAGE                        SECTION.
           EXEC SQL INCLUDE SQL-DCLGEN END-EXEC.
      *================================================================*
      * PROCEDURE                     DIVISION.
      *================================================================*
       PROCEDURE                      DIVISION USING DCL-TB-BATCH-LOG.
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
           GOBACK.
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
                   CONTINUE
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
      
