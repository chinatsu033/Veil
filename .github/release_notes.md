## Veil 0.2.1 · 预览版

Veil（原「FlClash 液态玻璃版」）是基于 [FlClash](https://github.com/chen08209/FlClash) 修改的**预览版**。核心和代理逻辑与 FlClash 相同，只重新设计了界面。

### 本版更新

- **新增 macOS 版**：支持 Intel 和 Apple 芯片（M 系列），界面与 Windows 版相同，是透明背景的圆角玻璃小组件。
  - 菜单栏图标会跟随系统浅色/深色自动变色。在设置中切换图标时，程序坞（Dock）图标会一起切换。
  - macOS 版使用独立的 Bundle ID（`com.chinatsu.veil`）和数据目录，可与原版 FlClash 共存。
- 清理了剩余的 FlClash 名称：链接协议改为 `veil://`，macOS/Linux 包名和核心文件名也改为 Veil。

0.2.0 的改动（改名为 Veil、深色模式、切换图标、Windows 版可与 FlClash 共存、Android 包名改为 `com.chinatsu.veil` 等）见 [0.2.0 发布说明](https://github.com/chinatsu033/Veil/releases/tag/v0.2.0-preview)。

### 界面简介

- **Windows / macOS**：紧凑的圆角玻璃小组件窗口。
  - 左侧是启动/停止按钮，右侧显示实时速度，地区胶囊用来切换地区。
  - 点开地区后会展开世界地图卡片，可以选择地区和节点。
- **Android**：顶部显示当前地区，中间是点阵世界地图，底部是启动按钮和速度条。
- 节点会根据名称自动按「城市 国家/地区」分组。选择地区后会自动测速并选用延迟最低的节点，也可以手动指定节点。
- FlClash 原有的请求、连接、日志、DNS/覆写、备份等功能都保留在「设置 → 更多工具」里。

### 安装方法

**Android**

1. 按设备架构下载 `.apk`：
   - 绝大多数手机选 **`Veil-0.2.1-android-arm64-v8a.apk`**。
   - 很老的 32 位手机选 `armeabi-v7a`。
   - 模拟器选 `x86_64`。
2. 安装时如果被拦截，请在系统设置中**允许该来源「安装未知应用」**。
3. 首次启动时需要允许 VPN 连接请求。

**Windows（x64）**

1. 下载 `Veil-0.2.1-windows-amd64-setup.exe` 安装包，或下载便携版 `.zip`（解压后运行 `Veil.exe`）。
2. 如果 SmartScreen 提示「Windows 已保护你的电脑」，请点「**更多信息 → 仍要运行**」。出现这个提示是因为本程序没有代码签名证书。
3. **虚拟网卡（TUN）模式需要管理员权限**：请以管理员身份运行，或按程序提示授权。不开 TUN 时使用系统代理，不需要管理员权限。

**macOS（12 Monterey 及以上）**

1. 按芯片下载 `.dmg`（可在「 → 关于本机」查看芯片）：
   - **Apple 芯片（M1/M2/M3/M4 等）**：`Veil-0.2.1-macos-arm64.dmg`
   - **Intel 芯片**：`Veil-0.2.1-macos-amd64.dmg`
2. 打开 dmg，把 **Veil** 拖到「应用程序」文件夹。
3. 本程序没有 Apple 开发者签名和公证，第一次打开时系统会提示「无法验证开发者」或「已损坏」。任选一种方法打开：
   - 在「应用程序」里**右键（或按住 Control 点按）Veil → 打开**，在弹窗中再点「打开」。
   - 或先双击一次，然后前往「**系统设置 → 隐私与安全性**」，在页面下方点「**仍要打开**」。
   - 如果提示「已损坏，无法打开」，请在「终端」中运行下面的命令，然后再打开：
     ```
     xattr -dr com.apple.quarantine /Applications/Veil.app
     ```
4. **虚拟网卡（TUN）模式需要管理员授权**：开启 TUN 时会弹出系统密码框，输入电脑密码即可。不开 TUN 时使用系统代理。

### 注意事项

- Windows 版和 macOS 版目前只在 CI 中构建过，**尚未在真机上测试**。未测试的部分包括透明窗口、图标切换、TUN，以及与原版 FlClash 共存。
- 按地区分组依赖节点名称，个别命名不规范的节点可能无法正确归类。
- 可用 `SHA256SUMS` 校验下载文件。

### 开源许可

Veil 是 [FlClash](https://github.com/chen08209/FlClash)（作者 chen08209）的修改版本，按 **GPL-3.0** 许可发布，源代码见本仓库。感谢 FlClash 和 mihomo（Clash.Meta）的作者和贡献者。世界地图数据来自 Natural Earth（公有领域），图标字标使用 Outfit 字体（SIL OFL 1.1）。
