# Redmi K90 Pro Max / POCO F8 Ultra (myron)

本设备树用于 Myron 的 TWRP 3.7.1 Android 16 构建，目标系统为 HyperOS 3 / Android 16，支持 FBE、动态分区和 Virtual A/B。

## 当前状态

- Recovery：独立 A/B recovery 分区，镜像不包含内核。
- 解密：QTI KeyMint、NXP StrongBox/Weaver、Android 16 FBE。
- 存储：Data/Metadata 使用 F2FS，内部存储按 `/data/media` 处理。
- 连接：ADB、MTP、ADB Sideload、WLAN。
- 硬件：触摸、亮度、振动。
- 刷机：传统 update-binary、官方 A/B OTA、动态分区镜像。

## 2026-07-28 至 2026-07-29 修复

### 解密与存储

- 调整 NXP KeyMint/Weaver 启动顺序，降低官方系统和 AOSP 系统偶发卡解密、密码类型误判的概率。
- 解密成功后直接建立内部存储映射，避免递归扫描 `/data` 导致首页等待。
- 移除重复 USB-OTG 定义，避免内部存储被误显示为 USB-OTG。
- 区分 Data、Internal Storage、Dalvik/ART Cache 等虚拟项目；文件系统操作必须选择真实 Data 分区。
- 保留 Data、Metadata 的 F2FS 检查、修复和格式化工具。

### 安装、动态分区与格式化

- 补齐 `/sbin/sh`、`/sbin/bash`、`/sbin/bas`、`/sbin/getprop` 兼容路径。
- 修复官方 A/B 包成功前提前切换/准备动态分区的问题。
- 安装官方包前后校验 LP 元数据容量；仅对安全的单 Super 布局执行扩容并复核写入结果。
- 刷写 Super 镜像前先解除逻辑分区映射。
- Format Data 先在独立页面检查 Virtual A/B 快照状态，检查线程结束后再由用户确认格式化，避免黑屏和界面锁死。
- 删除重复 Sideload USB 状态触发，避免首次进入 Sideload 时 ADB 连接立即关闭。
- 安装阶段可切换性能策略，结束后恢复默认调度。

### WLAN、显示与振动

- WLAN 优先从当前槽位的 `system_dlkm`、`vendor_dlkm` 加载匹配模块，并保留 recovery 内置模块作为回退。
- DHCP 正确配置 IPv4、默认路由、DNS，并生成 `/tmp/recovery/wifi-dhcp.lease`。
- 修复首次点击异常振动及振动只生效一次的问题。
- 亮度节点使用 `panel0-backlight`，最大值保持真机验证的 `16383`。
- 简体中文界面下 Czech、Greek、Ukrainian 使用稳定英文显示名，语言内容不变。
- 增加 Myron 专属双鱼开屏图标。

## 2026-08-04 修复

- 补齐官方 Myron Global vendor 中的 QTI KeyMint 运行依赖，并恢复 KeyMint、Gatekeeper 的 stock 服务身份。
- 保持 QTI + NXP 解密服务顺序；Evolution X 17 仅在 fscrypt 策略匹配时进入解密。
- 解密成功后单次自动启动 MTP；EvoX 下增加短时 USB gadget 状态恢复。
- U 盘使用结束后恢复 peripheral 模式及原有 ADB/MTP 组合，隐藏空的 USB-OTG 父项并保留真实分区。
- 修正 CPU 温度节点，EvoX 解密后按 ATS 偏移恢复 recovery 时间。
- Fastbootd 菜单改用经回读验证的 BCB 请求。
- Format Data 三态保护：`none` 正常允许；`merging` 禁止绕过；其他快照状态需“类原生／强制格式化”二次确认。

## 2026-08-08 修复

- Persist 统一挂载到 `/mnt/vendor/persist`，并以 `/persist` 软链接兼容旧安装器，避免分区刷新和 GApps 安装结束时重复挂载报错。
- USB-OTG 进入 host 模式前解除 UDC 绑定，退出后恢复原有 ADB/MTP 组合；组合恢复失败时回退到 ADB，避免拔出 U 盘后连接丢失。
- MTP 守护在 host 模式下暂停，防止 USB gadget 与 U 盘争用控制器。
- USB-OTG 父项不再作为普通存储显示，保留 U 盘实际分区；界面统一显示为 `USB-OTG`。
- 通用源码改用标准设备钩子，设备安全服务、解密重试与重启清理由各设备树单独提供。

## 构建

```bash
cd /root/twrp16

git clone --depth=1 -b main \
    https://github.com/MissMyTime/TWRP-Xiaomi.git /tmp/twrp-common
rsync -a /tmp/twrp-common/source_changes/files/ ./

git clone --depth=1 -b myron \
    https://github.com/MissMyTime/TWRP-Xiaomi.git /tmp/twrp-myron
mkdir -p device/xiaomi/myron
rsync -a /tmp/twrp-myron/device/xiaomi/myron/ device/xiaomi/myron/

source build/envsetup.sh
lunch twrp_myron-bp2a-eng
m recoveryimage
```

输出文件：

```text
out/target/product/myron/recovery.img
```

也可以在 `myron` 分支的 Actions 页面手动运行构建工作流。

## 刷入

```bash
adb reboot bootloader
fastboot getvar current-slot
fastboot --slot=b flash recovery recovery.img
fastboot reboot recovery
```

当前槽位为 `b` 时，把 `--slot=b` 改为 `--slot=a`。本镜像为 ramdisk-only recovery，不支持 `fastboot boot recovery.img`。

## 维护边界

- Myron 的安全服务、解密与 USB 脚本仅保留在本设备树，不与其他设备共用。
- Format Data 的 Virtual A/B 检查必须保持为独立 GUI 阶段，不能在 recovery 主线程中无限等待 BootControl 服务。
- 更新固件安全补丁级别后，应重新验证 KeyMint、Weaver、WLAN 模块和 FBE 解密。
