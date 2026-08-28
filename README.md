![LowBat Countdown](assets/readme-badge.png)

# 低电量倒计时

面向 TrollStore 的 iOS 低电量倒计时工具。设备电量达到阈值后，显示覆盖其他 App 的全屏提示；倒计时结束后保持显示，接通电源才会解除。

> [!WARNING]
> 这是面向 TrollStore 的越狱工具，使用了私有 UIKit / SpringBoard 能力。请先确认设备和系统版本符合要求，并自行承担使用风险。

## 功能

- 支持 iOS/iPadOS 15.0–16.6.1，以及 16.7 RC
- 支持 1%–20% 的低电量触发阈值
- 支持 10–300 秒倒计时
- 不可关闭的系统级全屏提示，充电后自动解除
- 内置测试入口，便于验证覆盖层行为
- 使用 C 状态机测试核心触发、倒计时、充电解除和边界配置

## 快速开始

如果你正在使用支持仓库安装的 agent，可以直接告诉它：

```text
帮我安装这个仓库……
```

## 传统开始

### 环境要求

- macOS 与 Xcode Command Line Tools
- iOS SDK 15.0 或更高版本
- arm64 iPhone 或 iPad
- 已安装 TrollStore
- 构建时需要 `ldid`

### 构建与测试

```sh
make test
make package
make inspect
```

构建产物为 `build/LowBatCountdown-1.0.2.tipa`。`make all` 会依次运行测试和打包。

### 安装到设备

1. 将 `.tipa` 复制到设备。
2. 通过 TrollStore 打开并安装。
3. 打开“低电量倒计时”，启用“监控服务”。
4. 设置触发电量和倒计时长度。

每次完整重启设备后，需要再次打开一次 App 来恢复监控；TrollStore 不会自动启动该辅助进程。

## 工作方式

配置 App 将设置写入共享 plist，并启动 HUD 监控进程。HUD 进程监听电量与充电状态，在达到阈值时显示安全的全屏覆盖层；倒计时归零后进入保持状态，只有检测到充电才会隐藏。

## 项目结构

```text
Sources/                 Objective-C UI、HUD 和进程启动逻辑
Sources/LBState.*        可测试的低电量状态机
Tests/test_state.c       状态机单元测试
Resources/               Info.plist、权限和 App 图标
DEVICE_TEST.md           TrollStore 真机验收清单
Makefile                 测试、打包和产物检查
```

## 真机验收

详细步骤见 [DEVICE_TEST.md](DEVICE_TEST.md)，包括测试弹窗、真实低电量触发、重复通知处理和充电解除行为。
