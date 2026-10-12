#
# SPDX-FileCopyrightText: The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#

$(call inherit-product, hardware/qcom-caf/common/common.mk)
$(call inherit-product, vendor/nothing/FroggerPro/FroggerPro-vendor.mk)
# Blobs present in the stock image but not installed by the vendor makefile above. The vintf
# fragments are excluded here because VINTF metadata cannot go through PRODUCT_COPY_FILES.
$(call inherit-product-if-exists, vendor/nothing/FroggerPro/extra_vendor_blobs.mk)
# Modules that out/soong/installs-*.mk already has an install rule for but that are missing from
# the vendor image: installed as packages, not copies, since Soong owns those destinations.
$(call inherit-product-if-exists, vendor/nothing/FroggerPro/extra_product_packages.mk)
# Vendor variants of the same modules, built with the .vendor suffix so they land in vendor.
$(call inherit-product-if-exists, vendor/nothing/FroggerPro/extra_vendor_variant.mk)

# The stock vendor image is the reference for what is missing, not this ROM's previous build,
# which only shows the difference against itself.
# extra_vendor_fill.mk and extra_vendor_fill_pkgs.mk are deliberately not inherited: 1,030 copies
# plus 61 modules stops the device at the logo with no adb, while the same copies with 0 modules
# boots. Adding module names to PRODUCT_PACKAGES makes Soong rebuild them from source instead of
# shipping the vendor binaries, which yields different binaries and missing dependencies.

# Display and GPU stack taken from the stock blobs. With no copy rules the image carries the
# source-built stack, whose libsdmcore aborts the composer and takes SurfaceFlinger down with it.
# A prefer: true prebuilt module replaces the source build with no duplicate-output clash.
$(call inherit-product-if-exists, vendor/nothing/FroggerPro/display_prebuilts.mk)
# Face unlock SDK licence file: the Nothing face HAL reads /vendor/etc/license.lic directly and
# fails registration without it.
$(call inherit-product-if-exists, vendor/nothing/FroggerPro/extra_face_license.mk)
# The three top-level Adreno names under /vendor/lib64 are symlinks into lib64/egl/. Their rules
# live in this directory's Android.mk, because $(TARGET_OUT_VENDOR) is undefined while product
# makefiles are parsed.

# A/B
# virtual A/B is deliberately not enabled. The stock super and the builds that boot carry
# metadata version 10.0, two slots and no virtual_ab_device header flag; inheriting
# vabc_features.mk produces version 10.2, three slots and that flag, which the bootloader does
# not understand.

AB_OTA_POSTINSTALL_CONFIG += \
    RUN_POSTINSTALL_system=true \
    POSTINSTALL_PATH_system=system/bin/otapreopt_script \
    FILESYSTEM_TYPE_system=erofs \
    POSTINSTALL_OPTIONAL_system=true

AB_OTA_POSTINSTALL_CONFIG += \
    RUN_POSTINSTALL_vendor=true \
    POSTINSTALL_PATH_vendor=bin/checkpoint_gc \
    FILESYSTEM_TYPE_vendor=erofs \
    POSTINSTALL_OPTIONAL_vendor=true

PRODUCT_PACKAGES += \
    checkpoint_gc \
    otapreopt_script

# No PRODUCT_VIRTUAL_AB_COMPRESSION_METHOD: the setting only applies to virtual A/B.

# API
PRODUCT_SHIPPING_API_LEVEL := 36
# Must not be removed: it drives the hardware/lineage/compat vendorcompat module names, and
# without it soong fails with "module ... already defined". The retrofit flag therefore lives in
# BoardConfig.mk, which is read after config.mk's guard.

# ART
PRODUCT_ENABLE_UFFD_GC := true

# Adreno
PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/android.hardware.opengles.aep.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.opengles.aep.xml \
    frameworks/native/data/etc/android.hardware.vulkan.compute-0.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.vulkan.compute-0.xml \
    frameworks/native/data/etc/android.hardware.vulkan.level-1.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.vulkan.level-1.xml \
    frameworks/native/data/etc/android.hardware.vulkan.version-1_1.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.vulkan.version-1_1.xml \
    frameworks/native/data/etc/android.hardware.vulkan.version-1_3.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.vulkan.version-1_3.xml \
    frameworks/native/data/etc/android.software.opengles.deqp.level-2023-03-01.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.software.opengles.deqp.level.xml \
    frameworks/native/data/etc/android.software.vulkan.deqp.level-2023-03-01.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.software.vulkan.deqp.level.xml

