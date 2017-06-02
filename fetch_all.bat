@ECHO OFF

Setlocal EnableDelayedExpansion

:: set up codepage
@CHCP 65001 > Nul

IF [%1]==[/?] GOTO :USAGE
IF [%1]==[-h] GOTO :USAGE

:: Home
SET Home=%~dp0

CD "%Home:"=%"

IF EXIST "%Home:"=%version" (
    SET /P Version=<version
    SET /A Version=!Version: =! + 1
) ELSE (
    SET Version=1
)

IF NOT EXIST "%Home:"=%git\.git" (
    CALL init.bat
)

CALL report.bat || (
  SET FAILED=1
    GOTO :EXIT
)

:MAIN_LOOP

IF EXIST "%Home:"=%commits\!Version!" (
    CALL dump.bat !Version! || (
        SET FAILED=1
        GOTO :EXIT
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
) ELSE (
    GOTO :EXIT
)

SET /A Version=!Version: =! + 1
GOTO :MAIN_LOOP

:EXIT

IF DEFINED FAILED (
    EXIT /B 1
)

EXIT /B 0

:USAGE

ECHO Usage: %~nx0
ECHO;
ECHO Fetches all versions from configuration repository
ECHO;

EXIT /B 1

