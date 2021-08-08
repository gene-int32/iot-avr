@echo off

call "vs2019tools.bat"

cmake --build ../build --config Debug --target all -j 10

exit