# Audio
PRODUCT_PACKAGES += \
    audio.bluetooth.default \
    audio.r_submix.default \
    audio.usbv2.default \
    libhapticgenerator \
    qtiaudiohalvendorextn \
    qti-audio-types-aidl-V1-ndk.vendor

PRODUCT_PACKAGES += \
    android.hardware.soundtrigger3-V1-ndk.vendor \
    android.hardware.audio.effect-V2-ndk.vendor \
    android.media.audio.common.types-V3-ndk.vendor \
    android.hardware.audio.common-V1-ndk.vendor \
    android.hardware.audio.core-V2-ndk.vendor \
    android.hardware.audio.core.sounddose-V3-ndk.vendor \
    android.hardware.audio.core.sounddose-V1-ndk.vendor \
    libalsautilsv2.vendor \
    libaudioaidlcommon.vendor \
    libaudioutils_shim \
    libmediautils_vendor.vendor \
    libmemunreachable.vendor

AUDIO_HAL_DIR := hardware/qcom-caf/sm8750/audio/primary-hal
CONFIG_HAL_SRC_DIR := $(AUDIO_HAL_DIR)/configs/sun
CONFIG_PAL_SRC_DIR := $(AUDIO_HAL_DIR)/../pal/configs/sun

# The stock image ships two audio_policy_configuration.xml files: a 16,971 byte one in
# /vendor/etc that xi:includes default_volume_tables.xml, and a 9,999 byte SKU one under
# sku_kera/. The SKU file had been installed in the full version's place, so the volume tables
# were never included and every stream's maximum volume came out as 0. Below, the full version is
# copied from the stock image and the SKU file keeps its own path and contents.
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/conf/audio/audio_module_config_primary.xml:$(TARGET_COPY_OUT_VENDOR)/etc/audio/audio_module_config_primary.xml \
    $(LOCAL_PATH)/conf/audio/mixer_paths_kera_qrd.xml:$(TARGET_COPY_OUT_VENDOR)/etc/audio/sku_kera/mixer_paths_kera_qrd.xml \
    $(LOCAL_PATH)/conf/audio/resourcemanager_kera_qrd.xml:$(TARGET_COPY_OUT_VENDOR)/etc/audio/sku_kera/resourcemanager_kera_qrd.xml \
    $(LOCAL_PATH)/conf/audio/quasar_config.xml:$(TARGET_COPY_OUT_VENDOR)/etc/audio/sku_kera/quasar_config.xml \
    $(LOCAL_PATH)/conf/audio/default_volume_tables.xml:$(TARGET_COPY_OUT_VENDOR)/etc/audio/sku_kera/default_volume_tables.xml \
    $(LOCAL_PATH)/conf/audio/default_volume_tables.xml:$(TARGET_COPY_OUT_VENDOR)/etc/default_volume_tables.xml \
    $(LOCAL_PATH)/conf/audio/usecaseKvManager.xml:$(TARGET_COPY_OUT_VENDOR)/etc/usecaseKvManager.xml \
    $(LOCAL_PATH)/conf/audio/audio_policy_volumes.xml:$(TARGET_COPY_OUT_VENDOR)/etc/audio/sku_kera/audio_policy_volumes.xml \
    $(LOCAL_PATH)/conf/audio/audio_policy_configuration.xml:$(TARGET_COPY_OUT_VENDOR)/etc/audio/sku_kera/audio_policy_configuration.xml \
    vendor/nothing/FroggerPro/etc/audio_policy_configuration.xml:$(TARGET_COPY_OUT_VENDOR)/etc/audio_policy_configuration.xml \
    $(LOCAL_PATH)/conf/audio/audio_effects.conf:$(TARGET_COPY_OUT_VENDOR)/etc/audio/sku_kera/audio_effects.conf \
    $(LOCAL_PATH)/conf/audio/audio_effects.xml:$(TARGET_COPY_OUT_VENDOR)/etc/audio/sku_kera/audio_effects.xml \
    $(LOCAL_PATH)/conf/audio/audio_effects.xml:$(TARGET_COPY_OUT_VENDOR)/etc/audio_effects.xml \
    $(LOCAL_PATH)/conf/audio/audio_effects_config.xml:$(TARGET_COPY_OUT_VENDOR)/etc/audio/audio_effects_config.xml \
    $(LOCAL_PATH)/conf/audio/backend_conf.xml:$(TARGET_COPY_OUT_VENDOR)/etc/backend_conf.xml

