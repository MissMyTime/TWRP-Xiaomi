# Xiaomi 17 Ultra / nezha TWRP 设备树改动说明

本设备树用于 Xiaomi 17 Ultra / nezha 的 TWRP 3.7.1 Android 16 适配。

## 当前状态

- 基础功能：可启动 TWRP，触摸、亮度、解密、MTP、ADB、WiFi、手电、振动均已适配。
- 分区形态：独立 recovery 分区，支持 `fastboot flash recovery recovery.img`。
- 目标系统：HyperOS 3 / Android 16，FBE metadata 加密，动态分区，Virtual A/B。
- 真解锁 BL 环境可正常刷入和使用。
- 假回锁 BL 环境依赖对应 ABL/GBL/AVB 信任链，不保证直接兼容第三方 recovery。

## 设备树内主要改动

### BoardConfig.mk

- 配置 nezha 基础板级参数、分辨率、亮度路径、温度路径、电池路径。
- 启用 FBE / metadata decrypt 相关选项，使 TWRP 可以解密 Android 16 的 `/data`。
- 增加 WiFi、MTP、ADB、fastbootd、dynamic partitions、recovery 独立分区等配置。
- 加载 recovery 所需 vendor modules，包括触摸、USB、WiFi、充电、电池、手电、haptics 等模块。
- 移除会导致振动卡顿或输入异常的 haptics blacklist 配置。

### recovery.fstab

- 按 nezha 实机分区调整 `/data`、`/metadata`、`/super`、`/misc` 等挂载项。
- 对 Android 16 FBE metadata 加密参数进行适配。
- 移除会触发 stock recovery 兼容性风险的部分自动 check / formattable 配置。
- 保留动态分区和 Virtual A/B 相关必要挂载信息。

### recovery/root/init.recovery.qcom.rc

- 加载 recovery 环境需要的 vendor kernel modules。
- 初始化 WiFi、USB、MTP、ADB 相关节点和目录。
- 修正部分 Android 16 init 不兼容语句，避免 `host_init_verifier` 编译失败。
- 调整 vendor / odm / firmware 挂载和 service 启动顺序。

### recovery/root/init.recovery.usb.rc

- 使用 configfs 方式配置 USB gadget。
- 修复 MTP 与 ADB 不能稳定切换的问题。
- 支持默认 ADB 在线，启用 MTP 后可传文件，关闭 MTP 后 ADB 能恢复。
- 使用小米 VID/PID 组合并绑定到设备实际 USB controller。

### prebuilt/system/etc/twrp.flags

- 增加 nezha 分区显示、备份、刷写标记。
- 修复 raw 分区备份项，避免 modem 等 busy 分区导致备份异常。
- 移除手动 `/super` raw 备份项，避免备份界面出现两个 Super。
- 保留动态 Super 逻辑，让 TWRP 自动显示 `Super` 备份项。

### WiFi 相关预置文件

- 添加 `iw`、`wpa_cli`、`wpa_supplicant`、WiFi 脚本和 WiFi vendor libraries。
- 添加 WiFi supplicant VINTF manifest。
- 添加 wlan/cfg80211/mac80211/qca_cld3 等模块，支持 recovery 内扫描和连接 WiFi。
- 修复第一次扫描为空、第二次扫描才出现网络的问题。

### sepolicy

- 补充 recovery 下访问 WiFi、USB、firmware、vendor service、sysfs 节点所需权限。
- 修复 recovery 编译时 CRLF / 非法字符导致的 `checkpolicy` 报错。

## bootable/recovery 源码侧配套改动

这些改动不在设备树目录内，但当前 recovery 镜像依赖它们。

### GUI / 主题

- 调整 nezha 挖孔屏状态栏布局，避免时间、CPU 温度、电量被摄像头遮挡。
- WiFi 页面按钮位置调整，避免底部按钮被导航栏遮挡。
- 添加 WiFi 状态栏图标。
- 高级扩展页添加作者信息：
  - 关注酷安：變換風雲
  - GitHub：MissMyTime
  - 基于 Team Win Recovery Project 开源项目
- 去除 QQ 群信息，减少发布包中的个人群号依赖。

### MTP / ADB

- 调整 USB gadget 切换逻辑，避免启用 MTP 后 ADB 永久掉线。
- 修复关闭 MTP 后 ADB 无法恢复的问题。
- 保持 recovery 默认 ADB 可用，MTP 需要时可手动启用。

### 振动

- 修改 `minuitwrp/events.cpp`，适配 nezha 实际 haptics input / ff-memless 路径。
- 修复点击振动无效问题。
- 避免错误 haptics 节点导致 UI 点击卡顿。

### ZIP / 卡刷

- 修复大体积 `super.img.zst` 通过 `unzip -p` 管道刷入时的输出逻辑。
- 解决 Android 16 / 6.1+ 内核环境下大 super 文件不能正常从 zip 流式刷入的问题。
- 官改包刷入时如果最后出现动态分区挂载红字，但上方显示安装成功，通常是刷完后 TWRP 尝试刷新挂载详情失败，不一定代表刷入失败；仍建议配合 recovery.log 判断。

### 备份 / 恢复

- 修复超大 Data 备份分卷数量超过 99 后失败的问题，将分卷上限扩展到 999。
- 修复备份失败后残留半成品备份目录的问题，失败时自动清理备份文件夹。
- 关闭 libtar 默认调试日志，避免 recovery.log / dmesg 日志过大。
- 调整动态 Super 显示名，避免 `Super (system system_ext product vendor)` 过长遮挡容量。

### APEX / 解密

- 调整 APEX 相关处理，避免解密流程中缺少 apex 或挂载顺序异常导致 FBE 解密卡住。
- 保持 Android 16 FBE metadata decrypt 所需环境。

## 构建说明

在 `/root/twrp16` 下执行：

```bash
source build/envsetup.sh
lunch twrp_nezha-bp2a-eng
mka recoveryimage -j$(nproc)
```

输出文件：

```text
out/target/product/nezha/recovery.img
```

## 发布注意事项

- 普通真解锁 BL 用户：推荐使用本 recovery。
- 假回锁 BL 用户：必须确认所用 ABL/GBL 信任链允许第三方 recovery，或使用对应签名链重新签名 recovery。仅修改 TWRP 设备树无法绕过强 AVB 校验。
- 刷入命令应使用：

```bash
fastboot flash recovery recovery.img
fastboot reboot recovery
```

不要使用 `fastboot flash recovery_ab recovery.img`，nezha 当前是独立 recovery 分区。
