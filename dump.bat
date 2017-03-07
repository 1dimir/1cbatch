@ECHO OFF

IF [%1]==[/?] GOTO :Usage
IF [%2]==[] GOTO :Usage

SET Version=%~1
SET Cfg=%2

FOR /F "tokens=* USEBACKQ" %%F IN (`powershell "[guid]::NewGuid().ToString().Trim()"`) DO (
    SET "ROOT=%temp%\%%F"
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
ECHO %date:~6%.%date:~3,2%.%date:~0,2% %time:~0,2%:%time:~3,2%:%time:~6,2%.%time:~9% ^
%~0 >> %LOG%

:: set up codepage
chcp 65001 >>%LOG%

:: read config
SET CONFIG=%~d0%~p0config.ini

IF NOT EXIST %CONFIG% (
    ECHO config.ini not fount
    GOTO :CLEANUP
)

ECHO %date:~6%.%date:~3,2%.%date:~0,2% %time:~0,2%:%time:~3,2%:%time:~6,2%.%time:~9% ^
config.ini located >> %LOG%

FOR /F "tokens=*" %%A IN ('TYPE "%CONFIG%"') DO SET %%A

IF NOT DEFINED EXE (
    ECHO EXE is not set in config.ini
    GOTO :CLEANUP
)

IF NOT DEFINED RepoPath (
    ECHO RepoPath is not set in config.ini
    GOTO :CLEANUP
)

IF NOT DEFINED RepoUser (
    ECHO RepoUser is not set in config.ini
    GOTO :CLEANUP
)

IF NOT DEFINED RepoPass (
    SET RepoPass=""
)

ECHO %date:~6%.%date:~3,2%.%date:~0,2% %time:~0,2%:%time:~3,2%:%time:~6,2%.%time:~9% ^
Settings read >> %LOG%

:: create temporary infobase
%EXE% DESIGNER ^
/IBConnectionString "File=""%ROOT%\db"";" ^
/RestoreIB ^
/Out %LOG% -NoTruncate

ECHO %date:~6%.%date:~3,2%.%date:~0,2% %time:~0,2%:%time:~3,2%:%time:~6,2%.%time:~9% ^
temporaty infobase %ROOT%\db created >> %LOG%

:: batch configurator call
%EXE% DESIGNER ^
/IBConnectionString "File=""%ROOT%\db"";" ^
/ConfigurationRepositoryF "%RepoPath%" ^
/ConfigurationRepositoryN "%RepoUser%" ^
/ConfigurationRepositoryP "%RepoPass%" ^
/ConfigurationRepositoryDumpCfg "%Cfg%" -v "%Version%" ^
/Out %LOG% -NoTruncate

ECHO %date:~6%.%date:~3,2%.%date:~0,2% %time:~0,2%:%time:~3,2%:%time:~6,2%.%time:~9% ^
Configuration dumped %Cfg% >> %LOG%

:CLEANUP

ECHO %date:~6%.%date:~3,2%.%date:~0,2% %time:~0,2%:%time:~3,2%:%time:~6,2%.%time:~9% ^
cleanup started >> %LOG%

TYPE %LOG% 
TYPE %LOG% >> %TEMP%\%~n0.log

RMDIR /S /Q %ROOT%

EXIT /B %ERRORLEVEL%

:Usage

ECHO Usage: %~n0 ^<version^> ^<dump.cf^>
ECHO;
ECHO Dumps specified version from 1c configuration repository 
ECHO;
ECHO Repository access parameters and path to 1c binaries must be specified in config.ini 
ECHO Sample:
ECHO EXE="C:\Program Files (x86)\1cv8\8.3.9.1850\bin\1cv8.exe"
ECHO RepoPath=tcp://repository_server:port/repo
ECHO RepoUser=User
ECHO RepoPass=123123

EXIT /B 1