PRODUCT_COPY_FILES += \
    $(CONFIG_HAL_SRC_DIR)/mem_logger_config.xml:$(TARGET_COPY_OUT_VENDOR)/etc/mem_logger_config.xml \
    $(CONFIG_HAL_SRC_DIR)/microphone_characteristics.xml:$(TARGET_COPY_OUT_VENDOR)/etc/microphone_characteristics.xml \
    $(CONFIG_HAL_SRC_DIR)/vendor_audio_interfaces.xml:$(TARGET_COPY_OUT_VENDOR)/etc/audio/vendor_audio_interfaces.xml \
    $(CONFIG_PAL_SRC_DIR)/Hapticsconfig.xml:$(TARGET_COPY_OUT_VENDOR)/etc/Hapticsconfig.xml \
    $(CONFIG_PAL_SRC_DIR)/card-defs.xml:$(TARGET_COPY_OUT_VENDOR)/etc/card-defs.xml

PRODUCT_COPY_FILES += \
    frameworks/av/services/audiopolicy/config/stub_audio_policy_configuration.xml:$(TARGET_COPY_OUT_VENDOR)/etc/stub_audio_policy_configuration.xml \
    frameworks/av/services/audiopolicy/config/a2dp_audio_policy_configuration.xml:$(TARGET_COPY_OUT_VENDOR)/etc/a2dp_audio_policy_configuration.xml \
    frameworks/av/services/audiopolicy/config/r_submix_audio_policy_configuration.xml:$(TARGET_COPY_OUT_VENDOR)/etc/audio/sku_kera/r_submix_audio_policy_configuration.xml \
    frameworks/av/services/audiopolicy/config/r_submix_audio_policy_configuration.xml:$(TARGET_COPY_OUT_VENDOR)/etc/r_submix_audio_policy_configuration.xml \
    frameworks/av/services/audiopolicy/config/usb_audio_policy_configuration.xml:$(TARGET_COPY_OUT_VENDOR)/etc/usb_audio_policy_configuration.xml
    
PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/android.hardware.audio.low_latency.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.audio.low_latency.xml \
    frameworks/native/data/etc/android.hardware.audio.pro.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.audio.pro.xml \
    frameworks/native/data/etc/android.hardware.sensor.dynamic.head_tracker.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.sensor.dynamic.head_tracker.xml \
    frameworks/native/data/etc/android.software.midi.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.software.midi.xml

# AxionFX
$(call inherit-product-if-exists, packages/apps/AxionFx/config.mk)

# Bluetooth
PRODUCT_PACKAGES += \
    android.hardware.bluetooth.audio-impl \
    android.hardware.bluetooth.audio-V4-ndk.vendor

PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/android.hardware.bluetooth_le.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.bluetooth_le.xml \
    frameworks/native/data/etc/android.hardware.bluetooth.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.bluetooth.xml

# Biometrics
PRODUCT_PACKAGES += \
    android.hardware.biometrics.fingerprint-service.nothing

$(call soong_config_set_bool,nothing_fingerprint,use_lhbm,true)

PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/android.hardware.fingerprint.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.fingerprint.xml

# Boot Control
PRODUCT_PACKAGES += \
    android.hardware.boot-service.qti \
    android.hardware.boot-service.qti.recovery

