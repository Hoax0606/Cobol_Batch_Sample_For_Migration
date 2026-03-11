@echo off
setlocal enabledelayedexpansion

:: ============================================================
:: 1. ?? ? ?? ??
:: ============================================================
set "BASE_DIR=%~dp0"
set "BIN_DIR=%BASE_DIR%bin"
set "COPY_DIR=%BASE_DIR%copy"
set "SRC_DIR=%BASE_DIR%batch"
set "DATA_DIR=%BASE_DIR%data_createdFromBatch"
set "RAW_DIR=%BASE_DIR%data_received"
set "DB_TYPE=sqlite"
set "DB_CONN=sqlite://SB_VaF_Education_JP.db"

:: DLL ? ?? ?? ??? ?? PATH? bin ??
set "PATH=%BIN_DIR%;%PATH%"

:: GnuCOBOL ???? ?? ??(.dll)? ?? ? ??? ?? ??
set "COB_LIBRARY_PATH=%BIN_DIR%"

:: GixSQL ? COBOL ????? ?? ??
set "GIX_LIB=C:\GixSQL\lib\copy"

:: DB ?? ??? ?? ?? ??
set GIXSQL_DEFAULT_DRIVER=%DB_TYPE%
set GIXSQL_DB_CONN=%DB_CONN%

:: ?? ?? ??? ??
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
:: 2. PHASE 1 : FILE to FILE (Standard COBOL)
:: ============================================================
echo [1/4] PHASE 1: [FILE to FILE] START
echo ------------------------------------------------------------
echo  ^> Compiling: %SRC_DIR%\PGM-PHASE1.CBL...
:: -I ???? copy ?? ??
cobc -x -I"%COPY_DIR%" -o "%BIN_DIR%\PGM-PHASE1.exe" "%SRC_DIR%\PGM-PHASE1.CBL"
if %ERRORLEVEL% NEQ 0 goto :ERROR_EXIT

:: GnuCOBOL ?? ?? ??(DD_)? ??? ?????.
set "DD_INFILE_VAR=%RAW_DIR%\RAW_TRX_DATA.txt"
set "DD_OUTFILE_VAR=%DATA_DIR%\CLEANSED_DATA.txt"
set "DD_ERRFILE_VAR=%DATA_DIR%\ERROR_DATA.txt"

echo  ^> Running %BIN_DIR%\PGM-PHASE1.exe...
echo.
"%BIN_DIR%\PGM-PHASE1.exe"
echo.

:: ============================================================
:: 3. PHASE 2 : FILE to DB (SQL COBOL)
:: ============================================================
echo [2/4] PHASE 2: [FILE to DATABASE] START
echo ------------------------------------------------------------
echo  ^> Precompiling %SRC_DIR%\PGM-PHASE2.CBL...
gixpp -e -I"%GIX_LIB%" -I"%COPY_DIR%" -I"%SRC_DIR%" -i "%SRC_DIR%\PGM-PHASE2.CBL" -o "%SRC_DIR%\PGM-PHASE2.COB"
if %ERRORLEVEL% NEQ 0 goto :ERROR_EXIT

echo  ^> Compiling %SRC_DIR%\PGM-PHASE2.COB...
:: -L. ? ?? ???? dll? ??, ??? -L"%BIN_DIR%" ??
cobc -x -fixed -I"%COPY_DIR%" -o "%BIN_DIR%\PGM-PHASE2.exe" "%SRC_DIR%\PGM-PHASE2.COB" -L"%BIN_DIR%" -lsqlite3
if %ERRORLEVEL% NEQ 0 goto :ERROR_EXIT

set "DD_INFILE_VAR=%DATA_DIR%\CLEANSED_DATA.txt"
echo  ^> Running %BIN_DIR%\PGM-PHASE2.exe...
echo.
"%BIN_DIR%\PGM-PHASE2.exe"
echo.

:: ============================================================
:: 4. PHASE 3 : DB to DB (SQL COBOL)
:: ============================================================
echo [3/4] PHASE 3: [DATABASE to DATABASE] START
echo ------------------------------------------------------------
echo  ^> Precompiling %SRC_DIR%\PGM-PHASE3.CBL...
gixpp -e -I"%GIX_LIB%" -I"%COPY_DIR%" -I"%SRC_DIR%" -i "%SRC_DIR%\PGM-PHASE3.CBL" -o "%SRC_DIR%\PGM-PHASE3.COB"
if %ERRORLEVEL% NEQ 0 goto :ERROR_EXIT

echo  ^> Compiling %SRC_DIR%\PGM-PHASE3.COB...
cobc -x -fixed -I"%COPY_DIR%" -o "%BIN_DIR%\PGM-PHASE3.exe" "%SRC_DIR%\PGM-PHASE3.COB" -L"%BIN_DIR%" -lsqlite3
if %ERRORLEVEL% NEQ 0 goto :ERROR_EXIT

echo  ^> Running %BIN_DIR%\PGM-PHASE3.exe...
echo.
"%BIN_DIR%\PGM-PHASE3.exe"
echo.

:: ============================================================
:: 5. PHASE 4 : DB to FILE (SQL COBOL)
:: ============================================================
echo [4/4] PHASE 4: [DATABASE to FILE] START
echo ------------------------------------------------------------
echo  ^> Precompiling %SRC_DIR%\PGM-PHASE4.CBL...
gixpp -e -I"%GIX_LIB%" -I"%COPY_DIR%" -I"%SRC_DIR%" -i "%SRC_DIR%\PGM-PHASE4.CBL" -o "%SRC_DIR%\PGM-PHASE4.COB"
if %ERRORLEVEL% NEQ 0 goto :ERROR_EXIT

echo  ^> Compiling %SRC_DIR%\PGM-PHASE4.COB...
cobc -x -fixed -I"%COPY_DIR%" -o "%BIN_DIR%\PGM-PHASE4.exe" "%SRC_DIR%\PGM-PHASE4.COB" -L"%BIN_DIR%" -lsqlite3
if %ERRORLEVEL% NEQ 0 goto :ERROR_EXIT

set "DD_OUTFILE_VAR=%DATA_DIR%\SEND_DATA.txt"
echo  ^> Running %BIN_DIR%\PGM-PHASE4.exe...
echo.
"%BIN_DIR%\PGM-PHASE4.exe"
echo.

:: ============================================================
:: ???
:: ============================================================
echo ============================================================
echo    ALL BATCH PROGRAMS COMPLETED SUCCESSFULLY
echo ============================================================
pause
exit /b 0

:ERROR_EXIT
echo.
echo !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
echo  [FATAL ERROR] FAILED AT %TIME%
echo  CHECK COMPILER LOGS IN THE BATCH FOLDER.
echo !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
pause
exit /b 1
