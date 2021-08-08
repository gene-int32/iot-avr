@echo off

@REM VS 2019 example
@REM Path to Developer Command Prompt
set VS2019TOOLS="C:\Program Files (x86)\Microsoft Visual Studio\2019\BuildTools\Common7\Tools\VsDevCmd.bat"

if not exist %VS2019TOOLS% (
    echo VS 2019 Build Tools are missing!
    exit
)

call %VS2019TOOLS%