# Camera
PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/android.hardware.camera.concurrent.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.camera.concurrent.xml \
    frameworks/native/data/etc/android.hardware.camera.flash-autofocus.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.camera.flash-autofocus.xml \
    frameworks/native/data/etc/android.hardware.camera.front.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.camera.front.xml \
    frameworks/native/data/etc/android.hardware.camera.full.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.camera.full.xml \
    frameworks/native/data/etc/android.hardware.camera.raw.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.camera.raw.xml

PRODUCT_PACKAGES += \
    vendor.qti.hardware.display.config-V2-ndk.vendor

# DRM
PRODUCT_PACKAGES += \
    android.hardware.drm-service.clearkey

# Dalvik
$(call inherit-product, frameworks/native/build/phone-xhdpi-6144-dalvik-heap.mk)

# DeviceExtras
PRODUCT_PACKAGES += \
    DeviceExtras

# Display
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/conf/display/display_id_4630947050240568210.xml:$(TARGET_COPY_OUT_VENDOR)/etc/displayconfig/display_id_4630947050240568210.xml \
    frameworks/native/data/etc/android.hardware.touchscreen.multitouch.jazzhand.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.touchscreen.multitouch.jazzhand.xml \
    hardware/qcom-caf/sm8750/display/core/config/sdm_display_resolution_extn.xml:$(TARGET_COPY_OUT_VENDOR)/etc/display/sdm_display_resolution_extn.xml \
    hardware/qcom-caf/sm8750/display/core/snapalloc/resources/camera_alignments.json:$(TARGET_COPY_OUT_VENDOR)/etc/display/camera_alignments.json \
    hardware/qcom-caf/sm8750/display/core/snapalloc/resources/cpu_alignments.json:$(TARGET_COPY_OUT_VENDOR)/etc/display/cpu_alignments.json \
    hardware/qcom-caf/sm8750/display/core/snapalloc/resources/default_alignments.json:$(TARGET_COPY_OUT_VENDOR)/etc/display/default_alignments.json \
    hardware/qcom-caf/sm8750/display/core/snapalloc/resources/display_alignments.json:$(TARGET_COPY_OUT_VENDOR)/etc/display/display_alignments.json \
    hardware/qcom-caf/sm8750/display/core/snapalloc/resources/formats.json:$(TARGET_COPY_OUT_VENDOR)/etc/display/formats.json \
    hardware/qcom-caf/sm8750/display/core/snapalloc/resources/graphics_alignments.json:$(TARGET_COPY_OUT_VENDOR)/etc/display/graphics_alignments.json \
    hardware/qcom-caf/sm8750/display/core/snapalloc/resources/ubwc_alignments.json:$(TARGET_COPY_OUT_VENDOR)/etc/display/ubwc_alignments.json \
    hardware/qcom-caf/sm8750/display/core/snapalloc/resources/video_alignments.json:$(TARGET_COPY_OUT_VENDOR)/etc/display/video_alignments.json

PRODUCT_PACKAGES += \
    android.hardware.graphics.mapper@4.0-impl-qti-display \
    init.qti.display_boot.rc \
    init.qti.display_boot.sh \
    libqdMetaData \
    vendor.qti.hardware.display.allocator-service \
    vendor.qti.hardware.display.composer-service \
    vendor.qti.hardware.display.demura-service \
    vendor.qti.hardware.display.snapalloc-impl \
    vendor.qti.hardware.memtrack-service

# eUICC
$(foreach sku, EEA JPN ROW TUR, \
    $(eval PRODUCT_COPY_FILES += \
        frameworks/native/data/etc/android.hardware.telephony.euicc.xml:$(TARGET_COPY_OUT_ODM)/etc/permissions/sku_$(sku)/android.hardware.telephony.euicc.xml))

PRODUCT_PACKAGES += \
    EuiccPolicy \
    NothingEsimSwitcher

# Fastboot
PRODUCT_PACKAGES += \
    fastbootd

# FeliCa
PRODUCT_PACKAGES += \
    NothingFelicaDisabler

# GPS
PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/android.hardware.location.gps.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.location.gps.xml

# Graphics
PRODUCT_PACKAGES += \
    android.hardware.graphics.allocator-V1-ndk.vendor
    
# Glyph
PRODUCT_PACKAGES += \
    HieroGlyphFroggerPro

