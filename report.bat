@ECHO OFF

Setlocal EnableDelayedExpansion

:: set up codepage
@CHCP 65001 > Nul

IF [%1]==[/?] GOTO :Usage
IF [%1]==[-h] GOTO :Usage

:: Home
SET Home=%~dp0

:: Initialize temporary folder name in %TEMP% with GUID
FOR /F "tokens=* USEBACKQ" %%F IN (`powershell "[guid]::NewGuid().ToString().Trim()"`) DO (
    SET ROOT="%TEMP:"=%\%%F"
)

MKDIR "%ROOT:"=%\db" > Nul || ECHO Failed to create temporary folder && EXIT /B 1

SET LOG="%ROOT:"=%\log.txt"

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

IF NOT DEFINED RepoPath (
    CALL :LOG %LOG% "RepoPath is not set in config.ini"
    GOTO :CLEANUP
)

IF NOT DEFINED RepoUser (
    CALL :LOG %LOG% "RepoUser is not set in config.ini"
    GOTO :CLEANUP
)

IF NOT DEFINED RepoPass (
    SET RepoPass=""
)

CALL :LOG %LOG% "Settings read"

SET ReportFile="%Home:"=%report.mxl"

:: create temporary infobase
%EXE% DESIGNER ^
/DisableStartupDialogs ^
/DisableStartupMessages ^
/IBConnectionString "File=""%ROOT:"=%\db"";" ^
/RestoreIB ^
/Out %LOG% -NoTruncate

CALL :LOG %LOG% "temporaty infobase %ROOT:"=%\db created"

IF EXIST "%Home:"=%version" (
    SET /P Version=<version
    SET /A Version=!Version: =! + 1
)

FOR /L %%x IN (1, 1, 10) DO (

    CALL :LOG %LOG% "Trying to get report from repository (%%x)"
        
    IF DEFINED Version (
        :: batch configurator call
        %EXE% DESIGNER ^
        /DisableStartupDialogs ^
        /DisableStartupMessages ^
        /IBConnectionString "File=""%ROOT:"=%\db"";" ^
        /ConfigurationRepositoryF "%RepoPath%" ^
        /ConfigurationRepositoryN "%RepoUser%" ^
        /ConfigurationRepositoryP "%RepoPass%" ^
        /ConfigurationRepositoryReport %ReportFile% -NBegin !Version! ^
        /Out %LOG% -NoTruncate ^
            && GOTO :SUCCESS 

    ) ELSE (
        :: batch configurator call
        %EXE% DESIGNER ^
        /DisableStartupDialogs ^
        /DisableStartupMessages ^
        /IBConnectionString "File=""%ROOT:"=%\db"";" ^
        /ConfigurationRepositoryF "%RepoPath%" ^
        /ConfigurationRepositoryN "%RepoUser%" ^
        /ConfigurationRepositoryP "%RepoPass%" ^
        /ConfigurationRepositoryReport %ReportFile% ^
        /Out %LOG% -NoTruncate ^
            && GOTO :SUCCESS 
    )
)

CALL :LOG %LOG% "Repository operation failed!"
GOTO :CLEANUP

:SUCCESS
  CALL :LOG %LOG% "Report saved %ReportFile%"
  
IF NOT EXIST %Home%commits (
    MKDIR %Home%commits
    CALL :LOG %LOG% "%Home%commits folder created"
)

IF DEFINED Version (
    :: start processor in enterprise mode
    %EXE% ENTERPRISE ^
    /IBConnectionString "File=""%ROOT:"=%\db"";" ^
    /EXECUTE %Home%report.epf ^
    /C "report=%Home%report.mxl; home=%Home%commits; log=%LOG:"=%; authors=%Home%AUTHORS; version=!Version!; shift=3" ^
    /Out %LOG% -NoTruncate

) ELSE (
    %EXE% ENTERPRISE ^
    /IBConnectionString "File=""%ROOT:"=%\db"";" ^
    /EXECUTE %Home%report.epf ^
    /C "report=%Home%report.mxl; home=%Home%commits; log=%LOG:"=%; authors=%Home%AUTHORS; shift=3" ^
    /Out %LOG% -NoTruncate
)

CALL :LOG %LOG% "Report parsed"

:CLEANUP

CALL :LOG %LOG% "cleanup started"

TYPE %LOG% 
TYPE %LOG% >> "%~dp0%~n0.log"

RMDIR /S /Q %ROOT% >> "%~dp0%~n0.log" 2>&1

EXIT /B %ERRORLEVEL%

:Usage

ECHO Usage: %~nx0
ECHO;
ECHO Retrieves report from 1c configuration repository 
ECHO;
ECHO Repository access parameters and path to 1c binaries must be specified in config.ini 
ECHO Sample:
ECHO EXE="C:\Program Files (x86)\1cv8\8.3.9.1850\bin\1cv8.exe"
ECHO RepoPath=tcp://repository_server:port/repo
ECHO RepoUser=User
ECHO RepoPass=123123

EXIT /B 1

:LOG

ECHO %date:~6%.%date:~3,2%.%date:~0,2% %time:~0,2%:%time:~3,2%:%time:~6,2%.%time:~9% %~2 >> %1

EXIT /B 0
