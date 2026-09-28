## Veil 0.2.2 · 预览版

Veil（原「FlClash 液态玻璃版」）是基于 [FlClash](https://github.com/chen08209/FlClash) 修改的**预览版**。核心和代理逻辑与 FlClash 相同，只重新设计了界面。

### 本版更新

- **背景遮罩，文字更清楚**：Windows / macOS 小组件后面加了一层半透明遮罩（浅色为偏白、深色为中性灰黑），桌面和其他窗口不会再透出来干扰文字。
  - Windows 11 使用系统亚克力（Acrylic）/ 云母（Mica）模糊；macOS 使用系统毛玻璃模糊；Windows 10 使用更不透明的遮罩。圆角玻璃外观保持不变。
- **动画更流畅**：
  - 展开/收起面板时不再逐帧改变窗口大小，改为一次调整窗口、在界面内做动画。
  - 世界地图的点阵只绘制一次并缓存，只有选中地区的脉冲圈在动画。
  - 速度每秒刷新时只重绘速度条，不再重建整个界面。
  - Android 上的玻璃卡片共用一次背景模糊，设置页去掉了看不出效果的模糊，滚动更顺。
- **新增 Linux 版**：提供 x86 和 arm64 的 `.deb`、`.rpm`、`.AppImage`。Linux 版使用不透明的面板背景（Linux 窗口透明支持不稳定，以可读性优先），应用 ID 为 `com.chinatsu.veil`。
- **架构命名改为 x86**：发布文件中 Intel/AMD 架构统一写作 `x86`（原来的 `amd64` / `x86_64`），ARM 仍为 `arm64`。

0.2.1 新增了 macOS 版，0.2.0 改名为 Veil 并加入深色模式等，详见 [0.2.1 发布说明](https://github.com/chinatsu033/Veil/releases/tag/v0.2.1-preview)。

### 界面简介

- **Windows / macOS / Linux**：紧凑的圆角玻璃小组件窗口。
  - 左侧是启动/停止按钮，右侧显示实时速度，地区胶囊用来切换地区。
  - 点开地区后会展开世界地图卡片，可以选择地区和节点。
- **Android**：顶部显示当前地区，中间是点阵世界地图，底部是启动按钮和速度条。
- 节点会根据名称自动按「城市 国家/地区」分组。选择地区后会自动测速并选用延迟最低的节点，也可以手动指定节点。
- FlClash 原有的请求、连接、日志、DNS/覆写、备份等功能都保留在「设置 → 更多工具」里。

### 安装方法

**Android**

1. 按设备架构下载 `.apk`：
   - 绝大多数手机选 **`Veil-0.2.2-android-arm64-v8a.apk`**。
   - 很老的 32 位手机选 `armeabi-v7a`。
   - 模拟器选 `x86`。
2. 安装时如果被拦截，请在系统设置中**允许该来源「安装未知应用」**。
3. 首次启动时需要允许 VPN 连接请求。

**Windows（x86 64 位）**

1. 下载 `Veil-0.2.2-windows-x86-setup.exe` 安装包，或下载便携版 `Veil-0.2.2-windows-x86.zip`（解压后运行 `Veil.exe`）。
2. 如果 SmartScreen 提示「Windows 已保护你的电脑」，请点「**更多信息 → 仍要运行**」。出现这个提示是因为本程序没有代码签名证书。
3. **虚拟网卡（TUN）模式需要管理员权限**：请以管理员身份运行，或按程序提示授权。不开 TUN 时使用系统代理，不需要管理员权限。

**macOS（12 Monterey 及以上）**

1. 按芯片下载 `.dmg`（可在「 → 关于本机」查看芯片）：
   - **Apple 芯片（M1/M2/M3/M4 等）**：`Veil-0.2.2-macos-arm64.dmg`
   - **Intel 芯片**：`Veil-0.2.2-macos-x86.dmg`
2. 打开 dmg，把 **Veil** 拖到「应用程序」文件夹。
3. 本程序没有 Apple 开发者签名和公证，第一次打开时系统会提示「无法验证开发者」或「已损坏」。任选一种方法打开：
   - 在「应用程序」里**右键（或按住 Control 点按）Veil → 打开**，在弹窗中再点「打开」。
   - 或先双击一次，然后前往「**系统设置 → 隐私与安全性**」，在页面下方点「**仍要打开**」。
   - 如果提示「已损坏，无法打开」，请在「终端」中运行下面的命令，然后再打开：
     ```
     xattr -dr com.apple.quarantine /Applications/Veil.app
     ```
4. **虚拟网卡（TUN）模式需要管理员授权**：开启 TUN 时会弹出系统密码框，输入电脑密码即可。不开 TUN 时使用系统代理。

**Linux（x86 / arm64）**

- **Debian / Ubuntu（.deb）**：
  ```
  sudo apt install ./Veil-0.2.2-linux-x86.deb
  ```
  ARM 设备请下载 `Veil-0.2.2-linux-arm64.deb`。安装后在应用菜单中打开 Veil。
- **Fedora / openSUSE（.rpm）**：`sudo dnf install ./Veil-0.2.2-linux-x86.rpm`
- **AppImage（免安装）**：
  ```
  chmod +x Veil-0.2.2-linux-x86.AppImage
  ./Veil-0.2.2-linux-x86.AppImage
  ```
  需要系统已安装托盘库 `libayatana-appindicator3-1`（大多数桌面发行版自带）。

### 注意事项

- Windows、macOS 和 Linux 版目前只在 CI 中构建过，**尚未在真机上测试**。未测试的部分包括背景遮罩与系统模糊的实际效果、图标切换、TUN，以及与原版 FlClash 共存。
- 按地区分组依赖节点名称，个别命名不规范的节点可能无法正确归类。
- 可用 `SHA256SUMS` 校验下载文件。

### 开源许可

Veil 是 [FlClash](https://github.com/chen08209/FlClash)（作者 chen08209）的修改版本，按 **GPL-3.0** 许可发布，源代码见本仓库。感谢 FlClash 和 mihomo（Clash.Meta）的作者和贡献者。世界地图数据来自 Natural Earth（公有领域），图标字标使用 Outfit 字体（SIL OFL 1.1）。
