# LaserJet 1020 Mac Kit

为 HP LaserJet 1020 准备的 macOS 本地安装包构建工具。它把现有的 CUPS 过滤程序、固件和 PPD 放进一个 `.pkg`，并附带卸载工具，省去手动复制文件。项目名为 **LaserJet 1020 Mac Kit**。

本项目没有重新实现打印协议。构建输入来自 [anxkhn/hp1020-driver-mac](https://github.com/anxkhn/hp1020-driver-mac)，该仓库的过滤程序是 **x86_64**，并非通用架构。Intel Mac 可直接运行；Apple 芯片 Mac 需要 Rosetta。当前方案依赖传统 CUPS PPD 驱动机制，未来 macOS 版本可能改变支持情况。参考仓库报告在 macOS 26 Tahoe 上工作；本项目的自动验证只覆盖安装包内容与 PPD，实际打印仍需在连接打印机的 Mac 上确认。

## 获取并构建安装包

需要 macOS、Xcode Command Line Tools（提供 `pkgbuild`、`lipo` 等工具）和网络连接。在项目目录执行一条命令即可下载固定版本的参考文件并构建：

```sh
cd "$HOME/Code/laserjet1020-mac-kit"
make package
```

下载内容保存在忽略版本控制的 `build/upstream/`。如果已有参考仓库的本地副本，或需要离线构建，可运行 `make package SOURCE_DIR=/path/to/hp1020-driver-mac`。输出是 `dist/LaserJet1020MacKit-0.1.0.pkg`。可在 Finder 中打开安装，也可在终端运行：

```sh
sudo installer -pkg dist/LaserJet1020MacKit-0.1.0.pkg -target /
```

此安装包由本机生成，未签名、未公证。项目不提供包含第三方驱动资源的公开发行包；发布或再分发前请自行确认这些资源的授权，见 [THIRD_PARTY.md](THIRD_PARTY.md)。

### Apple 芯片 Mac

在安装前按 [Apple 的说明](https://support.apple.com/en-hk/102527)安装 Rosetta：

```sh
softwareupdate --install-rosetta
```

## 添加打印机

安装包只安装驱动文件，不自动创建打印队列。连接并开启 HP LaserJet 1020 后，在“系统设置 → 打印机与扫描仪”中添加打印机，并选择 **HP LaserJet 1020 (Mac Kit)**。如果系统没有列出该驱动，可以用 CUPS 命令查看设备 URI 并添加：

```sh
lpinfo -v | grep -i usb
sudo lpadmin -p HP_LaserJet_1020 -E \
  -v 'usb://Hewlett-Packard/HP%20LaserJet%201020?serial=YOUR_SERIAL' \
  -P '/Library/Printers/PPDs/Contents/Resources/LaserJet 1020 Mac Kit.gz' \
  -D 'HP LaserJet 1020 (Mac Kit)'
```

将示例 URI 换成 `lpinfo -v` 的实际输出。`lpadmin` 可能提示 PPD 驱动已弃用，这是 CUPS 对传统驱动的提示。打印测试页或 PDF 后用 `lpstat -p HP_LaserJet_1020` 检查队列状态。

## 卸载

安装后在 Finder 打开 `/Library/Application Support/LaserJet1020MacKit/Uninstall.command`，按提示输入 `REMOVE` 和管理员密码。也可以在终端预览或执行：

```sh
'/Library/Application Support/LaserJet1020MacKit/Uninstall.command' --dry-run
'/Library/Application Support/LaserJet1020MacKit/Uninstall.command'
```

卸载工具只删除本项目安装的文件和包收据。已添加的打印队列会保留，请在“系统设置 → 打印机与扫描仪”中移除。安装包使用独立目录，不覆盖参考仓库手动安装在 `/Library/Printers/hp/laserjet/` 的文件。

## 开发与验证

```sh
make test
```

测试会构建临时安装包、解开 payload，核对程序、固件、PPD、卸载工具和 PPD 中的路径。它不会执行系统安装，也不代表完成了真实打印测试。

## 许可证与来源

本项目自行编写的脚本和文档采用 [MIT License](LICENSE)。参考仓库的过滤程序、固件和 PPD **不在本项目 MIT 授权范围内**，也没有提交到本仓库。参考文件的版权与来源见 [THIRD_PARTY.md](THIRD_PARTY.md)。本项目与 HP、Apple 无关联。
