# LaserJet 1020 Mac Kit

[English](README.md) | 简体中文

LaserJet 1020 Mac Kit 可为 HP LaserJet 1020 构建本地 macOS 安装包。`.pkg` 会安装现有的 CUPS 过滤器、固件、PPD、打印机设置 App 和 shell 卸载脚本，用户无需手动复制驱动文件。

本项目没有重新实现打印机协议。构建输入来自 [anxkhn/hp1020-driver-mac](https://github.com/anxkhn/hp1020-driver-mac)。上游过滤器包含 **x86_64** 代码，并非通用二进制文件；Intel Mac 可直接运行，Apple 芯片 Mac 需要 Rosetta。安装包还依赖旧式 CUPS PPD 驱动机制，未来的 macOS 版本可能改变这一机制。上游仓库称其驱动可在 macOS 26 Tahoe 上使用。本项目的自动检查覆盖安装包内容和 PPD；实际打印仍需连接 HP LaserJet 1020 测试。

## 构建本地 Release 文件

需要 macOS、Xcode Command Line Tools（提供 `pkgbuild` 和 `lipo`）及网络连接。在项目目录运行：

```sh
cd "$HOME/Code/laserjet1020-mac-kit"
make release
```

`make package` 或 `make release` 只生成一个 Release 文件：`dist/LaserJet1020MacKit-0.6.1.pkg`。发布前请确认第三方驱动文件的分发权利。指定版本的上游文件会下载到被 Git 忽略的 `build/upstream/` 目录。如果已有上游仓库的本地副本，可用 `make release SOURCE_DIR=/path/to/hp1020-driver-mac` 离线构建。在 Finder 中打开 `.pkg` 即可安装，也可运行：

```sh
sudo installer -pkg dist/LaserJet1020MacKit-0.6.1.pkg -target /
```

这个本地构建的安装包没有 Developer ID 签名，也没有经过公证。本项目不发布含第三方驱动资源的安装包。发布或分发前请确认这些资源的使用权利，详情见 [THIRD_PARTY.md](THIRD_PARTY.md)。

### Apple 芯片 Mac

安装驱动前，按照 [Apple 的说明](https://support.apple.com/zh-cn/102527) 安装 Rosetta：

```sh
softwareupdate --install-rosetta
```

## 添加打印机

安装包会将 **LaserJet 1020 Mac Kit.app** 放入“应用程序”文件夹。打开它会在“终端”中启动打印机设置工具。安装包不会自动创建打印队列。

连接并开启 HP LaserJet 1020，然后打开 App，选择 **Add Printer**。选择检测到的 USB 设备，输入管理员密码以创建专用打印队列。也可以在 Finder 中打开 `/Library/Application Support/LaserJet1020MacKit/AddPrinter.command`，或在 **系统设置 → 打印机与扫描仪** 中添加打印机并选择 **HP LaserJet 1020 (Mac Kit)** 驱动。如果列表中没有该驱动，可先查找设备 URI，再通过 CUPS 添加队列：

```sh
lpinfo -v | grep -i usb
sudo lpadmin -p HP_LaserJet_1020 -E \
  -v 'usb://Hewlett-Packard/HP%20LaserJet%201020?serial=YOUR_SERIAL' \
  -P '/Library/Printers/PPDs/Contents/Resources/LaserJet 1020 Mac Kit.gz' \
  -D 'HP LaserJet 1020 (Mac Kit)'
```

请用 `lpinfo -v` 的实际结果替换示例 URI。`lpadmin` 可能提示 PPD 驱动已弃用；这是 CUPS 对旧式驱动的提示。设置工具创建的队列名为 `HP_LaserJet_1020_MacKit`，上述手动命令创建的队列名为 `HP_LaserJet_1020`。打印测试页或 PDF 后，可用 `lpstat -p <队列名>` 检查队列。

## 卸载

在“终端”中运行安装好的 shell 脚本。脚本会要求输入 `REMOVE` 确认，然后申请管理员权限：

```sh
'/Library/Application Support/LaserJet1020MacKit/uninstall.sh' --dry-run
'/Library/Application Support/LaserJet1020MacKit/uninstall.sh'
```

通过 **系统设置 → 通用 → 储存空间 → 应用程序** 删除打印机设置 App 不会运行卸载器。要完整清理，请运行 shell 脚本。

如果仍有打印队列使用本驱动的过滤器，包括手动添加的 SMB 队列，脚本会在修改文件或队列前停止。先在 **打印机与扫描仪** 中为该队列换用其他驱动，或自行删除该队列，再重新运行脚本。脚本不会自动删除打印队列。

没有队列依赖本驱动时，脚本会删除打印机设置 App、驱动目录、PPD、支持目录和安装包收据；还会清理 0.4–0.5 版可能残留的图形化卸载 App 和收据。下载的 `.pkg` 文件不属于已安装文件，会保留在用户保存的位置。安装包使用独立目录，不会覆盖从上游仓库手动安装在 `/Library/Printers/hp/laserjet/` 的文件。

## 开发与验证

```sh
make test
```

测试会构建并解开临时安装包，检查过滤器、固件、PPD、设置 App、卸载脚本、升级清理脚本、队列依赖保护、App 签名及改写后的 PPD 路径。测试不会在系统中安装文件，也不能证明真实硬件能够打印。

### 已验证的构建环境（2026 年 10 月 14 日）

本机使用以下系统和工具版本构建并检查本地 Release 文件：

| 组件 | 版本 |
| --- | --- |
| macOS | 15.2（构建号 24C2101），Apple 芯片（`arm64`） |
| Xcode Command Line Tools | 16.2.0.0.1.1733547573（当前开发工具目录：`/Library/Developer/CommandLineTools`） |
| Apple clang | 16.0.0（`clang-1600.0.26.6`） |
| GNU Make | 3.81 |
| ShellCheck | 0.11.0 |
| Apple Git | 2.39.5（`Apple Git-154`） |

当前开发工具目录不是完整 Xcode。这些是本次构建使用的版本，并非最低支持版本。

## 许可证与来源

本项目编写的脚本和文档采用 [MIT 许可证](LICENSE)。上游仓库的过滤器、固件及 PPD **不适用本项目的 MIT 许可证**，也没有提交到本仓库。来源和权利信息见 [THIRD_PARTY.md](THIRD_PARTY.md)。本项目与 HP 或 Apple 没有关联。
