@ECHO OFF

:: set up codepage
@CHCP 65001 > Nul

IF [%1]==[/?] GOTO :Usage
IF [%1]==[-h] GOTO :Usage

:: Version
SET Version=%~1

:: Home
SET Home=%~dp0

:: Initialize temporary folder name in %TEMP% with GUID
FOR /F "tokens=* USEBACKQ" %%F IN (`powershell "[guid]::NewGuid().ToString().Trim()"`) DO (
    SET ROOT="%TEMP:"=%\%%F"
)

MKDIR %ROOT% > Nul || (
    ECHO Failed to create temporary folder
    EXIT /B 1
)

SET LOG="%ROOT:"=%\log.txt"

:: log script name
CALL :LOG %LOG% "%~0 %*"

IF EXIST "%Home:"=%commits\%Version%\author" (
    SET /p Author=<"%Home:"=%commits\%Version%\author"
) ELSE (
    SET Author="Unknown <example@example.org>"
)

IF EXIST "%Home:"=%commits\%Version%\timestamp" (
    SET /p COMMIT_DATE=<"%Home:"=%commits\%Version%\timestamp"
    SET /p GIT_COMMITTER_DATE=<"%Home:"=%commits\%Version%\timestamp"
)

IF NOT EXIST "%Home:"=%git\.git" (
    CALL :LOG %LOG% "%Home:"=%git\.git not found"
    GOTO :CLEANUP
)

IF NOT EXIST "%Home:"=%dumps\%Version%" (
    CALL :LOG %LOG% "%Home:"=%dumps\%Version% not found"
    GOTO :CLEANUP
)

MOVE "%Home:"=%git\.git" "%Home:"=%dumps\%Version%\.git" >> %LOG% 2>&1

IF EXIST "%Home:"=%git\.gitignore" (
    MOVE "%Home:"=%git\.gitignore" "%Home:"=%dumps\%Version%\" >> %LOG% 2>&1
)

CALL :LOG %LOG% "git files moved"

cd "%Home:"=%dumps\%Version%\"

git add . >> %LOG% 2>&1

CALL :LOG %LOG% "files added"

IF DEFINED COMMIT_DATE (
    git commit -F "%Home:"=%commits\%Version%\comment" --author="%Author:"=%" --date=%COMMIT_DATE% >> %LOG% 2>&1 ^
        && CALL :LOG %LOG% "changes committed" || (
            SET FAILED=1
            CALL :LOG %LOG% "commit failed"
        )
) ELSE (
    git commit -F "%Home:"=%commits\%Version%\comment" --author="%Author:"=%" >> %LOG% 2>&1 ^
        && CALL :LOG %LOG% "changes committed" || (
            SET FAILED=1
            CALL :LOG %LOG% "commit failed"
        )
)

IF NOT DEFINED FAILED (
    ECHO %Version: =%  > "%Home:"=%version" ^
        && CALL :LOG %LOG% "version file updated"
)

MOVE "%Home:"=%dumps\%Version%\.git" "%Home:"=%git\.git" >> %LOG% 2>&1

IF EXIST "%Home:"=%dumps\%Version%\.gitignore" (
    MOVE "%Home:"=%dumps\%Version%\.gitignore" "%Home:"=%git\" >> %LOG% 2>&1
)

CALL :LOG %LOG% "git files moved back to %Home:"=%git"

CD %Home%

:CLEANUP

CALL :LOG %LOG% "cleanup started"

TYPE %LOG% 
TYPE %LOG% >> "%~dp0%~n0.log"

RMDIR /S /Q %ROOT% >> "%~dp0%~n0.log" 2>&1

IF DEFINED FAILED (
    EXIT /B 1
)

EXIT /B 0

:Usage

ECHO Usage: %~nx0 ^<version^>
ECHO;
ECHO Commits changes. 
ECHO;
ECHO Repository files are taken from ./git folder
ECHO Files to be put in index,updated etc expected to be in ./dumps/^<version^> folder
ECHO Author name expected to be in ./commits/^<version^>.author file
ECHO Comment expected to be in ./commits/^<version^>.comment file
ECHO Date expected to be in ./commits/^<version^>.timestamp file

EXIT /B 1

:LOG

ECHO %date:~6%.%date:~3,2%.%date:~0,2% %time:~0,2%:%time:~3,2%:%time:~6,2%.%time:~9% %~2 >> %1

EXIT /B 0
