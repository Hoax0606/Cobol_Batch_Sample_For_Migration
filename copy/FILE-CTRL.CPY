      *================================================================*
      * [FILE-CTRL.cpy]  Header/Trailer (57 Bytes)
      *================================================================*
       01  FILE-CONTROL-REC.
           05 REC-TYPE           PIC X(1).
              88 IS-HEADER       VALUE 'H'.
              88 IS-DATA         VALUE 'D'.
              88 IS-TRAILER      VALUE 'T'.
           05 REC-CONTENT        PIC X(56).

      * --- Header Record  ---
       01  HEADER-REC REDEFINES FILE-CONTROL-REC.
           05 HDR-TYPE           PIC X(1).
           05 FILLER             PIC X(1).
           05 HDR-CREATE-DATE    PIC X(8).

      * --- Trailer Record ---
       01  TRAILER-REC REDEFINES FILE-CONTROL-REC.
           05 TRL-TYPE           PIC X(1).
           05 FILLER             PIC X(10).
           05 TRL-TOT-CNT        PIC 9(10).
           05 FILLER             PIC X(1).
           05 TRL-TOT-AMT        PIC 9(12).
           