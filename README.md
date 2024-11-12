## Pluto
   [skynet](https://github.com/cloudwu/skynet) 以CMake方式组织工程的跨平台的实现.

## 特点
    1. 跨平台
    2. 支持在 vs2022 中编译运行
    3. skynet 以 submodule 的方式链接,方便升级,确保不改

## 在 Windows 下

基于 [Visual Studio 2022](https://visualstudio.microsoft.com/zh-hans/downloads/) 需要安装 CMake 和 Clang 模块.

- [安装CMake](https://learn.microsoft.com/en-us/cpp/build/cmake-projects-in-visual-studio?view=msvc-170)
- [安装Clang](https://learn.microsoft.com/en-us/cpp/build/clang-support-cmake?view=msvc-170)

## 下载,更新项目

```bash
    git clone --recurse-submodules git@github.com:cloudfreexiao/pluto.git
```

## 在 Windows 下
    1.执行 build.bat 生成工程文件,编译
    2.可以使用vs2022打开此工程目录编译

## 在 Linux 下
    1. 执行 build.sh 编译
    2. 使用 vscode 打开此工程目录(确保安装c++插件)

## 在 MacosX 下
    1. 执行 build.sh 编译
    2. 执行 xcode.sh 生成工程文件,编译
    3. 使用 vscode 打开此工程目录(确保安装c++插件)

## 参考

- [cloudfreexiao/skynet/tree/windows](https://github.com/cloudfreexiao/skynet/tree/windows)

- [dpull/skynet-mingw](https://github.com/dpull/skynet-mingw)

