      *================================================================*
      * [ERR-LOG.cpy] ?? ??/?? ?? ??
      *================================================================*
       01  ERR-LOG-AREA.
           05 ERR-PGM-ID         PIC X(10) VALUE SPACES.
           05 ERR-PARA-NAME      PIC X(30) VALUE SPACES.
           05 ERR-SQLCODE        PIC S9(9) VALUE ZERO.
           05 ERR-FILE-STAT      PIC X(2)  VALUE SPACES.
           05 ERR-SEVERITY       PIC X(1)  VALUE SPACES.
              88 ERR-INFO        VALUE 'I'.
              88 ERR-WARN        VALUE 'W'.
              88 ERR-FATAL       VALUE 'F'.
           05 ERR-DESCRIPTION    PIC X(200) VALUE SPACES.
           