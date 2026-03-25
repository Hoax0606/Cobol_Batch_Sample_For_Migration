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

           INITIALIZE NETTING-TABLE.

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

      * --- DB ?? ---
      *    EXEC SQL 
      *        CONNECT :WS-USER IDENTIFIED BY :WS-PWD
      *                USING :WS-DATASRC
      *    END-EXEC.

           IF SQLCODE NOT = 0 THEN
               MOVE SQLCODE           TO ERR-SQLCODE
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

      * --- TB_TRX_DETAIL ?? ??? (??? ???) ---
           PERFORM DELETE-TRX-DETAIL-000.
      *    EXEC SQL COMMIT            END-EXEC.

      * --- C-STG-TRX ?? ?? ---
      *    EXEC SQL OPEN C-STG-TRX    END-EXEC.

           IF SQLCODE NOT = 0 THEN
               MOVE SQLCODE           TO ERR-SQLCODE
               MOVE 'CURSOR OPEN ERROR' TO ERR-DESCRIPTION
               PERFORM SYSTEM-ERROR-000
               SET BATCH-ERROR TO TRUE
               MOVE SYS-RET-CODE TO RETURN-CODE
               STOP RUN
           ELSE
               CONTINUE
           END-IF.

       INIT-999.
           EXIT.

      *----------------------------------------------------------------*
      * DATA-PROCESS                  SECTION.
      *----------------------------------------------------------------*
      * C-STG-TRX FETCH �� TB_INST_MASTER JOIN SELECT
      *                 �� TB_TRX_DETAIL INSERT
      *                 �� NETTING-TABLE ??
      *                 �� TB_STG_TRX PROC_STAT UPDATE
      *----------------------------------------------------------------*
       DATA-PROCESS                   SECTION.
       PROCESS-000.
      *    EXEC SQL
      *        FETCH C-STG-TRX
      *         INTO :STG-TRX-DATE,  :STG-TRX-SEQ,
      *              :STG-INST-CD,   :STG-ACC-NO,
      *              :STG-TRX-TYPE,  :STG-TRX-AMT,
      *              :STG-FEE-AMT
      *    END-EXEC.
       KS_JAVA_START
       dao.select_01(dto);
       KS_JAVA_END

           EVALUATE SQLCODE
               WHEN 0
                   ADD 1              TO WS-TOTAL-READ
                   PERFORM JOIN-INST-MASTER-000
               WHEN 100
                   SET WS-EOF         TO TRUE
               WHEN OTHER
                   MOVE SQLCODE       TO ERR-SQLCODE
                   MOVE 'STG CURSOR FETCH ERROR' TO ERR-DESCRIPTION
                   PERFORM DB-ERROR-000
                   SET WS-EOF         TO TRUE
           END-EVALUATE.

       PROCESS-999.
           EXIT.

      *----------------------------------------------------------------*
      * JOIN-INST-MASTER              SECTION.
      *----------------------------------------------------------------*
      * TB_INST_MASTER SELECT �� ???�E???? ?? (JOIN ??)
      * SQLCODE=0  : ??? ??? �� DETAIL INSERT �� ?? �� STG UPDATE
      * SQLCODE=100: ? ? ?? ?? �� WARN ?? ? SKIP
      *----------------------------------------------------------------*
       JOIN-INST-MASTER               SECTION.
       JOIN-INST-MASTER-000.
           MOVE STG-INST-CD           TO INST-MAST-CD.

      *    EXEC SQL
      *        SELECT INST_CD,    INST_NAME,
      *               INST_STAT,  FEE_RATE
      *          INTO :INST-MAST-CD,       :INST-MAST-NAME,
      *               :INST-MAST-STAT,     :INST-MAST-FEE-RATE
      *          FROM TB_INST_MASTER
      *         WHERE INST_CD = :INST-MAST-CD
      *    END-EXEC.
       KS_JAVA_START
       dao.select_03(dto);
       KS_JAVA_END

           EVALUATE SQLCODE
               WHEN 0
                   PERFORM CALC-FEE-000
                   PERFORM INSERT-TRX-DETAIL-000
                   PERFORM AGGREGATE-MEMORY-000
                   PERFORM UPDATE-STG-STAT-000
                   PERFORM CHUNK-COMMIT-000
               WHEN 100
                   ADD 1              TO WS-ERR-CNT
                   MOVE 'INST NOT FOUND IN MASTER' TO ERR-DESCRIPTION
                   PERFORM DB-WARN-000
               WHEN OTHER
                   MOVE SQLCODE       TO ERR-SQLCODE
                   MOVE 'INST MASTER JOIN SELECT ERROR'
                                      TO ERR-DESCRIPTION
                   PERFORM DB-ERROR-000
           END-EVALUATE.

       JOIN-INST-MASTER-999.
           EXIT.

      *----------------------------------------------------------------*
      * CALC-FEE                      SECTION.
      *----------------------------------------------------------------*
      * INST_MASTER.FEE_RATE ? ??? ???
      *----------------------------------------------------------------*
       CALC-FEE                       SECTION.
       CALC-FEE-000.
           COMPUTE WS-FEE-WORK ROUNDED
               = STG-TRX-AMT * INST-MAST-FEE-RATE.
       CALC-FEE-999.
           EXIT.

      *----------------------------------------------------------------*
      * INSERT-TRX-DETAIL             SECTION.
      *----------------------------------------------------------------*
      * TB_STG_TRX(FETCH) + TB_INST_MASTER(JOIN) ???
      * TB_TRX_DETAIL ? ?? ??
      *   DTL-INST-NAME  �� INST-MAST-NAME  (INST_MASTER JOIN)
      *   DTL-FEE-RATE   �� INST-MAST-FEE-RATE (INST_MASTER JOIN)
      *   DTL-CALC-FEE-AMT �� WS-FEE-WORK (???)
      *----------------------------------------------------------------*
       INSERT-TRX-DETAIL              SECTION.
       INSERT-TRX-DETAIL-000.
           MOVE SYS-BIZ-DATE          TO DTL-SETTLE-DATE.
           MOVE STG-TRX-SEQ           TO DTL-TRX-SEQ.
           MOVE STG-INST-CD           TO DTL-INST-CD.
           MOVE INST-MAST-NAME        TO DTL-INST-NAME.
           MOVE STG-ACC-NO            TO DTL-ACC-NO.
           MOVE STG-TRX-TYPE          TO DTL-TRX-TYPE.
           MOVE STG-TRX-AMT           TO DTL-TRX-AMT.
           MOVE STG-FEE-AMT           TO DTL-STG-FEE-AMT.
           MOVE INST-MAST-FEE-RATE    TO DTL-FEE-RATE.
           MOVE WS-FEE-WORK           TO DTL-CALC-FEE-AMT.
           MOVE WS-PROC-STAT-DONE     TO DTL-PROC-STAT.

      *    EXEC SQL
      *        INSERT INTO TB_TRX_DETAIL
      *               (SETTLE_DATE,   TRX_SEQ,       INST_CD,
      *                INST_NAME,     ACC_NO,        TRX_TYPE,
      *                TRX_AMT,       STG_FEE_AMT,   FEE_RATE,
      *                CALC_FEE_AMT,  PROC_STAT)
      *        VALUES (:DTL-SETTLE-DATE, :DTL-TRX-SEQ,    :DTL-INST-CD,
      *                :DTL-INST-NAME,   :DTL-ACC-NO,     :DTL-TRX-TYPE,
      *                :DTL-TRX-AMT,     :DTL-STG-FEE-AMT,:DTL-FEE-RATE,
      *                :DTL-CALC-FEE-AMT,:DTL-PROC-STAT)
      *    END-EXEC.
       KS_JAVA_START
       dao.insert_01(dto);
       KS_JAVA_END

           IF SQLCODE = 0 THEN
               ADD 1                  TO WS-DETAIL-INS-CNT
           ELSE
               ADD 1                  TO WS-ERR-CNT
               MOVE SQLCODE           TO ERR-SQLCODE
               MOVE 'TRX_DETAIL INSERT ERROR' TO ERR-DESCRIPTION
               PERFORM DB-ERROR-000
           END-IF.

       INSERT-TRX-DETAIL-999.
           EXIT.

      *----------------------------------------------------------------*
      * AGGREGATE-MEMORY              SECTION.
      *----------------------------------------------------------------*
      * ???? NETTING-TABLE ??? ?? ??
      *
      * ?? ?? ??:
      *   WS-NET-MAX-IDX+1 ??? ?? (?? ???)
      *----------------------------------------------------------------*
       AGGREGATE-MEMORY               SECTION.
       AGGREGATE-MEMORY-000.
           SET WS-NOT-FOUND           TO TRUE.

      *    ????: ?? ??(1~WS-NET-MAX-IDX)?? ???? ??
           PERFORM VARYING NET-IDX FROM 1 BY 1
                     UNTIL NET-IDX > WS-NET-MAX-IDX
                        OR WS-FOUND
               IF NET-INST-CD(NET-IDX) = STG-INST-CD THEN
                   SET WS-FOUND           TO TRUE
                   ADD 1                  TO NET-CNT(NET-IDX)
                   ADD WS-FEE-WORK        TO NET-TOT-FEE(NET-IDX)
                   IF STG-TRX-TYPE = 'I' THEN
                       ADD STG-TRX-AMT    TO NET-TOT-IN(NET-IDX)
                   ELSE
                       ADD STG-TRX-AMT    TO NET-TOT-OUT(NET-IDX)
                   END-IF
               ELSE
                   CONTINUE
               END-IF
           END-PERFORM.

      *    ??? ??: ����? ?? ??? ??
           IF WS-NOT-FOUND THEN
               ADD 1                  TO WS-NET-MAX-IDX
               SET NET-IDX            TO WS-NET-MAX-IDX
               MOVE STG-INST-CD       TO NET-INST-CD(NET-IDX)
               MOVE 1                 TO NET-CNT(NET-IDX)
               MOVE WS-FEE-WORK       TO NET-TOT-FEE(NET-IDX)
               MOVE 0                 TO NET-TOT-IN(NET-IDX)
               MOVE 0                 TO NET-TOT-OUT(NET-IDX)
               IF STG-TRX-TYPE = 'I' THEN
                   ADD STG-TRX-AMT    TO NET-TOT-IN(NET-IDX)
               ELSE
                   ADD STG-TRX-AMT    TO NET-TOT-OUT(NET-IDX)
               END-IF
           ELSE
               CONTINUE
           END-IF.

       AGGREGATE-MEMORY-999.
           EXIT.

      *----------------------------------------------------------------*
      * UPDATE-STG-STAT               SECTION.
      *----------------------------------------------------------------*
      * TB_STG_TRX.PROC_STAT �� '9' (?? ?? ??)
      *----------------------------------------------------------------*
       UPDATE-STG-STAT                SECTION.
       UPDATE-STG-STAT-000.
      *    EXEC SQL
      *        UPDATE TB_STG_TRX
      *           SET PROC_STAT = '9'
      *         WHERE TRX_DATE = :STG-TRX-DATE
      *           AND TRX_SEQ  = :STG-TRX-SEQ
      *    END-EXEC.
       KS_JAVA_START
       dao.update_01(dto);
       KS_JAVA_END

           IF SQLCODE = 0 THEN
               ADD 1                  TO WS-STAT-UPD-CNT
           ELSE
               ADD 1                  TO WS-ERR-CNT
               MOVE SQLCODE           TO ERR-SQLCODE
               MOVE 'STG_TRX UPDATE ERROR' TO ERR-DESCRIPTION
               PERFORM DB-ERROR-000
           END-IF.

       UPDATE-STG-STAT-999.
           EXIT.

      *----------------------------------------------------------------*
      * CHUNK-COMMIT                  SECTION.
      *----------------------------------------------------------------*
       CHUNK-COMMIT                   SECTION.
       CHUNK-COMMIT-000.
           ADD 1                      TO WS-COMMIT-CNT.

           IF WS-COMMIT-CNT >= WS-COMMIT-INTERVAL THEN
      *        EXEC SQL COMMIT        END-EXEC
               MOVE 0                 TO WS-COMMIT-CNT
               PERFORM PROGRESS-LOG-000
           ELSE
               CONTINUE
           END-IF.

       CHUNK-COMMIT-999.
           EXIT.

      *----------------------------------------------------------------*
      * FINALIZE                      SECTION.
      *----------------------------------------------------------------*
       FINALIZE                       SECTION.
       FINALIZE-000.
      * --- C-STG-TRX ?? ?? / ?? COMMIT ---
      *    EXEC SQL CLOSE C-STG-TRX   END-EXEC.

           IF WS-COMMIT-CNT > 0 THEN
      *        EXEC SQL COMMIT        END-EXEC
           ELSE
               CONTINUE
           END-IF.

      * --- �@ TB_INST_DAILY_STAT : ???? ?? �� DB ?? ---
           PERFORM DELETE-INST-STAT-000.
      *    EXEC SQL COMMIT            END-EXEC.

           PERFORM INSERT-INST-STAT-000 VARYING NET-IDX FROM 1 BY 1
                     UNTIL NET-IDX > WS-NET-MAX-IDX.

      *    EXEC SQL COMMIT            END-EXEC.

      * --- �A TB_NET_SUMMARY : DAILY_STAT + INST_MASTER JOIN/MERGE ---
           PERFORM DELETE-NET-SUMMARY-000.
           PERFORM OPEN-JOIN-CURSOR-000.
           PERFORM FETCH-AND-INSERT-SUMMARY-000
               UNTIL WS-JOIN-EOF.
           PERFORM CLOSE-JOIN-CURSOR-000.

      *    EXEC SQL COMMIT            END-EXEC.

      * --- �B ?? ?? ?? ?? ---
           PERFORM BATCHLOG-END-000.
      *    EXEC SQL COMMIT            END-EXEC.

           DISPLAY ' > ========= PGM-PHASE3 RESULT ========='.
           DISPLAY ' > TOTAL READ       : ' WS-TOTAL-READ.
           DISPLAY ' > DETAIL INSERT    : ' WS-DETAIL-INS-CNT.
           DISPLAY ' > STG STAT UPDATE  : ' WS-STAT-UPD-CNT.
           DISPLAY ' > SUMMARY INSERT   : ' WS-SUMMARY-INS-CNT.
           DISPLAY ' > INST COUNT       : ' WS-NET-MAX-IDX.
           DISPLAY ' > ERROR COUNT      : ' WS-ERR-CNT.
           DISPLAY ' > ====================================='.

      *    EXEC SQL DISCONNECT CURRENT END-EXEC.

       FINALIZE-999.
           EXIT.

      *----------------------------------------------------------------*
      * DELETE-TRX-DETAIL             SECTION.
      *----------------------------------------------------------------*
      * ?? TB_TRX_DETAIL ?? (??? ??? ??)
      *----------------------------------------------------------------*
       DELETE-TRX-DETAIL              SECTION.
       DELETE-TRX-DETAIL-000.
           MOVE SYS-BIZ-DATE          TO DTL-SETTLE-DATE.

      *    EXEC SQL
      *        DELETE FROM TB_TRX_DETAIL
      *         WHERE SETTLE_DATE = :DTL-SETTLE-DATE
      *    END-EXEC.
       KS_JAVA_START
       dao.delete_01(dto);
       KS_JAVA_END

           IF SQLCODE NOT = 0 AND SQLCODE NOT = 100 THEN
               MOVE SQLCODE           TO ERR-SQLCODE
               MOVE 'TRX_DETAIL DELETE ERROR' TO ERR-DESCRIPTION
               PERFORM DB-ERROR-000
           ELSE
               CONTINUE
           END-IF.

       DELETE-TRX-DETAIL-999.
           EXIT.

      *----------------------------------------------------------------*
      * DELETE-INST-STAT              SECTION.
      *----------------------------------------------------------------*     
      * ?? TB_INST_DAILY_STAT ?? (??? ??? ??)
      *----------------------------------------------------------------*
       DELETE-INST-STAT               SECTION.
       DELETE-INST-STAT-000.
           MOVE SYS-BIZ-DATE          TO IDS-SETTLE-DATE.

      *    EXEC SQL
      *        DELETE FROM TB_INST_DAILY_STAT
      *         WHERE SETTLE_DATE = :IDS-SETTLE-DATE
      *    END-EXEC.
       KS_JAVA_START
       dao.delete_02(dto);
       KS_JAVA_END

           IF SQLCODE NOT = 0 AND SQLCODE NOT = 100 THEN
               MOVE SQLCODE           TO ERR-SQLCODE
               MOVE 'INST_STAT DELETE ERROR' TO ERR-DESCRIPTION
               PERFORM DB-ERROR-000
           ELSE
               CONTINUE
           END-IF.

       DELETE-INST-STAT-999.
           EXIT.

      *----------------------------------------------------------------*
      * INSERT-INST-STAT              SECTION.
      *----------------------------------------------------------------*
      * NETTING-TABLE(???) �� TB_INST_DAILY_STAT INSERT
      *----------------------------------------------------------------*
       INSERT-INST-STAT               SECTION.
       INSERT-INST-STAT-000.
           MOVE SYS-BIZ-DATE          TO IDS-SETTLE-DATE.
           MOVE NET-INST-CD(NET-IDX)  TO IDS-INST-CD.
           MOVE NET-TOT-IN(NET-IDX)   TO IDS-TOT-IN.
           MOVE NET-TOT-OUT(NET-IDX)  TO IDS-TOT-OUT.
           COMPUTE IDS-NET-AMT
               = NET-TOT-IN(NET-IDX) - NET-TOT-OUT(NET-IDX).
           MOVE NET-TOT-FEE(NET-IDX)  TO IDS-TOT-FEE.
           MOVE NET-CNT(NET-IDX)      TO IDS-TOTAL-CNT.

      *    EXEC SQL
      *        INSERT INTO TB_INST_DAILY_STAT
      *               (SETTLE_DATE, INST_CD,
      *                TOT_IN_AMT,  TOT_OUT_AMT,
      *                NET_AMT,     TOT_FEE_AMT,  TOTAL_CNT)
      *        VALUES (:IDS-SETTLE-DATE, :IDS-INST-CD,
      *                :IDS-TOT-IN,      :IDS-TOT-OUT,
      *                :IDS-NET-AMT,     :IDS-TOT-FEE,
      *                :IDS-TOTAL-CNT)
      *    END-EXEC.
       KS_JAVA_START
       dao.insert_02(dto);
       KS_JAVA_END

           IF SQLCODE NOT = 0 THEN
               MOVE SQLCODE           TO ERR-SQLCODE
               MOVE 'INST_STAT INSERT ERROR' TO ERR-DESCRIPTION
               PERFORM DB-ERROR-000
           ELSE
               CONTINUE
           END-IF.

       INSERT-INST-STAT-999.
           EXIT.

      *----------------------------------------------------------------*
      * DELETE-NET-SUMMARY            SECTION.
      *----------------------------------------------------------------*
      * ?? TB_NET_SUMMARY ?? (??? ??? ??)
      *----------------------------------------------------------------*
       DELETE-NET-SUMMARY             SECTION.
       DELETE-NET-SUMMARY-000.
           MOVE SYS-BIZ-DATE          TO SUM-SETTLE-DATE.

      *    EXEC SQL
      *        DELETE FROM TB_NET_SUMMARY
      *         WHERE SETTLE_DATE = :SUM-SETTLE-DATE
      *    END-EXEC.
       KS_JAVA_START
       dao.delete_03(dto);
       KS_JAVA_END

           IF SQLCODE NOT = 0 AND SQLCODE NOT = 100 THEN
               MOVE SQLCODE           TO ERR-SQLCODE
               MOVE 'NET_SUMMARY DELETE ERROR' TO ERR-DESCRIPTION
               PERFORM DB-ERROR-000
           ELSE
               CONTINUE
           END-IF.

       DELETE-NET-SUMMARY-999.
           EXIT.

      *----------------------------------------------------------------*
      * OPEN-JOIN-CURSOR              SECTION.
      *----------------------------------------------------------------*
      * C-DAILY-STAT-JOIN ?? ??
      * WHERE D.SETTLE_DATE = :IDS-SETTLE-DATE ??? ?? ??
      *----------------------------------------------------------------*
       OPEN-JOIN-CURSOR               SECTION.
       OPEN-JOIN-CURSOR-000.
           MOVE SYS-BIZ-DATE          TO IDS-SETTLE-DATE.
           SET WS-JOIN-NOT-EOF        TO TRUE.

      *    EXEC SQL OPEN C-DAILY-STAT-JOIN END-EXEC.

           IF SQLCODE NOT = 0 THEN
               MOVE SQLCODE           TO ERR-SQLCODE
               MOVE 'JOIN CURSOR OPEN ERROR' TO ERR-DESCRIPTION
               PERFORM SYSTEM-ERROR-000
               SET BATCH-ERROR TO TRUE
               MOVE SYS-RET-CODE TO RETURN-CODE
               STOP RUN
           ELSE
               CONTINUE
           END-IF.

       OPEN-JOIN-CURSOR-999.
           EXIT.

      *----------------------------------------------------------------*
      * FETCH-AND-INSERT-SUMMARY      SECTION.
      *----------------------------------------------------------------*
      * C-DAILY-STAT-JOIN FETCH
      *   TB_INST_DAILY_STAT D JOIN TB_INST_MASTER M ??? ??
      *   TB_NET_SUMMARY ? INSERT (JOIN �� MERGE)
      *
      *   SUM-INST-NAME �� M.INST_NAME   (INST_MASTER JOIN)
      *   SUM-FEE-RATE  �� M.FEE_RATE    (INST_MASTER JOIN)
      *----------------------------------------------------------------*
       FETCH-AND-INSERT-SUMMARY       SECTION.
       FETCH-AND-INSERT-SUMMARY-000.
      *    EXEC SQL
      *        FETCH C-DAILY-STAT-JOIN
      *         INTO :SUM-SETTLE-DATE, :SUM-INST-CD,
      *              :SUM-INST-NAME,   :SUM-FEE-RATE,
      *              :SUM-TOT-IN,      :SUM-TOT-OUT,
      *              :SUM-NET-AMT,     :SUM-TOT-FEE,
      *              :SUM-TOT-CNT
      *    END-EXEC.
       KS_JAVA_START
       dao.select_02(dto);
       KS_JAVA_END

           EVALUATE SQLCODE
               WHEN 0
                   PERFORM INSERT-NET-SUMMARY-000
               WHEN 100
                   SET WS-JOIN-EOF    TO TRUE
               WHEN OTHER
                   MOVE SQLCODE       TO ERR-SQLCODE
                   MOVE 'JOIN CURSOR FETCH ERROR' TO ERR-DESCRIPTION
                   PERFORM DB-ERROR-000
                   SET WS-JOIN-EOF    TO TRUE
           END-EVALUATE.

       FETCH-AND-INSERT-SUMMARY-999.
           EXIT.

      *----------------------------------------------------------------*
      * INSERT-NET-SUMMARY            SECTION.
      *----------------------------------------------------------------*
      * JOIN ?? (DAILY_STAT + INST_MASTER) �� TB_NET_SUMMARY INSERT
      *----------------------------------------------------------------*
       INSERT-NET-SUMMARY             SECTION.
       INSERT-NET-SUMMARY-000.
      *    EXEC SQL
      *        INSERT INTO TB_NET_SUMMARY
      *               (SETTLE_DATE,  INST_CD,
      *                INST_NAME,    FEE_RATE,
      *                TOT_IN_AMT,   TOT_OUT_AMT,
      *                NET_AMT,      TOT_FEE_AMT,  TOTAL_CNT)
      *        VALUES (:SUM-SETTLE-DATE, :SUM-INST-CD,
      *                :SUM-INST-NAME,   :SUM-FEE-RATE,
      *                :SUM-TOT-IN,      :SUM-TOT-OUT,
      *                :SUM-NET-AMT,     :SUM-TOT-FEE,
      *                :SUM-TOT-CNT)
      *    END-EXEC.
       KS_JAVA_START
       dao.insert_03(dto);
       KS_JAVA_END
           
           IF SQLCODE = 0 THEN
               ADD 1                  TO WS-SUMMARY-INS-CNT
           ELSE
               MOVE SQLCODE           TO ERR-SQLCODE
               MOVE 'NET_SUMMARY INSERT ERROR' TO ERR-DESCRIPTION
               PERFORM DB-ERROR-000
           END-IF.

       INSERT-NET-SUMMARY-999.
           EXIT.

      *----------------------------------------------------------------*
      * CLOSE-JOIN-CURSOR             SECTION.
      *----------------------------------------------------------------*
       CLOSE-JOIN-CURSOR              SECTION.
       CLOSE-JOIN-CURSOR-000.
      *    EXEC SQL CLOSE C-DAILY-STAT-JOIN END-EXEC.

           IF SQLCODE NOT = 0 THEN
               MOVE SQLCODE           TO ERR-SQLCODE
               MOVE 'JOIN CURSOR CLOSE ERROR' TO ERR-DESCRIPTION
               PERFORM DB-ERROR-000
           ELSE
               CONTINUE
           END-IF.

       CLOSE-JOIN-CURSOR-999.
           EXIT.

      *----------------------------------------------------------------*
      * BATCHLOG-START                SECTION.
      *----------------------------------------------------------------*
      * TB_BATCH_LOG : ?? ?? ?? INSERT (STAT='R')
      *----------------------------------------------------------------*
       BATCHLOG-START                 SECTION.
       BATCHLOG-START-000.
           MOVE WS-PROG-NAME          TO BLG-PGM-ID.
           MOVE SYS-BIZ-DATE          TO BLG-BIZ-DATE.
           MOVE WS-START-DATETIME     TO BLG-START-DT.
           MOVE 'PHASE3 STARTED'      TO BLG-REMARK.
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
      * TB_BATCH_LOG : ?? ?? ?? UPDATE (STAT='S'/'E')
      *----------------------------------------------------------------*
       BATCHLOG-END                   SECTION.
       BATCHLOG-END-000.
           MOVE WS-TOTAL-READ         TO BLG-PROC-CNT.
           MOVE WS-ERR-CNT            TO BLG-ERR-CNT.
           MOVE 'END  '               TO BLG-ACTION.

           IF WS-ERR-CNT > 0 THEN
               MOVE 'E'               TO BLG-STAT
               MOVE 'PHASE3 COMPLETED WITH ERRORS' TO BLG-REMARK
           ELSE
               MOVE 'S'               TO BLG-STAT
               MOVE 'PHASE3 COMPLETED SUCCESSFULLY' TO BLG-REMARK
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

      *----------------------------------------------------------------*
      * PROGRESS-LOG                  SECTION.
      *----------------------------------------------------------------*
       PROGRESS-LOG                   SECTION.
       PROGRESS-LOG-000.
           DISPLAY ' >... ' WS-TOTAL-READ
                   ' RECORDS PROCESSED / DETAIL: '
                   WS-DETAIL-INS-CNT.
       PROGRESS-LOG-999.
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
           DISPLAY 'PGM: '     ERR-PGM-ID
                   ' SQLCODE: ' ERR-SQLCODE.
           DISPLAY 'MSG: '     ERR-DESCRIPTION.
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
           DISPLAY '*** DB ERROR ***'.
           DISPLAY 'PGM: '      ERR-PGM-ID
                   ' SQLCODE: ' ERR-SQLCODE.
           DISPLAY 'MSG: '      ERR-DESCRIPTION.
       DB-ERROR-999.
           EXIT.

      *----------------------------------------------------------------*
      * DB-WARN                       SECTION.
      *----------------------------------------------------------------*
       DB-WARN                        SECTION.
       DB-WARN-000.
           MOVE WS-PROG-NAME          TO ERR-PGM-ID.
           SET ERR-INFO               TO TRUE.
           DISPLAY ' > [WARN] INST=[' STG-INST-CD '] '
                   ERR-DESCRIPTION.
       DB-WARN-999.
           EXIT.

      *================================================================*
      * END OF PGM-PHASE3
      *================================================================*