# HIDL
PRODUCT_HIDL_ENABLED := true

PRODUCT_PACKAGES += \
    android.hidl.allocator@1.0-service \
    android.hidl.memory@1.0-impl \
    hwservicemanager

# Handheld
PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/handheld_core_hardware.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/handheld_core_hardware.xml

# Health
PRODUCT_PACKAGES += \
    android.hardware.health-service.qti \
    android.hardware.health-service.qti_recovery

# IPA
PRODUCT_PACKAGES += \
    IPACM_Filter_cfg.xml \
    IPACM_cfg.xml \
    ipacm

# Init
# The fstab has to sit under first_stage_ramdisk/ in the vendor ramdisk, or first-stage init
# cannot find /super and the device stops at the logo with no USB. The stock vendor ramdisk
# carries first_stage_ramdisk/fstab.default there, and device/google/trout/aosp_trout_common.mk
# uses the same shape.
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/init/fstab.default:$(TARGET_COPY_OUT_VENDOR_RAMDISK)/first_stage_ramdisk/fstab.default

PRODUCT_PACKAGES += \
    fstab.default \
    fstab.default.vendor_ramdisk \
    fstab.zram.4g \
    init.class_main.sh \
    init.froggerpro.rc \
    init.qcom.early_boot.sh \
    init.qcom.post_boot.sh \
    init.qcom.rc \
    init.qcom.recovery.rc \
    init.qcom.sh \
    init.target.rc \
    ueventd.froggerpro.rc \
    ueventd.qcom.rc

# Keylayout
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/conf/keylayout/gpio-keys.kl:$(TARGET_COPY_OUT_VENDOR)/usr/keylayout/gpio-keys.kl

# Keymint
PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/android.hardware.keystore.app_attest_key.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.keystore.app_attest_key.xml \
    frameworks/native/data/etc/android.software.device_id_attestation.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.software.device_id_attestation.xml

PRODUCT_PACKAGES += \
    android.hardware.hardware_keystore_V3.xml

PRODUCT_PACKAGES += \
    vendor.lineage.health-service.default

# LiveDisplay
$(call soong_config_set_bool,livedisplay_sdm,enable_dm,false)

PRODUCT_PACKAGES += \
    vendor.lineage.livedisplay-service.sdm

# Media
PRODUCT_COPY_FILES += \
    frameworks/av/media/libstagefright/data/media_codecs_google_audio.xml:$(TARGET_COPY_OUT_VENDOR)/etc/media_codecs_google_audio.xml \
    frameworks/av/media/libstagefright/data/media_codecs_google_c2.xml:$(TARGET_COPY_OUT_VENDOR)/etc/media_codecs_google_c2.xml \
    frameworks/av/media/libstagefright/data/media_codecs_google_c2_audio.xml:$(TARGET_COPY_OUT_VENDOR)/etc/media_codecs_google_c2_audio.xml \
    frameworks/av/media/libstagefright/data/media_codecs_google_c2_video.xml:$(TARGET_COPY_OUT_VENDOR)/etc/media_codecs_google_c2_video.xml \
    frameworks/av/media/libstagefright/data/media_codecs_google_telephony.xml:$(TARGET_COPY_OUT_VENDOR)/etc/media_codecs_google_telephony.xml

# NFC
PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/android.hardware.nfc.hcef.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.nfc.hcef.xml \
    frameworks/native/data/etc/android.hardware.nfc.hce.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.nfc.hce.xml \
    frameworks/native/data/etc/android.hardware.nfc.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.nfc.xml \
    frameworks/native/data/etc/com.android.nfc_extras.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/com.android.nfc_extras.xml \
    frameworks/native/data/etc/com.nxp.mifare.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/com.nxp.mifare.xml

PRODUCT_PACKAGES += \
    android.hardware.nfc-service.st

# Overlays
PRODUCT_ENFORCE_RRO_TARGETS := *

DEVICE_PACKAGE_OVERLAYS += \
    $(LOCAL_PATH)/overlay-lineage

