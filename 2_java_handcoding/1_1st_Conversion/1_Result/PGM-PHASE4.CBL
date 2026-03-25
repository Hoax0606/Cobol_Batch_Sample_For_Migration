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
           MOVE WS-PHASE-ID                  TO SYS-JOB-ID.
           MOVE FUNCTION CURRENT-DATE(1:8)   TO SYS-BIZ-DATE.
           MOVE FUNCTION CURRENT-DATE(1:14)  TO WS-START-DATETIME.
           MOVE SYS-BIZ-DATE                 TO WS-BIZ-DATE-W.

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
           OPEN OUTPUT OUT-FILE.

           IF WS-OUT-STAT NOT = '00' THEN
               MOVE 'OUTPUT FILE OPEN ERROR' TO ERR-DESCRIPTION
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

      * --- CURSOR OPEN ---
      *    EXEC SQL OPEN C-NET-SUMMARY END-EXEC.

           IF SQLCODE NOT = 0 THEN
               MOVE SQLCODE               TO ERR-SQLCODE
               MOVE 'CURSOR OPEN ERROR'   TO ERR-DESCRIPTION
               PERFORM SYSTEM-ERROR-000
               SET BATCH-ERROR TO TRUE
               MOVE SYS-RET-CODE TO RETURN-CODE
               STOP RUN
           ELSE
               CONTINUE
           END-IF.

      * --- Header ���R�[�h�o�� ---
           PERFORM WRITE-HEADER-000.

       INIT-999.
           EXIT.

      *----------------------------------------------------------------*
      * DATA-PROCESS                  SECTION.
      *----------------------------------------------------------------*
       DATA-PROCESS                   SECTION.
       PROCESS-000.
      *    EXEC SQL
      *        FETCH C-NET-SUMMARY
      *         INTO :SUM-SETTLE-DATE, :SUM-INST-CD,
      *              :SUM-INST-NAME,
      *              :SUM-TOT-IN,      :SUM-TOT-OUT,
      *              :SUM-NET-AMT,     :SUM-TOT-FEE,
      *              :SUM-TOT-CNT
      *    END-EXEC.
       KS_JAVA_START
       dao.select_01(dto);
       KS_JAVA_END

           EVALUATE SQLCODE
               WHEN 0
                   PERFORM WRITE-DATA-000
               WHEN 100
                   SET WS-EOF             TO TRUE
               WHEN OTHER
                   MOVE SQLCODE           TO ERR-SQLCODE
                   MOVE 'CURSOR FETCH ERROR' TO ERR-DESCRIPTION
                   PERFORM SYSTEM-ERROR-000
                   SET BATCH-ERROR TO TRUE
                   MOVE SYS-RET-CODE TO RETURN-CODE
                   STOP RUN
           END-EVALUATE.
       PROCESS-999.
           EXIT.

      *----------------------------------------------------------------*
      * WRITE-HEADER                  SECTION.
      *----------------------------------------------------------------*
       WRITE-HEADER                   SECTION.
       WRITE-HEADER-000.
      * --- FILE-CTRL (REDEFINES) ? ??? Header ?? ?? ---
           MOVE SPACES                TO OUT-REC.
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
      * --- ????? ??: STRING?? REC-KEY? ?? ?? ---
           STRING 'D'                          DELIMITED BY SIZE
                  SUM-SETTLE-DATE              DELIMITED BY SIZE
                  FUNCTION CURRENT-DATE(1:14)  DELIMITED BY SIZE
                  SUM-INST-CD                  DELIMITED BY SIZE
               INTO REC-KEY
           END-STRING.

      * --- ??? MOVE ? INSPECT CONVERTING ?? ??? ??? ---
           MOVE SUM-INST-NAME         TO OUT-INST-NAME.
           INSPECT OUT-INST-NAME
               CONVERTING 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
                        TO 'abcdefghijklmnopqrstuvwxyz'.

      * --- ?????? ?? ---
           MOVE SUM-TOT-IN            TO OUT-TOT-IN.
           MOVE SUM-TOT-OUT           TO OUT-TOT-OUT.
           MOVE SUM-NET-AMT           TO OUT-NET-AMT.
           MOVE SUM-TOT-FEE           TO OUT-TOT-FEE.
           MOVE SUM-TOT-CNT           TO OUT-TOTAL-CNT.
           WRITE OUT-REC.

      * --- DISPLAY ??: ?????? ??? ? ?? ---
           MOVE SUM-TOT-IN            TO ED-TOT-IN.
           MOVE SUM-TOT-OUT           TO ED-TOT-OUT.
           MOVE SUM-NET-AMT           TO ED-NET-AMT.
           MOVE SUM-TOT-FEE           TO ED-TOT-FEE.
           DISPLAY ' > [DATA]'
                   ' KEY=['   REC-KEY ']'
                   ' NAME='   OUT-INST-NAME
                   ' IN='     ED-TOT-IN
                   ' OUT='    ED-TOT-OUT
                   ' NET='    ED-NET-AMT
                   ' FEE='    ED-TOT-FEE.

      * --- ??? ??�E?? ?? ---
           ADD 1                      TO WS-CALC-CNT.
           ADD SUM-TOT-IN             TO WS-CALC-IN.
           ADD SUM-TOT-OUT            TO WS-CALC-OUT.
           ADD SUM-NET-AMT            TO WS-CALC-AMT.
           ADD SUM-TOT-FEE            TO WS-CALC-FEE.

      * --- ?? ?? (WS-PROGRESS-INTERVAL ???) ---
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
      *    EXEC SQL CLOSE C-NET-SUMMARY END-EXEC.

      * --- Trailer ���R�[�h�o�� ---
           PERFORM WRITE-TRAILER-000.

      * --- ?? ?? CLOSE ---
           CLOSE OUT-FILE.

      * --- ?? ?? ?? ?? ---
           PERFORM BATCHLOG-END-000.
      *    EXEC SQL COMMIT            END-EXEC.

      * --- DB ?? ?? ---
      *    EXEC SQL DISCONNECT CURRENT END-EXEC.

      * --- ?? ?? DISPLAY ---
           MOVE WS-CALC-AMT           TO ED-CALC-AMT.
           DISPLAY ' > ========= PGM-PHASE4 RESULT ========='.
           DISPLAY ' > DATA WRITTEN : '  WS-CALC-CNT.
           DISPLAY ' > TOTAL IN AMT : '  WS-CALC-IN.
           DISPLAY ' > TOTAL OUT AMT: '  WS-CALC-OUT.
           DISPLAY ' > TOTAL FEE AMT: '  WS-CALC-FEE.
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
      * --- FILE-CTRL (REDEFINES) ? ??? Trailer ?? ?? ---
           MOVE SPACES                TO OUT-REC.
           MOVE 'T'                   TO REC-TYPE.
           MOVE WS-CALC-CNT           TO TRL-TOT-CNT.
           MOVE WS-CALC-AMT           TO TRL-TOT-AMT.
           STRING REC-TYPE            DELIMITED BY SIZE
                  SPACE               DELIMITED BY SIZE
                  TRL-TOT-CNT         DELIMITED BY SIZE
                  SPACE               DELIMITED BY SIZE
                  TRL-TOT-AMT         DELIMITED BY SIZE
               INTO OUT-REC
           END-STRING.
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
      * TB_BATCH_LOG : ?? ?? ?? INSERT (STAT='R')
      *----------------------------------------------------------------*
       BATCHLOG-START                 SECTION.
       BATCHLOG-START-000.
           MOVE WS-PROG-NAME          TO BLG-PGM-ID.
           MOVE SYS-BIZ-DATE          TO BLG-BIZ-DATE.
           MOVE WS-START-DATETIME     TO BLG-START-DT.
           MOVE 'PHASE4 STARTED'      TO BLG-REMARK.
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
           MOVE WS-CALC-CNT           TO BLG-PROC-CNT.
           MOVE WS-ERR-CNT            TO BLG-ERR-CNT.
           MOVE 'END  '               TO BLG-ACTION.

           IF WS-ERR-CNT > 0 THEN
               MOVE 'E'               TO BLG-STAT
               MOVE 'PHASE4 COMPLETED WITH ERRORS' TO BLG-REMARK
           ELSE
               MOVE 'S'               TO BLG-STAT
               MOVE 'PHASE4 COMPLETED SUCCESSFULLY' TO BLG-REMARK
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
           DISPLAY 'KEY: ['     REC-KEY ']'.
       DB-ERROR-999.
           EXIT.
      *================================================================*
      * END OF PGM-PHASE4
      *================================================================*
      
