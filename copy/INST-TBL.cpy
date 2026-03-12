      *================================================================*
      * [INST-TBL.cpy] 기관코드 마스터 테이블 (메모리 테이블)
      * SEARCH ALL 사용을 위해 ASCENDING KEY 정렬 유지 필수
      *================================================================*
      * --- 기관코드 마스터 테이블 (메모리 로드용) ---
       01  INST-MASTER-TABLE.
           05 INST-MAX-CNT           PIC 9(4)  VALUE 0.
           05 INST-ENTRY OCCURS 100 TIMES
                         ASCENDING KEY IS INST-TBL-CD
                         INDEXED BY INST-IDX.
              10 INST-TBL-CD        PIC X(4).
              10 INST-TBL-NAME      PIC X(20).
              10 INST-TBL-STAT      PIC X(1).
                 88 INST-ACTIVE     VALUE 'A'.
                 88 INST-INACTIVE   VALUE 'I'.

      * --- SEARCH ALL 결과 저장용 ---
       01  WS-INST-FOUND-FLAG        PIC X(1)  VALUE 'N'.
              88 INST-FOUND          VALUE 'Y'.
              88 INST-NOT-FOUND      VALUE 'N'.

      * --- DCL: TB_INST_MASTER ---
       01  DCL-TB-INST-MASTER.
           05 MST-INST-CD            PIC X(4).
           05 MST-INST-NAME          PIC X(20).
           05 MST-INST-STAT          PIC X(1).
