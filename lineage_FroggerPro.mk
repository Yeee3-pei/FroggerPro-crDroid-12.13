#
# SPDX-FileCopyrightText: The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#

$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit_only.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/generic_system.mk)

$(call inherit-product, $(SRC_TARGET_DIR)/product/handheld_product.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/telephony_product.mk)

$(call inherit-product, $(SRC_TARGET_DIR)/product/handheld_system_ext.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/telephony_system_ext.mk)

$(call inherit-product, $(SRC_TARGET_DIR)/product/handheld_vendor.mk)

$(call inherit-product, device/nothing/froggerPro/device.mk)
$(call inherit-product, vendor/lineage/config/common_full_phone.mk)

# microG's signature spoofing is upstream LineageOS behaviour (frameworks/base
# ComputerEngine.isMicrogSigned) and is gated on isDebuggable(), which reads ro.debuggable.
# vendor/lineage/config/common.mk ties that property to WITH_ADB_INSECURE through
# PRODUCT_NOT_DEBUGGABLE_IN_USERDEBUG, so a build that keeps adb authentication lands at
# ro.debuggable=0 and upstream's check can never pass. Clearing the variable here, after the
# vendor/lineage inherit, takes the AOSP userdebug default instead; adb authentication is
# untouched (ro.adb.secure stays 1).
#
# Cost: the debug-oriented userdebug_or_eng() SELinux conditionals apply again, and a shell
# without root can read dmesg and use the debug tooling. That is the AOSP userdebug default,
# which LineageOS narrows deliberately; this port trades it for working signature spoofing.
# Left empty, NOT := false. build/make/core/soong_extra_config.mk hands the raw value to
# add_json_bool, which takes any non-empty string as true, so ":=" false kept the restriction
# on and ro.debuggable stayed 0. Empty is what "not set" means here.
PRODUCT_NOT_DEBUGGABLE_IN_USERDEBUG :=

PRODUCT_BRAND := Nothing
PRODUCT_DEVICE := FroggerPro
PRODUCT_MANUFACTURER := Nothing
PRODUCT_MODEL := A069P
PRODUCT_NAME := lineage_FroggerPro

PRODUCT_GMS_CLIENTID_BASE := android-nothing

PRODUCT_BUILD_PROP_OVERRIDES += \
    BuildDesc="qssi_64-user 16 BQ2A.250913.001-BP2A.250605.031.A3 2609071153 release-keys" \
    BuildFingerprint=Nothing/FroggerPro/FroggerPro:16/BQ2A.250913.001-BP2A.250605.031.A3/2609071153:user/release-keys \
    DeviceName=FroggerPro \
    DeviceProduct=FroggerPro \
    SystemDevice=FroggerPro \
    SystemName=FroggerPro

# The privacy app belongs to the privacy variant only (lineage_FroggerPro_privacy.mk), so this
# product stays a plain LineageOS build.