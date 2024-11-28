@echo off

call "C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvars64.bat"

rmdir /s /q out
cmake --preset x64-debug
cmake --build out/build/x64-debug
