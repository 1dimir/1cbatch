@ECHO OFF

:: set up codepage
@CHCP 65001 > Nul

IF [%1]==[] GOTO :Usage
IF [%1]==[/?] GOTO :Usage
IF [%1]==[-h] GOTO :Usage

SET EPF="%~dpnx1"
SET SRC="%~dp1src"

:: initialize temporary folder name in %TEMP% with GUID
FOR /F "tokens=* USEBACKQ" %%F IN (`powershell "[guid]::NewGuid().ToString().Trim()"`) DO (
    SET "ROOT=%TEMP%\%%F"
)

MKDIR %ROOT%\db

SET LOG=%ROOT%\log.txt

:: log script name
CALL :LOG %LOG% "%~0 %*"

:: read config
SET CONFIG=%~d0%~p0config.ini

IF NOT EXIST %CONFIG% (
    CALL :LOG %LOG% "config.ini not found"
    GOTO :CLEANUP
)

CALL :LOG %LOG% "config.ini located"

FOR /F "tokens=*" %%A IN ('TYPE "%CONFIG%"') DO SET %%A

IF NOT DEFINED EXE (
    CALL :LOG %LOG% "EXE is not set in config.ini"
    GOTO :CLEANUP
)

CALL :LOG %LOG% "Settings read"

SET EPF="%~dpnx1"
SET SRC="%~dp1src"

IF NOT EXIST %SRC% (
    MKDIR %SRC% && CALL :LOG %LOG% "%SRC:"='% folder created"
)

:: create temporary infobase
%EXE% DESIGNER ^
/DisableStartupDialogs ^
/DisableStartupMessages ^
/IBConnectionString "File=""%ROOT%\db"";" ^
/RestoreIB ^
/Out %LOG% -NoTruncate ^
&& CALL :LOG %LOG% "temporaty infobase %ROOT:"=%\db created" ^
|| GOTO :CLEANUP

%EXE% DESIGNER ^
/DisableStartupDialogs ^
/DisableStartupMessages ^
/IBConnectionString "File=""%ROOT%\db"";" ^
/DumpExternalDataProcessorOrReportToFiles %SRC% %EPF% -Format Hierarchical ^
/Out %LOG% -NoTruncate ^
&& CALL :LOG %LOG% "File %EPF:"='% successfully parsed to %SRC:"='%" ^
|| GOTO :CLEANUP

:CLEANUP

CALL :LOG %LOG% "cleanup started"

TYPE %LOG% 
TYPE %LOG% >> %~dp0%~n0.log

RMDIR /S /Q %ROOT% > Nul

EXIT /B 0

:Usage

ECHO Usage: %~nx0 ^<external_data_processor.epf^>
ECHO;
ECHO Dumps specified external data procesor or report to files into src directory
ECHO;
ECHO Path to 1c binaries must be specified in config.ini 
ECHO Sample:
ECHO EXE="C:\Program Files (x86)\1cv8\8.3.9.1850\bin\1cv8.exe"

EXIT /B 1

:LOG

ECHO %date:~6%.%date:~3,2%.%date:~0,2% %time:~0,2%:%time:~3,2%:%time:~6,2%.%time:~9% %~2 >> %1

EXIT /B 0
