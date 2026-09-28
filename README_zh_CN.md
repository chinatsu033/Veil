<div>

[**English**](README.md)

</div>

# Veil

> [!NOTE]
> **Veil 是 [FlClash](https://github.com/chen08209/FlClash)（作者 chen08209）的修改版本**，由 [chinatsu033](https://github.com/chinatsu033/Veil) 维护。
> 它保留了 FlClash 的核心与服务逻辑，把主界面换成了「液态玻璃」风格：Windows、macOS 和 Linux 上是紧凑的迷你小组件窗口，Android 上是竖屏地图布局，节点在点阵世界地图上按地区分组显示。支持浅色（默认）和中性深色外观，并可在设置中切换两款应用图标。
> 本项目与原项目一样采用 **GNU 通用公共许可证 v3.0（GPL-3.0）** 授权（见 [LICENSE](LICENSE)），并保留了上游的版权与许可声明。
> Android 包名为 `com.chinatsu.veil`。Windows 版使用独立的安装目录、安装程序 ID、数据目录（`%APPDATA%\com.chinatsu\veil`）、核心/服务名称和端口，可与原版 FlClash 同时安装。macOS 版的 Bundle ID 为 `com.chinatsu.veil`（提供 Intel `x86` 与 Apple 芯片 `arm64` 两个版本，未签名，首次打开方法见发布说明）。Linux 版（`x86` 与 `arm64`）提供 `.deb`、`.rpm` 和 `.AppImage`，应用 ID 为 `com.chinatsu.veil`。发布文件中 Intel/AMD 架构统一命名为 `x86`。
> Veil 的问题请不要反馈给上游 FlClash。

## 许可与致谢

| 组件 | 用途 | 许可 |
| --- | --- | --- |
| [FlClash](https://github.com/chen08209/FlClash)（chen08209） | 除玻璃界面外的全部功能 | GPL-3.0 |
| [Natural Earth](https://www.naturalearthdata.com/) 1:50m Admin 0 – Countries | 预先计算为点阵世界地图（`lib/glass/world_dots.dart`，由 `tool/gen_world_dots.py` 生成） | 公有领域 |
| [Outfit](https://github.com/Outfitio/Outfit-Fonts) 字体，© 2021 The Outfit Project Authors | 仅用于应用图标中的「Veil」字标（已转为轮廓，应用内不打包该字体）；字体与许可见 `tool/icon/` | SIL OFL 1.1 |
| Material Icons（随 Flutter 提供） | 界面图标 | Apache-2.0 |
| JetBrains Mono、Twemoji（Mozilla 版）、`Icons.ttf` | 继承自上游 FlClash | OFL 1.1 / CC-BY 4.0（图形）/ 上游 |


## FlClash（上游）

[![Downloads](https://img.shields.io/github/downloads/chen08209/FlClash/total?style=flat-square&logo=github)](https://github.com/chen08209/FlClash/releases/)[![Last Version](https://img.shields.io/github/release/chen08209/FlClash/all.svg?style=flat-square)](https://github.com/chen08209/FlClash/releases/)[![License](https://img.shields.io/github/license/chen08209/FlClash?style=flat-square)](LICENSE)

[![Channel](https://img.shields.io/badge/Telegram-Channel-blue?style=flat-square&logo=telegram)](https://t.me/FlClash)

基于ClashMeta的多平台代理客户端，简单易用，开源无广告。

<p align="center">
    <picture>
        <source media="(prefers-color-scheme: dark)" srcset="snapshots/preview-dark.png">
        <img alt="FlClash on desktop and mobile" src="snapshots/preview.png" width="90%">
    </picture>
</p>

## Features

✈️ 多平台: Android, Windows, macOS and Linux

💻 自适应多个屏幕尺寸,多种颜色主题可供选择

💡 基本 Material You 设计, 类[Surfboard](https://github.com/getsurfboard/surfboard)用户界面

☁️ 支持通过WebDAV同步数据

✨ 支持一键导入订阅, 深色模式

## Use

### Linux

`.deb` 用 `sudo apt install ./Veil-<版本>-linux-x86.deb` 安装（ARM 设备选 `linux-arm64`）；`.AppImage` 先 `chmod +x` 再直接运行。

⚠️ 使用 AppImage 前请确保系统已安装托盘依赖

   ```bash
    sudo apt-get install libayatana-appindicator3-dev
   ```

### Android

支持下列操作

   ```bash
    com.follow.clash.action.START
    
    com.follow.clash.action.STOP
    
    com.follow.clash.action.TOGGLE
   ```

## Download

<a href="https://chen08209.github.io/FlClash-fdroid-repo/repo?fingerprint=789D6D32668712EF7672F9E58DEEB15FBD6DCEEC5AE7A4371EA72F2AAE8A12FD"><img alt="Get it on F-Droid" src="snapshots/get-it-on-fdroid.svg" width="200px"/></a> <a href="https://github.com/chen08209/FlClash/releases"><img alt="Get it on GitHub" src="snapshots/get-it-on-github.svg" width="200px"/></a>

### Homebrew

```bash
brew tap chen08209/tap
brew install --cask flclash
```

## Build

1. 更新 submodules
   ```bash
   git submodule update --init --recursive
   ```

2. 安装 `Flutter` 以及 `Golang` 环境

3. 构建应用

    - android

        1. 安装  `Android SDK` ,  `Android NDK`

        2. 设置 `ANDROID_NDK` 环境变量

        3. 运行构建脚本

           ```bash
           dart setup.dart android
           ```

    - windows

        1. 你需要一个windows客户端

        2. 安装 `GCC`，`Inno Setup`

        3. 运行构建脚本

           ```bash
           dart setup.dart windows
           ```

    - linux

        1. 你需要一个linux客户端

        2. 依赖会由 setup 脚本自动安装，也可以手动安装：
           ```bash
           sudo apt-get install -y libayatana-appindicator3-dev
           ```

        3. 运行构建脚本

           ```bash
           dart setup.dart linux
           ```

    - macOS

        1. 你需要一个macOS客户端

        2. 运行构建脚本

           ```bash
           dart setup.dart macos
           ```

## Star

支持开发者的最简单方式是点击页面顶部的星标（⭐）。

<p style="text-align: center;">
    <a href="https://api.star-history.com/svg?repos=chen08209/FlClash&Date">
        <img alt="start" width=50% src="https://api.star-history.com/svg?repos=chen08209/FlClash&Date"/>
    </a>
</p>
