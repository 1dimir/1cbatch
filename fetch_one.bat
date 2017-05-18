@ECHO OFF

Setlocal EnableDelayedExpansion

:: set up codepage
@CHCP 65001 > Nul

IF [%1]==[/?] GOTO :Usage
IF [%1]==[-h] GOTO :Usage

:: Home
SET Home=%~dp0

CD "%Home:"=%"

IF EXIST "%Home:"=%version" (
    SET /P Version=<version
    SET /A Version=!Version: =! + 1
) ELSE (
    SET /P Version=1
)

IF NOT EXIST "%Home:"=%git\.git" (
    CALL init.bat
)

IF NOT EXIST "%Home:"=%commits\!Version!" (
    CALL report.bat || (
        SET FAILED=1
        GOTO :CLEANUP
    )
)

IF EXIST "%Home:"=%commits\!Version!" (
    CALL dump.bat !Version! || (
        SET FAILED=1
        GOTO :CLEANUP
    )
    CALL parse.bat !Version! || (
        SET FAILED=1
        GOTO :CLEANUP
    )
    CALL commit.bat !Version! || (
        SET FAILED=1
        GOTO :CLEANUP
    )
    CALL cleanup.bat !Version! || (
        SET FAILED=1
        GOTO :CLEANUP
    )
)

:CLEANUP

IF DEFINED FAILED (
    EXIT /B 1
)

EXIT /B 0

:Usage

ECHO Usage: %~nx0
ECHO;
ECHO Fetches next version from configuration repository
ECHO;

EXIT /B 1

