# twrp_nezha.mk — Xiaomi 17 Ultra / nezha
# TWRP 16 on AOSP android-16.0.0_r1
# Android 16 / API 36 / SM8850 / canoe
# SPDX-License-Identifier: Apache-2.0

DEVICE_PATH := device/xiaomi/nezha

$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/full_base_telephony.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/emulated_storage.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/virtual_ab_ota/compression_with_xor.mk)
$(call inherit-product, vendor/twrp/config/common.mk)
$(call inherit-product, $(DEVICE_PATH)/device.mk)

PRODUCT_RELEASE_NAME := nezha
PRODUCT_DEVICE := nezha
PRODUCT_NAME := twrp_nezha
PRODUCT_BRAND := Xiaomi
PRODUCT_MODEL := Xiaomi 17 Ultra
PRODUCT_MANUFACTURER := Xiaomi
PRODUCT_PLATFORM := canoe
PRODUCT_SHIPPING_API_LEVEL := 36

PRODUCT_BUILD_PROP_OVERRIDES += \
    PRIVATE_BUILD_DESC="nezha-user 16 BP2A.250605.031.A3 OS3.0.303.0.WPACNXM release-keys"

BUILD_FINGERPRINT := Xiaomi/nezha/nezha:16/BP2A.250605.031.A3/OS3.0.303.0.WPACNXM:user/release-keys
