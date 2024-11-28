# 使用 CMake 编译 skynet

[skynet-cmake](https://github.com/hanxi/skynet-cmake) 是 [skynet](https://github.com/cloudwu/skynet) 的使用 CMake 的多平台的实现。

## 特点

- 支持在 Visual Studio 2022 中编译运行。
- skynet 以 submodule 的方式链接，方便升级，确保不改。

## 在 Windows 下

基于 [Visual Studio 2022](https://visualstudio.microsoft.com/zh-hans/downloads/) ，需要安装 CMake 和 Clang 模块。

- [安装CMake](https://learn.microsoft.com/en-us/cpp/build/cmake-projects-in-visual-studio?view=msvc-170)
- [安装Clang](https://learn.microsoft.com/en-us/cpp/build/clang-support-cmake?view=msvc-170)

### 下载工程和更新 submodule

```bash
git checkout https://github.com/hanxi/skynet-cmake.git
cd skynet-cmake
git submodule update --init --recursive
```

使用 vs2022 打开此工程目录 skynet-cmake (即CMakeLists.txt 文件所在目录）。
- 点击 [生成] -> [全部重新生成]
- 选择 skynet.exe -> 点击 [调试]

也可以执行 `build.bat` 脚本生成 `out/build/x64-debug/skynet.exe` 文件。

## 在 Linux MacOSX 下

没多大必要，直接用 make 可能更方便。

```bash
mkdir build
cd build
    Makefile:
        cmake ../
    Xcode:
        cmake -G Xcode ../
```

## 参考

- [cloudfreexiao/skynet/tree/windows](https://github.com/cloudfreexiao/skynet/tree/windows)
- [dpull/skynet-mingw](https://github.com/dpull/skynet-mingw)
- [cloudfreexiao/pluto](https://github.com/cloudfreexiao/pluto)

