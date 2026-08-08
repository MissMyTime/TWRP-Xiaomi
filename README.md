# TWRP Xiaomi Device Trees

## 分支说明

| 分支 | 设备 | 说明 |
|------|------|------|
| `main` | 通用 | 源码修改、README、文档 |
| `annibale` | 红米 K90 | 设备树 |
| `myron` | 红米 K90 Pro Max | 设备树 |
| `nezha` | 小米 17 Ultra | 设备树 |

## 编译说明

请从对应设备分支获取设备树，并在编译前把 `main/source_changes/files/` 覆盖到 TWRP 16 源码根目录。

```bash
rsync -a source_changes/files/ /path/to/twrp16/
```

## 分支内容

- **main**: 包含 `source_changes/` 目录，通用源码修改补丁和文件
- **annibale**: 红米 K90 完整设备树
- **myron**: 红米 K90 Pro Max 完整设备树
- **nezha**: 小米 17 Ultra 完整设备树

## 通用修改边界

- `main` 只保留安装、动态分区、Virtual A/B、MTP、USB、FBE 框架和界面等通用修改。
- 设备安全服务通过 `/system/bin/twrp-pre-decrypt.sh`、`twrp-decrypt-retry.sh` 和 `twrp-reboot-cleanup.sh` 按需接入。
- KeyMint、Weaver、WLAN 模块、USB 角色恢复和设备专属 init 服务必须放在对应设备分支。
- `source_changes/patches/` 与 `source_changes/files/` 内容保持同步，两种方式任选其一。
