@ECHO OFF

:: set up codepage
@CHCP 65001 > Nul

IF [%1]==[/?] GOTO :Usage
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
    MKDIR %ROOT%\backup
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

IF NOT DEFINED GIT (
    CALL :LOG %LOG% "GIT is not set in config.ini"
    GOTO :CLEANUP
)

CALL :LOG %LOG% "Settings read"

:: backup
ROBOCOPY /move "%GIT%\.git" "%ROOT%\backup\.git"  /E /NFL /NDL /NJH /NJS /nc /ns /np
ROBOCOPY /move "%GIT%\.gitignore" "%ROOT%\backup\.gitignore"  /E /NFL /NDL /NJH /NJS /nc /ns /np

:: ROBOCOPY /move "%GIT%\.gitignore" "%ROOT%\backup\\"  /E /NFL /NDL /NJH /NJS /nc /ns /np

:SUCCESS

CALL :LOG %LOG% "Success %Cfg%"

:CLEANUP

CALL :LOG %LOG% "cleanup started"

TYPE %LOG% 
TYPE %LOG% >> %TEMP%\%~n0.log

RMDIR /S /Q %ROOT%

EXIT /B %ERRORLEVEL%

:Usage

ECHO Usage: %~n0 ^<version^> 
ECHO;
ECHO Commits parsed files
ECHO;
ECHO Parameters be specified in config.ini 
ECHO Sample:
ECHO EXE="C:\Program Files (x86)\1cv8\8.3.9.1850\bin\1cv8.exe"
ECHO RepoPath=tcp://repository_server:port/repo
ECHO RepoUser=User
ECHO RepoPass=123123

EXIT /B 1

:LOG

ECHO %date:~6%.%date:~3,2%.%date:~0,2% %time:~0,2%:%time:~3,2%:%time:~6,2%.%time:~9% %~2 >> %1

EXIT /B 0
