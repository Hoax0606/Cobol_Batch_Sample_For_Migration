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
       MAIN-999.
           MOVE SYS-RET-CODE TO RETURN-CODE
           STOP RUN.

      *----------------------------------------------------------------*
      * INIT                          SECTION.
      *----------------------------------------------------------------*
       INIT                           SECTION.
       INIT-000.
      * --- ??? ?? ?? ??? ---
           MOVE WS-PHASE-ID                 TO SYS-JOB-ID.
           MOVE FUNCTION CURRENT-DATE(1:8)  TO SYS-BIZ-DATE.
           MOVE FUNCTION CURRENT-DATE(1:14) TO WS-START-DATETIME.

      * --- ?????? DB ?? ?? ?? ---
           ACCEPT WS-DATASRC      FROM ENVIRONMENT 'GIXSQL_DB_CONN'.
           ACCEPT WS-USER         FROM ENVIRONMENT 'GIXSQL_USER'.
           ACCEPT WS-PWD          FROM ENVIRONMENT 'GIXSQL_PWD'.

           IF WS-DATASRC = SPACES THEN
               MOVE 'GIXSQL_DB_CONN NOT SET' TO ERR-DESCRIPTION
               PERFORM SYSTEM-ERROR-000
               SET BATCH-ERROR TO TRUE
               MOVE SYS-RET-CODE TO RETURN-CODE
               STOP RUN
           ELSE
               CONTINUE
           END-IF.  

      * --- ?? ?? ?? ---
           OPEN INPUT IN-FILE.

           IF WS-IN-STAT NOT = '00' THEN
               MOVE 'INPUT FILE OPEN ERROR' TO ERR-DESCRIPTION
               PERFORM SYSTEM-ERROR-000
               SET BATCH-ERROR TO TRUE
               MOVE SYS-RET-CODE TO RETURN-CODE
               STOP RUN
           ELSE
               CONTINUE
           END-IF.

      * --- DB ?? ---
      *    EXEC SQL
      *        CONNECT :WS-USER IDENTIFIED BY :WS-PWD
      *                USING :WS-DATASRC
      *    END-EXEC.

           IF SQLCODE NOT = 0 THEN
               MOVE SQLCODE            TO ERR-SQLCODE
               MOVE 'DB CONNECT ERROR' TO ERR-DESCRIPTION
               PERFORM SYSTEM-ERROR-000
               SET BATCH-ERROR TO TRUE
               MOVE SYS-RET-CODE TO RETURN-CODE
               STOP RUN
           ELSE
               CONTINUE
           END-IF.

      * --- ?? ?? ?? ?? ---
           PERFORM BATCHLOG-START-000.

      * --- ???? ??? ?? ??? (??? ???) ---
      *    EXEC SQL DELETE FROM TB_STG_TRX END-EXEC.
      *    EXEC SQL COMMIT END-EXEC.
       KS_JAVA_START
       dao.delete_01(dto);
       KS_JAVA_END
      * --- ?? ??? ?? ---
           PERFORM READ-IN-FILE-000.
       INIT-999.
           EXIT.

      *----------------------------------------------------------------*
      * DATA-PROCESS                  SECTION.
      *----------------------------------------------------------------*
       DATA-PROCESS                   SECTION.
       PROCESS-000.
      * --- INSPECT REPLACING: ???? ???? ??? ---
           INSPECT IN-REC
               CONVERTING 'abcdefghijklmnopqrstuvwxyz'
                       TO 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.

      * --- ??? ??(H/D/T) ??? ?? ?? ?? ---
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
      * --- TB_INST_MASTER ??: ???? ??? ?? ? ???? ?? ---
           MOVE INST-CD               TO INST-MAST-CD.

      *    EXEC SQL
      *        SELECT INST_CD,
      *               INST_STAT,      FEE_RATE
      *          INTO :INST-MAST-CD,
      *               :INST-MAST-STAT,     :INST-MAST-FEE-RATE
      *          FROM TB_INST_MASTER
      *         WHERE INST_CD = :INST-MAST-CD
      *    END-EXEC.
       KS_JAVA_START
       dao.select_01(dto);
       KS_JAVA_END

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
      * --- ??? ??? ?? ---
           MOVE TRX-DATE              TO STG-TRX-DATE.
           MOVE TRX-SEQ               TO STG-TRX-SEQ.
           MOVE INST-CD               TO STG-INST-CD.
           MOVE ACC-NO                TO STG-ACC-NO.
           MOVE TRX-TYPE              TO STG-TRX-TYPE.
           MOVE TRX-AMT               TO STG-TRX-AMT.

      * --- ??? ????? ??? ?? (COMP-3?? ?? ??? ??) ---
           COMPUTE WS-FEE-AMT-COMP
                       = STG-TRX-AMT * INST-MAST-FEE-RATE.
           MOVE WS-FEE-AMT-COMP       TO STG-FEE-AMT.
           MOVE WS-PROC-STAT-INIT     TO STG-PROC-STAT.

      * --- ?? INSERT (INIT ???? DELETE? ?? ??? ??) ---
      *    EXEC SQL
      *        INSERT INTO TB_STG_TRX
      *               (TRX_DATE,    TRX_SEQ,     INST_CD,
      *                ACC_NO,      TRX_TYPE,    TRX_AMT,
      *                FEE_AMT,     PROC_STAT)
      *        VALUES (:STG-TRX-DATE, :STG-TRX-SEQ,
      *                :STG-INST-CD,  :STG-ACC-NO,
      *                :STG-TRX-TYPE, :STG-TRX-AMT,
      *                :STG-FEE-AMT,  :STG-PROC-STAT)
      *    END-EXEC.
       KS_JAVA_START
       dao.insert_01(dto);
       KS_JAVA_END
       
           IF SQLCODE = 0 THEN
               ADD 1              TO WS-INSERT-CNT
               ADD 1              TO WS-COMMIT-CNT
           ELSE
               ADD 1              TO WS-ERR-CNT
               MOVE SQLCODE       TO ERR-SQLCODE
               MOVE 'DB INSERT ERROR' TO ERR-DESCRIPTION
               PERFORM DB-ERROR-000
           END-IF.
       
      * --- ?? COMMIT ? ?? ?? ?? ---
           IF WS-COMMIT-CNT >= WS-COMMIT-INTERVAL THEN
      *        EXEC SQL COMMIT END-EXEC
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
           DISPLAY ' > ... ' WS-INSERT-CNT ' RECORDS INSERTED... <'.
       PROGRESS-LOG-999.
           EXIT.

      *----------------------------------------------------------------*
      * FINALIZE                      SECTION.
      *----------------------------------------------------------------*
       FINALIZE                       SECTION.
       FINALIZE-000.
      * --- ?? ???? ?? ---
           IF WS-COMMIT-CNT > 0 THEN
      *        EXEC SQL COMMIT END-EXEC
           ELSE
               CONTINUE
           END-IF.

           CLOSE IN-FILE.

      * --- ?? ?? ?? ?? ---
           PERFORM BATCHLOG-END-000.
      *    EXEC SQL COMMIT            END-EXEC.

      *    EXEC SQL DISCONNECT CURRENT END-EXEC.

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
           MOVE 'PHASE2 STARTED'      TO BLG-REMARK.
           MOVE 'START'               TO BLG-ACTION.

           CALL 'PGM-BLOGSVR' USING DCL-TB-BATCH-LOG.

           IF BLG-RETURN-CODE NOT = 0 THEN
               DISPLAY '> [WARN] BLOGSVR START FAILED. RC='
                       BLG-RETURN-CODE
           ELSE
               CONTINUE
           END-IF.

       BATCHLOG-START-999.
           EXIT.

      *----------------------------------------------------------------*
      * BATCHLOG-END                  SECTION.
      *----------------------------------------------------------------*
       BATCHLOG-END                   SECTION.
       BATCHLOG-END-000.
           MOVE WS-INSERT-CNT         TO BLG-PROC-CNT.
           MOVE WS-ERR-CNT            TO BLG-ERR-CNT.
           MOVE 'END  '               TO BLG-ACTION.

           IF WS-ERR-CNT > 0 THEN
               MOVE 'E'               TO BLG-STAT
               MOVE 'PHASE2 COMPLETED WITH ERRORS' TO BLG-REMARK
           ELSE
               MOVE 'S'               TO BLG-STAT
               MOVE 'PHASE2 COMPLETED SUCCESSFULLY' TO BLG-REMARK
           END-IF.

           CALL 'PGM-BLOGSVR' USING DCL-TB-BATCH-LOG.

           IF BLG-RETURN-CODE NOT = 0 THEN
               DISPLAY '> [WARN] BLOGSVR END FAILED. RC='
                       BLG-RETURN-CODE
           ELSE
               CONTINUE
           END-IF.

       BATCHLOG-END-999.
           EXIT.
      *================================================================*
      * END OF PGM-PHASE2
      *================================================================*
      
