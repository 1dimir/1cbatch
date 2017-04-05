@ECHO OFF

:: set up codepage
@CHCP 65001 > Nul

IF [%1]==[/?] GOTO :Usage
IF [%1]==[] GOTO :Usage

:: Home
SET Home=%~dp0

SET Version=%~1

FOR /F "tokens=* USEBACKQ" %%F IN (`powershell "[guid]::NewGuid().ToString().Trim()"`) DO (
    SET "ROOT=%TEMP%\%%F"
)

IF NOT DEFINED ROOT (
    EXIT /B 100
)

IF EXIST %ROOT% (
    EXIT /B 200
) ELSE (
    MKDIR %ROOT%\db
)

SET LOG=%ROOT%\log.txt

:: log script name
CALL :LOG %LOG% %0

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

SET CfFile="%Home:"=%\cf\%Version%.cf"

IF NOT EXIST %CfFile% (
    CALL :LOG %LOG% "%CfFile% not found"
    GOTO :CLEANUP
)

SET Exportdir="%Home:"=%\dumps\%Version%"

:: create temporary infobase
%EXE% DESIGNER ^
/IBConnectionString "File=""%ROOT%\db"";" ^
/RestoreIB ^
/Out %LOG% -NoTruncate

CALL :LOG %LOG% "temporaty infobase %ROOT%\db created"

:: load cf
%EXE% DESIGNER ^
/IBConnectionString "File=""%ROOT%\db"";" ^
/LoadCfg %CfFile% ^
/Out %LOG% -NoTruncate

CALL :LOG %LOG% "Configuration loaded"

:: create export dir if not exist
IF NOT EXIST %Exportdir% (
    MKDIR %ExportDir%
    CALL :LOG %LOG% "%ExportDir% created"
)

:: dump to files
%EXE% DESIGNER ^
/IBConnectionString "File=""%ROOT%\db"";" ^
/DumpConfigToFiles %ExportDir% ^
/Out %LOG% -NoTruncate

CALL :LOG %LOG% "Configuration parsed to %ExportDir%"

:CLEANUP

CALL :LOG %LOG% "cleanup started"

TYPE %LOG% 
TYPE %LOG% >> %~dp0%~n0.log

RMDIR /S /Q %ROOT%

EXIT /B %ERRORLEVEL%

:Usage

ECHO Usage: %~n0 ^<version^>
ECHO;
ECHO Parses specified configuration of specified version
ECHO;
ECHO Repository access parameters and path to 1c binaries must be specified in config.ini 
ECHO It must contain EXE variable setting
ECHO;
ECHO Sample:
ECHO EXE="C:\Program Files (x86)\1cv8\8.3.9.1850\bin\1cv8.exe"

EXIT /B 1

:LOG

ECHO %date:~6%.%date:~3,2%.%date:~0,2% %time:~0,2%:%time:~3,2%:%time:~6,2%.%time:~9% %~2 >> %1

EXIT /B 0
