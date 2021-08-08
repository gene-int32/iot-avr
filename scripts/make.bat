@echo off

call "vs2019tools.bat"

@REM Command to make
set COMMAND=%1
if "%COMMAND%"=="" (
    set  COMMAND=help
)

cd ../build

make %COMMAND%

exit