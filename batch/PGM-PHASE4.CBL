      *================================================================*
      * PGM-PHASE4.cbl - DB to File
      * 1. DB 데이터를 읽어 55 Bytes 파일 생성
      * 2. FILE-CTRL(REDEFINES)를 활용하여 Header 및 Trailer 동적 생성
      * 3. 서식형변수(Edited Data Item)를 활용한 금액/날짜 편집 출력
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
       01  OUT-REC                    PIC X(55).

      * --- 출력 파일 데이터 레이아웃 (55 Bytes) ---
       01  DATA-REC REDEFINES OUT-REC.
           05 OUT-SETTLE-DATE   PIC X(8).
           05 OUT-INST-CD       PIC X(4).
           05 OUT-TOT-IN        PIC 9(15).
           05 OUT-TOT-OUT       PIC 9(15).
           05 OUT-NET-AMT       PIC -9(12).

       WORKING-STORAGE SECTION.
      * --- 시스템 공통 영역 및 에러 로그 Include ---
           COPY SYS-COM.
           COPY ERR-LOG.
           COPY FILE-CTRL.

      * --- SQLCA 및 DB DCLGEN Include ---
           EXEC SQL INCLUDE SQLCA END-EXEC.
           EXEC SQL INCLUDE SQL-DCLGEN END-EXEC.

      * --- 제어 변수 및 대사 변수 ---
       01  WS-OUT-STAT                PIC X(2).
       01  WS-EOF-FLAG                PIC X(1) VALUE 'N'.
           88 EOF-TRUE                         VALUE 'Y'.
           88 EOF-FALSE                        VALUE 'N'.

       01  WS-CALC-TOTALS.
           05 WS-CALC-CNT             PIC 9(10) VALUE 0.
           05 WS-CALC-AMT             PIC S9(15) VALUE 0.
       01  WS-BIZ-DATE-W              PIC X(8).
       
       01 WS-DATASRC                  PIC X(30)
                                      VALUE 'SB_VaF_Education_JP.db'.
       01 WS-USER                     PIC X(10) VALUE 'gixsql'.
       01 WS-PWD                      PIC X(10) VALUE 'gixsql'.

      * --- 서식형변수 (Edited Data Item) 정의 ---
       01  WS-EDIT-AREA.
           05 ED-TOT-IN               PIC -Z,ZZZ,ZZZ,ZZ9.
           05 ED-TOT-OUT              PIC -Z,ZZZ,ZZZ,ZZ9.
           05 ED-NET-AMT              PIC -Z,ZZZ,ZZZ,ZZ9.
           05 ED-SETTLE-DATE          PIC 9999/99/99.
           05 ED-CALC-AMT             PIC -$,$$$,$$$,$$$,$$9.

      * --- SQL CURSOR 선언 ---
           EXEC SQL
               DECLARE C-NET-SUMMARY CURSOR FOR
               SELECT SETTLE_DATE, INST_CD,
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
       MAIN                          SECTION.
       MAIN-000.
           PERFORM INIT-000.
           PERFORM PROCESS-000 UNTIL EOF-TRUE.
           PERFORM FINALIZE-000.
       MAIN-999.
           STOP RUN.
      *----------------------------------------------------------------*
      * INIT                          SECTION.
      *----------------------------------------------------------------*
       INIT                          SECTION.
       INIT-000.
           MOVE 'PHASE4'                    TO SYS-JOB-ID.
           MOVE FUNCTION CURRENT-DATE       TO SYS-BIZ-DATE.
           MOVE SYS-BIZ-DATE                TO WS-BIZ-DATE-W.

           OPEN OUTPUT OUT-FILE.
           IF WS-OUT-STAT NOT = '00'
               MOVE 'OUTPUT FILE OPEN ERROR' TO ERR-DESCRIPTION
               PERFORM SYSTEM-ERROR-000
           END-IF.

           EXEC SQL
               CONNECT :WS-USER IDENTIFIED BY :WS-PWD
                       USING :WS-DATASRC
           END-EXEC.
           IF SQLCODE NOT = 0
               DISPLAY 'DB CONNECT FAILED: ' SQLCODE
               STOP RUN
           END-IF.

           EXEC SQL OPEN C-NET-SUMMARY END-EXEC.
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
                     :SUM-TOT-IN, :SUM-TOT-OUT, :SUM-NET-AMT
           END-EXEC.

           EVALUATE SQLCODE
               WHEN 0
                   PERFORM WRITE-DATA-000
               WHEN 100
                   SET EOF-TRUE       TO TRUE
               WHEN OTHER
                   MOVE SQLCODE       TO ERR-SQLCODE
                   MOVE 'FETCH ERROR' TO ERR-DESCRIPTION
                   PERFORM SYSTEM-ERROR-000
           END-EVALUATE.
       PROCESS-999.
           EXIT.
      *----------------------------------------------------------------*
      * WRITE-DATA                    SECTION.
      *----------------------------------------------------------------*
       WRITE-DATA                     SECTION.
       WRITE-DATA-000.
      * --- [파일 출력] 수치형 변수 그대로 OUT-REC에 MOVE ---
           MOVE SUM-SETTLE-DATE  TO OUT-SETTLE-DATE.
           MOVE SUM-INST-CD      TO OUT-INST-CD.
           MOVE SUM-TOT-IN       TO OUT-TOT-IN.
           MOVE SUM-TOT-OUT      TO OUT-TOT-OUT.
           MOVE SUM-NET-AMT      TO OUT-NET-AMT.
           WRITE OUT-REC.
      * --- [DISPLAY 출력] 서식형변수에 MOVE 후 편집된 값을 표시 ---
           MOVE SUM-SETTLE-DATE  TO ED-SETTLE-DATE.
           MOVE SUM-TOT-IN       TO ED-TOT-IN.
           MOVE SUM-TOT-OUT      TO ED-TOT-OUT.
           MOVE SUM-NET-AMT      TO ED-NET-AMT.

      *    DISPLAY '[DATA] DATE: ' ED-SETTLE-DATE
      *            '  CODE: '        SUM-INST-CD
      *            '  IN: '          ED-TOT-IN
      *            '  OUT: '         ED-TOT-OUT
      *            '  NET: '         ED-NET-AMT.

      * --- 대사를 위한 건수 및 금액 누적 ---
           ADD 1                 TO WS-CALC-CNT.
           ADD SUM-NET-AMT       TO WS-CALC-AMT.
       WRITE-DATA-999.
           EXIT.
      *----------------------------------------------------------------*
      * FINALIZE                      SECTION.
      *----------------------------------------------------------------*
       FINALIZE                       SECTION.
       FINALIZE-000.
           EXEC SQL CLOSE C-NET-SUMMARY END-EXEC.
           EXEC SQL DISCONNECT END-EXEC.

           CLOSE OUT-FILE.
      
           MOVE WS-CALC-AMT TO ED-CALC-AMT.
      * --- [FINALIZE DISPLAY] 합계 금액도 서식형변수로 편집 출력 ---
           DISPLAY ' > ========= PGM-PHASE4 RESULT ========='.
      *    DISPLAY ' > [PHASE 4] DB TO FILE BATCH COMPLETED'.
           DISPLAY ' > DATA WRITTEN : ' WS-CALC-CNT.
           DISPLAY ' > TOTAL NET AMT: ' ED-CALC-AMT.
           DISPLAY ' > ====================================='.
       FINALIZE-999.
           EXIT.
      *----------------------------------------------------------------*
      * SYSTEM-ERROR                  SECTION.
      *----------------------------------------------------------------*
       SYSTEM-ERROR                   SECTION.
       SYSTEM-ERROR-000.
           MOVE 'PGM-PHASE4' TO ERR-PGM-ID.
           SET ERR-FATAL     TO TRUE.
           DISPLAY '*** SYSTEM ERROR *** MSG: ' ERR-DESCRIPTION.
           STOP RUN.
       SYSTEM-ERROR-999.
           EXIT.
      *================================================================*
      * END OF PGM-PHASE4
      *================================================================*
