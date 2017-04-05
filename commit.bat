@ECHO OFF

:: set up codepage
@CHCP 65001 > Nul

:: Version
SET Version=%~1

:: Home
SET Home=%~dp0

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

IF EXIST %Home%comments\%Version%.author (
    SET /p Author=<%Home%comments\%Version%.author
) ELSE (
    SET Author="Unknown <example@example.org>"
)

IF NOT EXIST "%Home%git\.git" (
    CALL :LOG %LOG% "%Home%git\.git not found"
    GOTO :CLEANUP
)

IF NOT EXIST "%Home%dumps\%Version%" (
    CALL :LOG %LOG% "%Home%dumps\%Version% not found"
    GOTO :CLEANUP
)


MOVE "%Home%git\.git" "%Home%\dumps\%Version%\.git"

IF EXIST "%Home%git\.gitignore" (
    MOVE "%Home%git\.gitignore" "%Home%dumps\%Version%\"
)

CALL :LOG %LOG% "git files moved"

cd %Home%dumps\%Version%\

git add -A >> %LOG%

git commit -F %Home%comments\%Version%.msg --author="%Author%" >> %LOG%

CALL :LOG %LOG% "files added"

MOVE "%Home%\dumps\%Version%\.git" "%Home%git\.git" 

IF EXIST "%Home%dumps\%Version%\.gitignore" (
    MOVE "%Home%dumps\%Version%\.gitignore" "%Home%git\" 
)



:CLEANUP

CALL :LOG %LOG% "cleanup started"

TYPE %LOG% 
TYPE %LOG% >> %TEMP%\%~n0.log

RMDIR /S /Q %ROOT%

EXIT /B %ERRORLEVEL%

EXIT /B %ERRORLEVEL%

:LOG

ECHO %date:~6%.%date:~3,2%.%date:~0,2% %time:~0,2%:%time:~3,2%:%time:~6,2%.%time:~9% %~2 >> %1

EXIT /B 0

