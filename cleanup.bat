@ECHO OFF

:: set up codepage
@CHCP 65001 > Nul

IF [%1]==[/?] GOTO :Usage
IF [%1]==[-h] GOTO :Usage
IF [%1]==[] GOTO :Usage

:: Version
SET Version=%~1

:: Home
SET Home=%~dp0

:: Initialize temporary folder name in %TEMP% with GUID
FOR /F "tokens=* USEBACKQ" %%F IN (`powershell "[guid]::NewGuid().ToString().Trim()"`) DO (
    SET ROOT="%TEMP:"=%\%%F"
)

MKDIR %ROOT% > Nul || ECHO Failed to create temporary folder && EXIT /B 1

SET LOG="%ROOT:"=%\log.txt"

:: log script name
CALL :LOG %LOG% "%~0 %*"

IF EXIST "%Home:"=%cf\%Version%" (
    RMDIR /S /Q "%Home:"=%cf\%Version%" >> %LOG% 2>&1 && CALL :LOG %LOG% "%Home:"=%cf\%Version% deleted"
)

IF EXIST "%Home:"=%commits\%Version%.author" (
    DEL /F /Q /S "%Home:"=%commits\%Version%.author" >> %LOG% 2>&1 && CALL :LOG %LOG% "%Home:"=%commits\%Version%.author deleted"
)

IF EXIST "%Home:"=%commits\%Version%.comment" (
    DEL /F /Q /S "%Home:"=%commits\%Version%.comment" >> %LOG% 2>&1 && CALL :LOG %LOG% "%Home:"=%commits\%Version%.comment deleted"
)

IF EXIST "%Home:"=%commits\%Version%.timestamp" (
    DEL /F /Q /S "%Home:"=%commits\%Version%.timestamp" >> %LOG% 2>&1 && CALL :LOG %LOG% "%Home:"=%commits\%Version%.timestamp deleted"
)

IF EXIST "%Home:"=%dumps\%Version%\.git" IF NOT EXIST "%Home":=%git\.git" (
    MOVE "%Home:"=%dumps\%Version%\.git" "%Home:"=%git\.git"  >> %LOG% 2>&1 && CALL :LOG %LOG% ".git folder moved back" || CALL :LOG %LOG% ".git folder is still present in %Home:"=%dumps\%Version%\ and failed to be moved" && GOTO :CLEANUP
)

IF EXIST "%Home:"=%dumps\%Version%\.gitignore" IF NOT EXIST "%Home:"=%git\.gitignore" (
    MOVE "%Home:"=%dumps\%Version%\.gitignore" "%Home:"=%git\.gitignore"  >> %LOG% 2>&1 && CALL :LOG %LOG% ".gitignore file moved back" || CALL :LOG %LOG% ".gitignore file is still present in %Home:"=%dumps\%Version%\ and failed to be moved" && GOTO :CLEANUP
)

IF EXIST "%Home"=%dumps\%Version%" (
    RMDIR /S /Q "%Home:"=%dumps\%Version%" >> %LOG% 2>&1 && CALL :LOG %LOG% "%Home:"=%dumps\%Version% deleted"
)

:CLEANUP

CALL :LOG %LOG% "cleanup started"

TYPE %LOG% 
TYPE %LOG% >> "%~dp0%~n0.log"

RMDIR /S /Q %ROOT% >> "%~dp0%~n0.log" 2>&1

EXIT /B 0

:Usage

ECHO Usage: %~nx0 ^<version^>
ECHO;
ECHO Cleans up everything corresponding to given version. 
ECHO;

EXIT /B 1

:LOG

ECHO %date:~6%.%date:~3,2%.%date:~0,2% %time:~0,2%:%time:~3,2%:%time:~6,2%.%time:~9% %~2 >> %1

EXIT /B 0
