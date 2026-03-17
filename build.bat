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

:: ============================================================
:: 1-0. BLOGSVR : 배치 이력 서브프로그램 (PHASE1보다 먼저 빌드)
:: ============================================================
echo [0/4] BLOGSVR: [BATCH LOG SERVICE] BUILD
echo ------------------------------------------------------------
echo  ^> Precompiling %SRC_DIR%\PGM-BLOGSVR.CBL...
gixpp -e -I"%COPY_DIR%" -I"%SRC_DIR%" -i "%SRC_DIR%\PGM-BLOGSVR.CBL" -o "%SRC_DIR%\PGM-BLOGSVR.COB"
if %ERRORLEVEL% NEQ 0 goto :ERROR_EXIT

echo  ^> Compiling: %SRC_DIR%\PGM-BLOGSVR.COB...
cobc -m -fixed -I"%COPY_DIR%" -o "%BIN_DIR%\PGM-BLOGSVR.dll" "%SRC_DIR%\PGM-BLOGSVR.COB" -L"%BIN_DIR%" -lsqlite3
if %ERRORLEVEL% NEQ 0 goto :ERROR_EXIT
echo  ^> BLOGSVR build OK.
echo.

:: ============================================================
:: 2. PHASE 1 : FILE to FILE (EXEC SQL 없음, gixpp 불필요)
::    cobc 직접 컴파일 / CALL 'PGM-BLOGSVR' 링크를 위해 BIN_DIR 지정
:: ============================================================
echo [1/4] PHASE 1: [FILE to FILE] START
echo ------------------------------------------------------------
echo  ^> Compiling: %SRC_DIR%\PGM-PHASE1.CBL...
cobc -x -I"%COPY_DIR%" -o "%BIN_DIR%\PGM-PHASE1.exe" "%SRC_DIR%\PGM-PHASE1.CBL"
@REM cobc -x -fixed -I"%COPY_DIR%" -o "%BIN_DIR%\PGM-PHASE1.exe" "%SRC_DIR%\PGM-PHASE1.CBL" -L"%BIN_DIR%"
if %ERRORLEVEL% NEQ 0 goto :ERROR_EXIT

:: File needed for PHASE-1
set "DD_INFILE_VAR=%RAW_DIR%\RAW_TRX_DATA.txt"
set "DD_OUTFILE_VAR=%DATA_DIR%\CLEANSED_DATA.txt"
set "DD_ERRFILE_VAR=%DATA_DIR%\ERROR_DATA.txt"

echo  ^> Running %BIN_DIR%\PGM-PHASE1.exe...
echo.
"%BIN_DIR%\PGM-PHASE1.exe"
if %ERRORLEVEL% NEQ 0 (
    echo  ^> [RC=%ERRORLEVEL%] PGM-PHASE1 ABEND. BATCH STOPPED.
    goto :ERROR_EXIT
)
echo.

:: ============================================================
:: 3. PHASE 2 : FILE to DB (SQL COBOL)
:: ============================================================
echo [2/4] PHASE 2: [FILE to DATABASE] START
echo ------------------------------------------------------------
echo  ^> Precompiling %SRC_DIR%\PGM-PHASE2.CBL...
gixpp -e -I"%COPY_DIR%" -I"%COPY_DIR%" -I"%SRC_DIR%" -i "%SRC_DIR%\PGM-PHASE2.CBL" -o "%SRC_DIR%\PGM-PHASE2.COB"
if %ERRORLEVEL% NEQ 0 goto :ERROR_EXIT

echo  ^> Compiling %SRC_DIR%\PGM-PHASE2.COB...
cobc -x -fixed -I"%COPY_DIR%" -o "%BIN_DIR%\PGM-PHASE2.exe" "%SRC_DIR%\PGM-PHASE2.COB" -L"%BIN_DIR%" -lsqlite3
if %ERRORLEVEL% NEQ 0 goto :ERROR_EXIT

set "DD_INFILE_VAR=%DATA_DIR%\CLEANSED_DATA.txt"
echo  ^> Running %BIN_DIR%\PGM-PHASE2.exe...
echo.
"%BIN_DIR%\PGM-PHASE2.exe"
if %ERRORLEVEL% NEQ 0 (
    echo  ^> [RC=%ERRORLEVEL%] PGM-PHASE2 ABEND. BATCH STOPPED.
    goto :ERROR_EXIT
)
echo.

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
if %ERRORLEVEL% NEQ 0 (
    echo  ^> [RC=%ERRORLEVEL%] PGM-PHASE3 ABEND. BATCH STOPPED.
    goto :ERROR_EXIT
)
echo.

:: ============================================================
:: 5. PHASE 4 : DB to FILE (SQL COBOL)
:: ============================================================
echo [4/4] PHASE 4: [DATABASE to FILE] START
echo ------------------------------------------------------------
echo  ^> Precompiling %SRC_DIR%\PGM-PHASE4.CBL...
gixpp -e -I"%COPY_DIR%" -I"%COPY_DIR%" -I"%SRC_DIR%" -i "%SRC_DIR%\PGM-PHASE4.CBL" -o "%SRC_DIR%\PGM-PHASE4.COB"
if %ERRORLEVEL% NEQ 0 goto :ERROR_EXIT

echo  ^> Compiling %SRC_DIR%\PGM-PHASE4.COB...
cobc -x -fixed -I"%COPY_DIR%" -o "%BIN_DIR%\PGM-PHASE4.exe" "%SRC_DIR%\PGM-PHASE4.COB" -L"%BIN_DIR%" -lsqlite3
if %ERRORLEVEL% NEQ 0 goto :ERROR_EXIT

set "DD_OUTFILE_VAR=%DATA_DIR%\SEND_DATA.txt"
echo  ^> Running %BIN_DIR%\PGM-PHASE4.exe...
echo.
"%BIN_DIR%\PGM-PHASE4.exe"
if %ERRORLEVEL% NEQ 0 (
    echo  ^> [RC=%ERRORLEVEL%] PGM-PHASE4 ABEND. BATCH STOPPED.
    goto :ERROR_EXIT
)
echo.

:: ============================================================
:: End of Batch
:: ============================================================
echo ============================================================
echo    ALL BATCH PROGRAMS COMPLETED SUCCESSFULLY
echo ============================================================
exit /b 0

:ERROR_EXIT
echo.
echo !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
echo  [FATAL ERROR] FAILED AT %TIME%
echo  CHECK COMPILER LOGS IN THE BATCH FOLDER.
echo !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
exit /b 1