PRODUCT_PACKAGES += \
    FroggerProApertureDevOverlay \
    FroggerProApertureOverlay \
    FroggerProEuiccOverlay \
    FroggerProFrameworksOverlay \
    FroggerProSettingsOverlay \
    FroggerProSettingsProviderOverlay \
    FroggerProSystemUIOverlay \
    FroggerProTelecommOverlay \
    FroggerProTelephonyOverlay \
    FroggerProWifiOverlay

# Page Size
PRODUCT_CHECK_PREBUILT_MAX_PAGE_SIZE := false

# Partitions
PRODUCT_BUILD_RECOVERY_IMAGE := true
PRODUCT_USE_DYNAMIC_PARTITIONS := true


PRODUCT_PACKAGES += \
    vendor_bt_firmware_mountpoint \
    vendor_dsp_mountpoint \
    vendor_firmware_mnt_mountpoint

# Power
PRODUCT_PACKAGES += \
    android.hardware.power-service.lineage-libperfmgr \
    libqti-perfd-client

PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/conf/powerhint.json:$(TARGET_COPY_OUT_VENDOR)/etc/powerhint.json

# Properties
TARGET_ODM_PROP += $(DEVICE_PATH)/odm.prop
TARGET_PRODUCT_PROP += $(DEVICE_PATH)/product.prop
TARGET_SYSTEM_EXT_PROP += $(DEVICE_PATH)/system_ext.prop
TARGET_VENDOR_PROP += $(DEVICE_PATH)/vendor.prop

# Project ID Quota
$(call inherit-product, $(SRC_TARGET_DIR)/product/emulated_storage.mk)

# QSPA
PRODUCT_PACKAGES += \
    qspa_vendor.rc \
    vendor.qti.qspa-service

# Ramdisk
$(call inherit-product, $(SRC_TARGET_DIR)/product/generic_ramdisk.mk)

# Secure Element
PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/android.hardware.nfc.ese.xml:$(TARGET_COPY_OUT_ODM)/etc/permissions/sku_JPN/android.hardware.nfc.ese.xml \
    frameworks/native/data/etc/android.hardware.se.omapi.ese.xml:$(TARGET_COPY_OUT_ODM)/etc/permissions/sku_JPN/android.hardware.se.omapi.ese.xml \
    frameworks/native/data/etc/android.hardware.se.omapi.uicc.xml:$(TARGET_COPY_OUT_ODM)/etc/permissions/sku_JPN/android.hardware.se.omapi.uicc.xml

# Security
# Each value states when that partition's contents were last updated. The vendor partition
# carries Nothing's blobs from the B4.1-260907-1153 stock release, so it keeps that release's
# date; only a new stock release can move it forward.
BOOT_SECURITY_PATCH := 2026-09-01
INIT_BOOT_SECURITY_PATCH := $(PLATFORM_SECURITY_PATCH)
ODM_SECURITY_PATCH := $(PLATFORM_SECURITY_PATCH)
SYSTEM_DLKM_SECURITY_PATCH := $(BOOT_SECURITY_PATCH)
VENDOR_DLKM_SECURITY_PATCH := 2026-03-05
VENDOR_SECURITY_PATCH := 2026-04-05

# Sensors
PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/android.hardware.sensor.accelerometer.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/sku_kera/android.hardware.sensor.accelerometer.xml \
    frameworks/native/data/etc/android.hardware.sensor.dynamic.head_tracker.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/sku_kera/android.hardware.sensor.dynamic.head_tracker.xml \
    frameworks/native/data/etc/android.hardware.sensor.compass.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/sku_kera/android.hardware.sensor.compass.xml \
    frameworks/native/data/etc/android.hardware.sensor.stepcounter.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/sku_kera/android.hardware.sensor.stepcounter.xml \
    frameworks/native/data/etc/android.hardware.sensor.proximity.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/sku_kera/android.hardware.sensor.proximity.xml \
    frameworks/native/data/etc/android.hardware.sensor.stepdetector.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/sku_kera/android.hardware.sensor.stepdetector.xml \
    frameworks/native/data/etc/android.hardware.sensor.light.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/sku_kera/android.hardware.sensor.light.xml \
    frameworks/native/data/etc/android.hardware.sensor.gyroscope.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/sku_kera/android.hardware.sensor.gyroscope.xml

