@ECHO OFF

Setlocal EnableDelayedExpansion

:: set up codepage
@CHCP 65001 > Nul

IF [%1]==[/?] GOTO :Usage
IF [%1]==[-h] GOTO :Usage

:: Home
SET Home=%~dp0

IF EXIST "%Home:"=%version" (
    SET /P Version=<version
    SET /A Version=!Version: =! + 1
) ELSE (
    SET /P Version=1
)

IF NOT EXIST "%Home:"=%commits\!Version!" (
    CALL report.bat || (
        SET FAILED
        GOTO :CLEANUP
    )
)

IF EXIST "%Home:"=%commits\!Version!" (
    CALL dump.bat !Version! || (
        SET FAILED
        GOTO :CLEANUP
    )
    CALL parse.bat !Version!
    CALL commit.bat !Version!
    CALL cleanup.bat !Version!
)

:CLEANUP

IF DEFINED FAILED ^
    EXIT /B 1

EXIT /B 0

:Usage

ECHO Usage: %~nx0
ECHO;
ECHO Fetches next version from configuration repository
ECHO;

EXIT /B 1

