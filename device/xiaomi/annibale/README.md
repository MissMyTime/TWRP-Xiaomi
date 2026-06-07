# Redmi K90 / annibale TWRP 设备树改动说明

本设备树用于 Redmi K90 / annibale 的 TWRP 3.7.1 Android 16 适配，基于已提取的官方 OS3.0.304.0.WPKCNXM 运行环境整理。

## 当前整理内容

- 设备身份改为 `annibale / sun / SM8750`，清理从 myron 继承来的 `canoe`、`peach`、`focaltech` 等错误残留。
- fstab 使用官方 `fstab.qcom` 的 Android 16 FBE metadata 加密参数：`wrappedkey_v0`、`metadata_encryption=aes-256-xts:wrappedkey_v0`、`checkpoint=fs`。
- 解密链切到 K90 的 NXP eSE / Weaver：`vendor.secure_element` -> `se_omapi` -> `vendor.weaver_nxp`。
- 仅保留 ODM 侧 NXP Weaver / StrongBox init，删除错误的 vendor 侧重复 NXP init 定义，避免 init 服务冲突。
- WiFi 切换为 K90 的 `qca_cld3_kiwi_v2.ko` 与 `vendor/etc/wifi/kiwi_v2/WCNSS_qcom_cfg.ini`。
- `vendor_dlkm` 只打包 recovery 必需模块，避免完整 3GB 模块集塞入 recovery。
- 移除不存在的 `/soccp` 备份项，避免备份页面出现无效分区。

## 本地编译

```bash
cd /root/twrp16
source build/envsetup.sh
lunch twrp_annibale-bp2a-eng
mka recoveryimage -j$(nproc)
```

输出路径：`out/target/product/annibale/recovery.img`。
