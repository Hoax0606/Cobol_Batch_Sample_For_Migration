@echo off
setlocal enabledelayedexpansion

set "BASE_DIR=%~dp0"
set "BIN_DIR=%BASE_DIR%bin"
set "COPY_DIR=%BASE_DIR%copy"
set "SRC_DIR=%BASE_DIR%batch"
set "DATA_DIR=%BASE_DIR%data_createdFromBatch"
set "RAW_DIR=%BASE_DIR%data_received"
set "DB_TYPE=sqlite"
set "DB_CONN=sqlite://SB_VaF_Education_JP.db"

set "PATH=%BIN_DIR%;%PATH%"
set "COB_LIBRARY_PATH=%BIN_DIR%"
::set "GIX_LIB=C:\GixSQL\lib\copy"

:: DB Setting
:: DB Setting
set GIXSQL_DEFAULT_DRIVER=%DB_TYPE%
set GIXSQL_DB_CONN=%DB_CONN%
set GIXSQL_USER=gixsql
set GIXSQL_PWD=gixsql

:: create data_createdFromBatch
if not exist "%DATA_DIR%" (
    mkdir "%DATA_DIR%"
)

cls
echo ============================================================
echo    PGM-PHASE BATCH PROCESSOR
echo    SOURCE: %SRC_DIR% 
echo    COPY: %COPY_DIR%
echo    bin: %BIN_DIR%
echo    Raw Data Folder : %RAW_DIR%
echo    Created Data Folder : %DATA_DIR%
echo    DB TYPE : %DB_TYPE%
echo    DB CONN : %DB_CONN%
echo ============================================================
echo.

@REM :: ============================================================
@REM :: 2. PHASE 1 : FILE to FILE (Standard COBOL)
@REM :: ============================================================
@REM echo [1/4] PHASE 1: [FILE to FILE] START
@REM echo ------------------------------------------------------------
@REM echo  ^> Compiling: %SRC_DIR%\PGM-PHASE1.CBL...

@REM cobc -x -I"%COPY_DIR%" -o "%BIN_DIR%\PGM-PHASE1.exe" "%SRC_DIR%\PGM-PHASE1.CBL"
@REM if %ERRORLEVEL% NEQ 0 goto :ERROR_EXIT

@REM :: File needed for PHASE-1
@REM set "DD_INFILE_VAR=%RAW_DIR%\RAW_TRX_DATA.txt"
@REM set "DD_OUTFILE_VAR=%DATA_DIR%\CLEANSED_DATA.txt"
@REM set "DD_ERRFILE_VAR=%DATA_DIR%\ERROR_DATA.txt"

@REM echo  ^> Running %BIN_DIR%\PGM-PHASE1.exe...
@REM echo.
@REM "%BIN_DIR%\PGM-PHASE1.exe"
@REM echo.

@REM :: ============================================================
@REM :: 3. PHASE 2 : FILE to DB (SQL COBOL)
@REM :: ============================================================
@REM echo [2/4] PHASE 2: [FILE to DATABASE] START
@REM echo ------------------------------------------------------------
@REM echo  ^> Precompiling %SRC_DIR%\PGM-PHASE2.CBL...
@REM gixpp -e -I"%COPY_DIR%" -I"%COPY_DIR%" -I"%SRC_DIR%" -i "%SRC_DIR%\PGM-PHASE2.CBL" -o "%SRC_DIR%\PGM-PHASE2.COB"
@REM if %ERRORLEVEL% NEQ 0 goto :ERROR_EXIT

@REM echo  ^> Compiling %SRC_DIR%\PGM-PHASE2.COB...

@REM cobc -x -fixed -I"%COPY_DIR%" -o "%BIN_DIR%\PGM-PHASE2.exe" "%SRC_DIR%\PGM-PHASE2.COB" -L"%BIN_DIR%" -lsqlite3
@REM if %ERRORLEVEL% NEQ 0 goto :ERROR_EXIT

@REM set "DD_INFILE_VAR=%DATA_DIR%\CLEANSED_DATA.txt"
@REM echo  ^> Running %BIN_DIR%\PGM-PHASE2.exe...
@REM echo.
@REM "%BIN_DIR%\PGM-PHASE2.exe"
@REM echo.

:: ============================================================
:: 4. PHASE 3 : DB to DB (SQL COBOL)
:: ============================================================
echo [3/4] PHASE 3: [DATABASE to DATABASE] START
echo ------------------------------------------------------------
echo  ^> Precompiling %SRC_DIR%\PGM-PHASE3.CBL...
gixpp -e -I"%COPY_DIR%" -I"%COPY_DIR%" -I"%SRC_DIR%" -i "%SRC_DIR%\PGM-PHASE3.CBL" -o "%SRC_DIR%\PGM-PHASE3.COB"
if %ERRORLEVEL% NEQ 0 goto :ERROR_EXIT

echo  ^> Compiling %SRC_DIR%\PGM-PHASE3.COB...
cobc -x -fixed -I"%COPY_DIR%" -o "%BIN_DIR%\PGM-PHASE3.exe" "%SRC_DIR%\PGM-PHASE3.COB" -L"%BIN_DIR%" -lsqlite3
if %ERRORLEVEL% NEQ 0 goto :ERROR_EXIT

echo  ^> Running %BIN_DIR%\PGM-PHASE3.exe...
echo.
"%BIN_DIR%\PGM-PHASE3.exe"
echo.

@REM :: ============================================================
@REM :: 5. PHASE 4 : DB to FILE (SQL COBOL)
@REM :: ============================================================
@REM echo [4/4] PHASE 4: [DATABASE to FILE] START
@REM echo ------------------------------------------------------------
@REM echo  ^> Precompiling %SRC_DIR%\PGM-PHASE4.CBL...
@REM gixpp -e -I"%COPY_DIR%" -I"%COPY_DIR%" -I"%SRC_DIR%" -i "%SRC_DIR%\PGM-PHASE4.CBL" -o "%SRC_DIR%\PGM-PHASE4.COB"
@REM if %ERRORLEVEL% NEQ 0 goto :ERROR_EXIT

@REM echo  ^> Compiling %SRC_DIR%\PGM-PHASE4.COB...
@REM cobc -x -fixed -I"%COPY_DIR%" -o "%BIN_DIR%\PGM-PHASE4.exe" "%SRC_DIR%\PGM-PHASE4.COB" -L"%BIN_DIR%" -lsqlite3
@REM if %ERRORLEVEL% NEQ 0 goto :ERROR_EXIT

@REM set "DD_OUTFILE_VAR=%DATA_DIR%\SEND_DATA.txt"
@REM echo  ^> Running %BIN_DIR%\PGM-PHASE4.exe...
@REM echo.
@REM "%BIN_DIR%\PGM-PHASE4.exe"
@REM echo.

@REM :: ============================================================
@REM :: End of Batch
@REM :: ============================================================
@REM echo ============================================================
@REM echo    ALL BATCH PROGRAMS COMPLETED SUCCESSFULLY
@REM echo ============================================================
@REM pause
@REM exit /b 0

@REM :ERROR_EXIT
@REM echo.
@REM echo !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
@REM echo  [FATAL ERROR] FAILED AT %TIME%
@REM echo  CHECK COMPILER LOGS IN THE BATCH FOLDER.
@REM echo !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
@REM pause
@REM exit /b 1