TP_SYSFS_PATH := /sys/devices/platform/soc/8c0000.qcom,qupv3_2_geni_se/880000.spi/spi_master/spi8/spi8.0

$(call soong_config_set,nothing_sensors,tp_single_tap_path,$(TP_SYSFS_PATH)/fts_gesture_single_tap_pressed)
$(call soong_config_set,nothing_sensors,tp_single_tap_enabled_path,$(TP_SYSFS_PATH)/fts_gesture_single_tap_enabled)
$(call soong_config_set,nothing_sensors,tp_single_tap_coords_path,/proc/touchpanel/gesture_code)

$(call soong_config_set,nothing_sensors,tp_udfps_path,$(TP_SYSFS_PATH)/fts_fod_pressed)

PRODUCT_PACKAGES += \
    sensors.nothing \
    sensors.dynamic_sensor_hal

# SKUs
$(foreach sku, EEA JPN IND TUR, \
    $(eval PRODUCT_COPY_FILES += \
        $(LOCAL_PATH)/sku/build_$(sku).prop:$(TARGET_COPY_OUT_ODM)/etc/build_$(sku).prop))
        
# Soong
PRODUCT_SOONG_NAMESPACES += \
    $(LOCAL_PATH) \
    hardware/google/interfaces \
    hardware/google/pixel \
    hardware/lineage/interfaces/power-libperfmgr \
    hardware/qcom-caf/common/libqti-perfd-client \
    vendor/nothing/FroggerPro \
    vendor/nothing/NanoGlyph \
    packages/apps/HieroGlyph \
    packages/apps/GlyphBridge

# Storage
PRODUCT_CHARACTERISTICS := nosdcard

# Telephony
PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/android.hardware.telephony.cdma.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.telephony.cdma.xml \
    frameworks/native/data/etc/android.hardware.telephony.gsm.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.telephony.gsm.xml \
    frameworks/native/data/etc/android.hardware.telephony.ims.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.telephony.ims.xml \
    frameworks/native/data/etc/android.hardware.telephony.mbms.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.telephony.mbms.xml \
    frameworks/native/data/etc/android.software.sip.voip.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.software.sip.voip.xml

PRODUCT_PACKAGES += \
    extphonelib \
    extphonelib-product \
    extphonelib.xml \
    extphonelib_product.xml \
    ims-ext-common \
    ims_ext_common.xml \
    qti-telephony-hidl-wrapper \
    qti-telephony-hidl-wrapper-prd \
    qti-telephony-utils \
    qti_telephony_hidl_wrapper.xml \
    qti_telephony_hidl_wrapper_prd.xml \
    qti_telephony_utils.xml \
    telephony-ext

PRODUCT_BOOT_JARS += \
    telephony-ext

# Thermal
PRODUCT_PACKAGES += \
    android.hardware.thermal-service.qti

# USB
PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/android.hardware.usb.accessory.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.usb.accessory.xml \
    frameworks/native/data/etc/android.hardware.usb.host.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.usb.host.xml

PRODUCT_PACKAGES += \
    android.hardware.usb.gadget-service.qti \
    android.hardware.usb-service.qti \
    init.qcom.usb.rc \
    init.qcom.usb.sh \
    usb_compositions.conf

PRODUCT_SOONG_NAMESPACES += \
    vendor/qcom/opensource/usb/etc

# Update Engine
PRODUCT_PACKAGES += \
    update_engine \
    update_engine_sideload \
    update_verifier

# Vendor Service Manager
PRODUCT_PACKAGES += \
    vndservicemanager

# Verified Boot
PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/android.software.verified_boot.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.software.verified_boot.xml

# Vibrator
# Uses the vendor blob rather than a same-named source build, which makes init drop every
# service of that name.

# Wi-Fi
PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/android.hardware.wifi.aware.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.wifi.aware.xml \
    frameworks/native/data/etc/android.hardware.wifi.direct.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.wifi.direct.xml \
    frameworks/native/data/etc/android.hardware.wifi.passpoint.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.wifi.passpoint.xml \
    frameworks/native/data/etc/android.hardware.wifi.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.wifi.xml \
    frameworks/native/data/etc/android.software.ipsec_tunnels.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.software.ipsec_tunnels.xml

PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/conf/wifi/WCNSS_qcom_cfg.ini:$(TARGET_COPY_OUT_VENDOR)/etc/wifi/qca6750/WCNSS_qcom_cfg.ini

PRODUCT_PACKAGES += \
    android.hardware.wifi-service \
    firmware_WCNSS_qcom_cfg.ini_symlink \
    firmware_wlanmdsp.otaupdate_symlink \
    firmware_wlan_mac.bin_symlink \
    hostapd \
    libwifi-hal-ctrl \
    libwifi-hal-qcom \
    wpa_supplicant \
    wpa_supplicant.conf


# Diagnostics that have to survive the update: an always-on logcatd is the only way a first-stage
# failure is observed on this device (there is no USB until the framework comes up), and MTP lets
# files off the phone. No WITH_ADB_INSECURE: this follows the LineageOS default, so ro.adb.secure=1
# and ro.debuggable=0, and USB debugging is left to the developer options.

# NOTE: the old local add-ons vendor_extra_blobs.mk / vendor_missing_modules.mk are deliberately
# NOT re-included any more. They were written against the July device tree and list modules by name
# (init.qcom.rc, fstab.default, FroggerPro*Overlay, froggerPro_hidl_vendor_deps, ...) that upstream's current
# tree no longer defines that way, so kati aborts with "includes non-existent modules in PRODUCT_PACKAGES".
# Upstream now installs that content itself; if a later link step turns out to need vendor libs again, add the
# specific modules back rather than the whole list.
PRODUCT_PROPERTY_OVERRIDES += \
    persist.sys.usb.config=adb,mtp \
    ro.adb.secure=0 \
    persist.logd.logpersistd=logcatd

# Nothing Ndot fonts, installed by fonts.mk.
-include device/nothing/froggerPro/fonts.mk

# Stock services and odm content ported as copies rather than rebuilt.
$(call inherit-product, vendor/nothing/FroggerPro/c_blobs.mk)
$(call inherit-product, vendor/nothing/FroggerPro/odm_content.mk)

# VINTF declarations for the ported stock HALs. VINTF metadata cannot go through
# PRODUCT_COPY_FILES (build/make/core/Makefile:148), so it uses DEVICE_MANIFEST_FILE.
# The face, facsvc, camera, stability, thermal, vibrator and wifilearner fragments are not
# declared: each either stops the device at the logo or names a HAL that is not in the image.
$(call inherit-product, vendor/nothing/FroggerPro/c_modules.mk)

# VINTF for the local vibrator HAL, whose binary is present.
DEVICE_MANIFEST_FILE += vendor/nothing/FroggerPro/etc/vintf/manifest/android.hardware.vibrator.service.froggerpro-richtap.xml

# VINTF for three stock HALs that call AIBinder_markVintfStability and therefore abort with
# "Check failed: status == STATUS_OK" when servicemanager cannot find their fqname in the device
# manifest. Same fix as the sensors HAL.
DEVICE_MANIFEST_FILE += \
    vendor/nothing/FroggerPro/etc/vintf/manifest/vendor.qti.hardware.servicetrackeraidl-service.xml \
    vendor/nothing/FroggerPro/etc/vintf/manifest/vendor.qti.hardware.lights.service.xml \
    vendor/nothing/FroggerPro/etc/vintf/manifest/android.hardware.biometrics.face-service.noth.xml \
    vendor/nothing/FroggerPro/etc/vintf/manifest/vendor.noth.hardware.thermal-service.xml \
    vendor/nothing/FroggerPro/etc/vintf/manifest/vendor.qti.memory.pasrmanager-service.xml

# The pasrmanager HAL above is a oneshot service: when its registration is refused it aborts and
# is never retried, so it never shows up in "getprop | grep init.svc | grep restarting".

# Stock keylayout and hardware codecs.
-include vendor/nothing/FroggerPro/stock_add.mk

# The full safe copy list, vintf excluded.
-include vendor/nothing/FroggerPro/stock_full.mk
# stock_vintf.mk is not included: its 24 fragments need a soong glob cache fix first.
