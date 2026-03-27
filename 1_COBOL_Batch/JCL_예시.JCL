//PHASEJOB JOB (ACCT),'PHASE BATCH',
//             CLASS=A,
//             MSGCLASS=X,
//             MSGLEVEL=(1,1),
//             NOTIFY=&SYSUID
//*
//*------------------------------------------------------------*
//* DB 접속 정보 (build.bat의 GIXSQL 환경변수 대응)
//*------------------------------------------------------------*
//DBSET    SET DBCONN='sqlite://SB_VaF_Education_JP.db',
//             DBUSER='gixsql',
//             DBPWD='gixsql'
//*
//*------------------------------------------------------------*
//* STEP1: PHASE1 - FILE TO FILE
//*------------------------------------------------------------*
//STEP1    EXEC PGM=PGM-PHASE1
//STEPLIB  DD  DSN=BATCH.LOAD.LIB,DISP=SHR
//INFILE   DD  DSN=RAW.TRX.DATA,          ← build.bat DD_INFILE_VAR
//             DISP=SHR
//OUTFILE  DD  DSN=CLEANSED.DATA,          ← build.bat DD_OUTFILE_VAR
//             DISP=(NEW,CATLG,DELETE)
//ERRFILE  DD  DSN=ERROR.DATA,             ← build.bat DD_ERRFILE_VAR
//             DISP=(NEW,CATLG,DELETE)
//SYSOUT   DD  SYSOUT=*
//*
//*------------------------------------------------------------*
//* STEP2: PHASE2 - FILE TO DB
//*------------------------------------------------------------*
//STEP2    EXEC PGM=PGM-PHASE2,
//             COND=(0,NE,STEP1)           ← STEP1 RC≠0이면 스킵
//STEPLIB  DD  DSN=BATCH.LOAD.LIB,DISP=SHR
//INFILE   DD  DSN=CLEANSED.DATA,          ← STEP1 출력 파일
//             DISP=SHR
//DBCONN   DD  DSN=DB.CONNECT.INFO,DISP=SHR
//SYSOUT   DD  SYSOUT=*
//*
//*------------------------------------------------------------*
//* STEP3: PHASE3 - DB TO DB
//*------------------------------------------------------------*
//STEP3    EXEC PGM=PGM-PHASE3,
//             COND=(0,NE,STEP2)           ← STEP2 RC≠0이면 스킵
//STEPLIB  DD  DSN=BATCH.LOAD.LIB,DISP=SHR
//DBCONN   DD  DSN=DB.CONNECT.INFO,DISP=SHR
//SYSOUT   DD  SYSOUT=*
//*
//*------------------------------------------------------------*
//* STEP4: PHASE4 - DB TO FILE
//*------------------------------------------------------------*
//STEP4    EXEC PGM=PGM-PHASE4,
//             COND=(0,NE,STEP3)           ← STEP3 RC≠0이면 스킵
//STEPLIB  DD  DSN=BATCH.LOAD.LIB,DISP=SHR
//OUTFILE  DD  DSN=SEND.DATA,              ← build.bat DD_OUTFILE_VAR
//             DISP=(NEW,CATLG,DELETE)
//DBCONN   DD  DSN=DB.CONNECT.INFO,DISP=SHR
//SYSOUT   DD  SYSOUT=*