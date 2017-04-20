@ECHO OFF

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

MKDIR %ROOT% > Nul || (
    ECHO Failed to create temporary folder
    EXIT /B 1
)

SET LOG="%ROOT:"=%\log.txt"

:: log script name
CALL :LOG %LOG% "%~0 %*"

IF NOT EXIST "%Home:"=%git" (
    MKDIR "%Home:"=%git" >> %LOG% 2>&1 ^
        && CALL :LOG %LOG% "%Home:"=%git created"
)

RMDIR /S /Q "%Home:"=%git\.git" >> %LOG% 2>&1 ^
    && CALL :LOG %LOG% "%Home:"=%git\.git removed"

DEL /F /Q /S "%Home:"=%git\.gitignore" >> %LOG% 2>&1 ^
    && CALL :LOG %LOG% "%Home:"=%git\.gitignore deleted"

ECHO "*.cf" >> "%Home:"=%git\.gitignore"
ECHO "*.bin" >> "%Home:"=%git\.gitignore"
ECHO "*.png" >> "%Home:"=%git\.gitignore"
ECHO "**/Help" >> "%Home:"=%git\.gitignore"
ECHO "**\Help" >> "%Home:"=%git\.gitignore"
ECHO "Help.xml" >> "%Home:"=%git\.gitignore"

CALL :LOG %LOG% "%Home:"=%git\.gitignore initialized"

CD "%Home:"=%git" >> %LOG% 2>&1

git init >> %LOG% 2>&1 ^
    && CALL :LOG %LOG% "git init successful"

attrib -H "%Home:"=%git\.git" >> %LOG% 2>&1 ^
    && CALL :LOG %LOG% ".git set visible"

CD "%Home:"=%" >> %LOG% 2>&1 

:CLEANUP

CALL :LOG %LOG% "cleanup started"

TYPE %LOG% 
TYPE %LOG% >> "%~dp0%~n0.log"

RMDIR /S /Q %ROOT% >> "%~dp0%~n0.log" 2>&1

EXIT /B 0

:Usage

ECHO Usage: %~nx0
ECHO;
ECHO Initialize git
ECHO;

EXIT /B 1

:LOG

ECHO %date:~6%.%date:~3,2%.%date:~0,2% %time:~0,2%:%time:~3,2%:%time:~6,2%.%time:~9% %~2 >> %1

EXIT /B 0
