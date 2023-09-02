# 使用 CMake 编译 skynet

## 在 Windows 下

基于 [Visual Studio 2022](https://visualstudio.microsoft.com/zh-hans/downloads/) ，需要安装 CMake 和 Clang 模块。

- [安装CMake](https://learn.microsoft.com/en-us/cpp/build/cmake-projects-in-visual-studio?view=msvc-170)
- [安装Clang](https://learn.microsoft.com/en-us/cpp/build/clang-support-cmake?view=msvc-170)

更新 submodule

```bash
git submodule update --init
```

使用 vs2022 打开此工程目录 (即CMakeLists.txt 文件所在目录）

## 在 Linux 下

```bash
mkdir build
cd build
cmake ..
make
```

