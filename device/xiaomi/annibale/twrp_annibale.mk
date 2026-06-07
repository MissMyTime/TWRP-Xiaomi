# twrp_annibale.mk — Redmi K90 / annibale
# TWRP 16 on AOSP android-16.0.0_r1
# Android 16 / API 36 / SM8750 / sun
# SPDX-License-Identifier: Apache-2.0

DEVICE_PATH := device/xiaomi/annibale

$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/full_base_telephony.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/emulated_storage.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/virtual_ab_ota/compression_with_xor.mk)
$(call inherit-product, vendor/twrp/config/common.mk)
$(call inherit-product, $(DEVICE_PATH)/device.mk)

PRODUCT_RELEASE_NAME := annibale
PRODUCT_DEVICE := annibale
PRODUCT_NAME := twrp_annibale
PRODUCT_BRAND := Redmi
PRODUCT_MODEL := Redmi K90
PRODUCT_MANUFACTURER := Xiaomi
PRODUCT_PLATFORM := sun
PRODUCT_SHIPPING_API_LEVEL := 36

PRODUCT_BUILD_PROP_OVERRIDES += \
    PRIVATE_BUILD_DESC="annibale-user 16 BP2A.250605.031.A3 OS3.0.304.0.WPKCNXM release-keys"

BUILD_FINGERPRINT := Redmi/annibale/annibale:16/BP2A.250605.031.A3/OS3.0.304.0.WPKCNXM:user/release-keys
