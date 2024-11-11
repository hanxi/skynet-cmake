rem Building PATH
SET PATH=%PATH%;C:\Program Files\Microsoft Visual Studio\2022\Community\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin\
SET PATH=%PATH%;C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Tools\Llvm\x64\bin\
SET PATH=%PATH%;C:\Program Files\Microsoft Visual Studio\2022\Community\Common7\IDE\

rem Building on clang in windows
rmdir /s /q build
mkdir build
cd build
cmake --no-warn-unused-cli -S ../ -B ./ -G "Visual Studio 17 2022" -A x64 -T ClangCL
devenv.com pluto.sln /Build