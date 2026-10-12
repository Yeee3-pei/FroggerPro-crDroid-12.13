#
# SPDX-FileCopyrightText: The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#

DEVICE_PATH := device/nothing/FroggerPro

include build/make/target/board/BoardConfigMainlineCommon.mk
include vendor/nothing/FroggerPro/BoardConfigVendor.mk

# A/B
AB_OTA_UPDATER := true
AB_OTA_PARTITIONS += \
    boot \
    dtbo \
    init_boot \
    odm \
    product \
    recovery \
    system_dlkm \
    system_ext \
    system \
    vbmeta \
    vbmeta_system \
    vbmeta_vendor \
    vendor_boot \
    vendor_dlkm \
    vendor

# API
BOARD_SHIPPING_API_LEVEL := 202404

# Keep adb up on this userdebug A16 build: logcat is the only window onto a first-stage
# failure on this device. No WITH_ADB_INSECURE, so ro.adb.secure=1 and ro.debuggable=0,
# which is the LineageOS default path (vendor/lineage/config/common.mk:38-44).

# AVB
BOARD_AVB_MAKE_VBMETA_IMAGE_ARGS += --flags 3

BOARD_AVB_BOOT_KEY_PATH := external/avb/test/data/testkey_rsa4096.pem
BOARD_AVB_BOOT_ALGORITHM := SHA256_RSA4096
BOARD_AVB_BOOT_ROLLBACK_INDEX := $(PLATFORM_SECURITY_PATCH_TIMESTAMP)
BOARD_AVB_BOOT_ROLLBACK_INDEX_LOCATION := 3

BOARD_AVB_RECOVERY_KEY_PATH := external/avb/test/data/testkey_rsa4096.pem
BOARD_AVB_RECOVERY_ALGORITHM := SHA256_RSA4096
BOARD_AVB_RECOVERY_ROLLBACK_INDEX := $(PLATFORM_SECURITY_PATCH_TIMESTAMP)
BOARD_AVB_RECOVERY_ROLLBACK_INDEX_LOCATION := 1

BOARD_AVB_VBMETA_SYSTEM := product system system_ext
BOARD_AVB_VBMETA_SYSTEM_KEY_PATH := external/avb/test/data/testkey_rsa4096.pem
BOARD_AVB_VBMETA_SYSTEM_ALGORITHM := SHA256_RSA4096
BOARD_AVB_VBMETA_SYSTEM_ROLLBACK_INDEX := $(PLATFORM_SECURITY_PATCH_TIMESTAMP)
BOARD_AVB_VBMETA_SYSTEM_ROLLBACK_INDEX_LOCATION := 2

BOARD_AVB_VBMETA_VENDOR := odm system_dlkm vendor vendor_dlkm
BOARD_AVB_VBMETA_VENDOR_KEY_PATH := external/avb/test/data/testkey_rsa4096.pem
BOARD_AVB_VBMETA_VENDOR_ALGORITHM := SHA256_RSA4096
BOARD_AVB_VBMETA_VENDOR_ROLLBACK_INDEX := $(PLATFORM_SECURITY_PATCH_TIMESTAMP)
BOARD_AVB_VBMETA_VENDOR_ROLLBACK_INDEX_LOCATION := 4

BOARD_MOVE_GSI_AVB_KEYS_TO_VENDOR_BOOT := true

# Architecture
TARGET_ARCH := arm64
TARGET_ARCH_VARIANT := armv8-2a-dotprod
TARGET_CPU_ABI := arm64-v8a
TARGET_CPU_VARIANT := generic
# TARGET_CPU_VARIANT_RUNTIME is the only variable that survives: config.mk recomputes
# DEX2OAT_TARGET_CPU_VARIANT_RUNTIME from it, and board_config.mk uses $(or ...) so a value
# set here is not overwritten. It feeds ro.bionic.cpu_variant and dalvik.vm.isa.arm64.variant
# (sysprop_config.mk:21,29); setting it on DEX2OAT_TARGET_CPU_VARIANT_RUNTIME or in
# system.prop does not work.
TARGET_CPU_VARIANT_RUNTIME := kryo300
DEX2OAT_TARGET_INSTRUCTION_SET_FEATURES := default


# Audio
AUDIO_FEATURE_ENABLED_DLKM := true
AUDIO_FEATURE_ENABLED_GKI := true
AUDIO_FEATURE_ENABLED_INSTANCE_ID := true
AUDIO_FEATURE_ENABLED_MCS := true
AUDIO_FEATURE_ENABLED_SVA_MULTI_STAGE := true
# BOARD_SUPPORTS_OPENSOURCE_STHAL := true

# Board
TARGET_BOARD_INFO_FILE := $(DEVICE_PATH)/android-info.txt

# Bootloader
TARGET_BOOTLOADER_BOARD_NAME := FroggerPro

# Boot
BOARD_BOOT_HEADER_VERSION := 4
BOARD_MKBOOTIMG_ARGS += --header_version $(BOARD_BOOT_HEADER_VERSION)

BOARD_INIT_BOOT_HEADER_VERSION := 4
BOARD_MKBOOTIMG_INIT_ARGS += --header_version $(BOARD_INIT_BOOT_HEADER_VERSION)

# DTB
BOARD_INCLUDE_DTB_IN_BOOTIMG := true
#BOARD_KERNEL_SEPARATED_DTBO := true
#BOARD_USES_QCOM_MERGE_DTBS_SCRIPT := true
BOARD_PREBUILT_DTBIMAGE_DIR := $(DEVICE_PATH)/dtb
BOARD_PREBUILT_DTBOIMAGE := $(DEVICE_PATH)/dtbo.img

# Display
TARGET_SCREEN_DENSITY := 420

# Filesystem
TARGET_FS_CONFIG_GEN := $(DEVICE_PATH)/config.fs

# Graphics
TARGET_USES_VULKAN := true

# Kernel
BOARD_BOOTCONFIG := \
    androidboot.hardware=qcom \
    androidboot.load_modules_parallel=true \
    androidboot.usbcontroller=a600000.dwc3
    
BOARD_KERNEL_CMDLINE := \
    androidboot.serialconsole=0 \
    firmware_class.path=/vendor/firmware,/vendor/firmware_mnt/image,/firmware/image \
    log_buf_len=1M \
    nosoftlockup \
    sysctl.kernel.firmware_config.force_sysfs_fallback=1

BOARD_KERNEL_BASE := 0x00000000
BOARD_KERNEL_IMAGE_NAME := Image
BOARD_KERNEL_PAGESIZE := 4096
BOARD_RAMDISK_USE_LZ4 := true
BOARD_USES_GENERIC_KERNEL_IMAGE := true

TARGET_KERNEL_SOURCE := kernel/nothing/sm8750
TARGET_KERNEL_CONFIG := \
    gki_defconfig \
    vendor/sun_perf.config \
    vendor/noth_common.config \
    vendor/froggerpro_perf.config

TARGET_KERNEL_EXT_MODULE_ROOT := kernel/nothing/sm8750-modules
TARGET_KERNEL_EXT_MODULES := \
    qcom/opensource/mmrm-driver \
    qcom/opensource/mm-drivers/hw_fence \
    qcom/opensource/mm-drivers/msm_ext_display \
    qcom/opensource/mm-drivers/sync_fence \
    qcom/opensource/audio-kernel \
    qcom/opensource/securemsm-kernel \
    qcom/opensource/synx-kernel \
    qcom/opensource/camera-kernel \
    qcom/opensource/data-kernel/drivers/smem-mailbox \
    qcom/opensource/datarmnet-ext/mem \
    qcom/opensource/dataipa/drivers/platform/msm \
    qcom/opensource/datarmnet/core \
    qcom/opensource/datarmnet-ext/aps \
    qcom/opensource/datarmnet-ext/offload \
    qcom/opensource/datarmnet-ext/perf \
    qcom/opensource/datarmnet-ext/perf_tether \
    qcom/opensource/datarmnet-ext/sch \
    qcom/opensource/datarmnet-ext/shs \
    qcom/opensource/datarmnet-ext/wlan \
    qcom/opensource/display-drivers/msm \
    qcom/opensource/dsp-kernel \
    qcom/opensource/eva-kernel \
    qcom/opensource/graphics-kernel \
    qcom/opensource/spu-kernel \
    qcom/opensource/touch-drivers \
    qcom/opensource/video-driver \
    qcom/opensource/wlan/platform \
    qcom/opensource/wlan/qcacld-3.0/.qca6750 \
    qcom/opensource/bt-kernel \
    st/opensource/driver \
    st/opensource/eSE-driver

BOARD_SYSTEM_KERNEL_MODULES_BLOCKLIST_FILE := $(DEVICE_PATH)/modules.blocklist.system_dlkm
BOARD_SYSTEM_KERNEL_MODULES_LOAD := $(strip $(shell cat $(DEVICE_PATH)/modules.load.system_dlkm))
BOARD_VENDOR_KERNEL_MODULES_BLOCKLIST_FILE := $(DEVICE_PATH)/modules.blocklist.vendor_dlkm
BOARD_VENDOR_KERNEL_MODULES_LOAD := $(strip $(shell cat $(DEVICE_PATH)/modules.load.vendor_dlkm))
BOARD_VENDOR_RAMDISK_KERNEL_MODULES_LOAD := $(strip $(shell cat $(DEVICE_PATH)/modules.load.vendor_boot))
BOARD_VENDOR_RAMDISK_RECOVERY_KERNEL_MODULES_LOAD := $(strip $(shell cat $(DEVICE_PATH)/modules.load.recovery))
BOOT_KERNEL_MODULES := $(BOARD_VENDOR_RAMDISK_RECOVERY_KERNEL_MODULES_LOAD)
SYSTEM_KERNEL_MODULES := $(BOARD_SYSTEM_KERNEL_MODULES_LOAD)

# Partitions
# The stock super uses the group name "default", not qti_dynamic_partitions. config.mk
# upper-cases the group name to find BOARD_<GROUP>_PARTITION_LIST and BOARD_<GROUP>_SIZE,
# so the variable names below have to match the group name.
BOARD_DEFAULT_PARTITION_LIST := odm product system system_dlkm system_ext vendor vendor_dlkm
# Must stay below BOARD_SUPER_PARTITION_SIZE / 2, or check_all_partition_sizes fails on the
# group itself rather than on the sum of its partitions.
BOARD_DEFAULT_SIZE := 4829184000 # BOARD_SUPER_PARTITION_SIZE - 4MiB
BOARD_SUPER_PARTITION_GROUPS := default
BOARD_SUPER_PARTITION_SIZE := 9663676416

# Retrofit dynamic partitions require both of these (config.mk:1021-1033). super is a real
# physical partition on this device, so no androidboot.super_partition is injected.
BOARD_SUPER_PARTITION_METADATA_DEVICE := super
BOARD_SUPER_PARTITION_BLOCK_DEVICES := super

# Deliberately kept, though the in-tree retrofit route does not work: writing
# PRODUCT_RETROFIT_DYNAMIC_PARTITIONS is rejected by config.mk:911 because the shipping API
# level is 36, and dropping PRODUCT_SHIPPING_API_LEVEL to get past that guard makes the
# hardware/lineage/compat vendorcompat modules collide. The super image is built by a local
# lpmake script outside this tree instead.

# The booting stock super uses retrofit geometry: one "default" group and two metadata slots,
# which build_super_image.py only produces when dynamic_partition_retrofit is true.
BOARD_BOOTIMAGE_PARTITION_SIZE := 0x6000000
BOARD_DTBOIMG_PARTITION_SIZE := 0x3200000
BOARD_FLASH_BLOCK_SIZE := 131072 # (BOARD_KERNEL_PAGESIZE * 32)
BOARD_INIT_BOOT_IMAGE_PARTITION_SIZE := 0x800000
BOARD_RECOVERYIMAGE_PARTITION_SIZE := 0x6400000
BOARD_VENDOR_BOOTIMAGE_PARTITION_SIZE := 0x6000000

BOARD_ODMIMAGE_FILE_SYSTEM_TYPE := erofs
BOARD_PRODUCTIMAGE_FILE_SYSTEM_TYPE := erofs
BOARD_SYSTEM_DLKMIMAGE_FILE_SYSTEM_TYPE := erofs
BOARD_SYSTEM_EXTIMAGE_FILE_SYSTEM_TYPE := erofs
BOARD_SYSTEMIMAGE_FILE_SYSTEM_TYPE := erofs
BOARD_VENDORIMAGE_FILE_SYSTEM_TYPE := erofs
BOARD_VENDOR_DLKMIMAGE_FILE_SYSTEM_TYPE := erofs

TARGET_COPY_OUT_ODM := odm
TARGET_COPY_OUT_SYSTEM_DLKM := system_dlkm
TARGET_COPY_OUT_VENDOR_DLKM := vendor_dlkm

# Platform
BOARD_USES_QCOM_HARDWARE := true
TARGET_BOARD_PLATFORM := sun

# RIL
ENABLE_VENDOR_RIL_SERVICE := true

# Recovery
BOARD_EXCLUDE_KERNEL_FROM_RECOVERY_IMAGE := true
BOARD_USES_FULL_RECOVERY_IMAGE := true
TARGET_RECOVERY_FSTAB := $(DEVICE_PATH)/init/fstab.default
TARGET_RECOVERY_PIXEL_FORMAT := RGBX_8888
TARGET_RECOVERY_UI_MARGIN_HEIGHT := 100
TARGET_USERIMAGES_USE_F2FS := true

# SELinux
include vendor/nothing/NanoGlyph/sepolicy/config.mk
include hardware/nothing/config.mk
include device/qcom/sepolicy_vndr/SEPolicy.mk
include device/lineage/sepolicy/libperfmgr/sepolicy.mk

SYSTEM_EXT_PUBLIC_SEPOLICY_DIRS += $(DEVICE_PATH)/sepolicy/public
SYSTEM_EXT_PRIVATE_SEPOLICY_DIRS += $(DEVICE_PATH)/sepolicy/private
BOARD_VENDOR_SEPOLICY_DIRS += $(DEVICE_PATH)/sepolicy/vendor

# VINTF
DEVICE_FRAMEWORK_COMPATIBILITY_MATRIX_FILE += \
    $(DEVICE_PATH)/vintf/framework_matrix_nothing.xml \
    hardware/qcom-caf/common/vendor_framework_compatibility_matrix.xml \
    $(NANOGLYPH_PATH)/matrix/vintf/framework_matrix_nanoglyph.xml

DEVICE_MANIFEST_FILE += \
    $(DEVICE_PATH)/vintf/manifest.xml \
    $(AUDIO_HAL_DIR)/configs/sun/manifest_audio_qti_services.xml

# VINTF device fragments. Our vendor image declared only 5 HALs; these entries fill the gap.
# DEVICE_MANIFEST_FILE is the only supported route for them: PRODUCT_COPY_FILES is rejected
# for VINTF metadata (build/make/core/Makefile:148).
include $(DEVICE_PATH)/vintf/vintf_fragments.mk

ODM_MANIFEST_FILES += $(DEVICE_PATH)/vintf/manifest_FroggerPro.xml    
ODM_MANIFEST_SKUS += JPN
ODM_MANIFEST_JPN_FILES += $(DEVICE_PATH)/vintf/manifest_JPN.xml

DEVICE_MATRIX_FILE += hardware/qcom-caf/common/compatibility_matrix.xml

# Wi-Fi
BOARD_WLAN_DEVICE := qcwcn
BOARD_HOSTAPD_DRIVER := NL80211
BOARD_HOSTAPD_PRIVATE_LIB := lib_driver_cmd_$(BOARD_WLAN_DEVICE)
BOARD_WPA_SUPPLICANT_DRIVER := $(BOARD_HOSTAPD_DRIVER)
BOARD_WPA_SUPPLICANT_PRIVATE_LIB := $(BOARD_HOSTAPD_PRIVATE_LIB)
BOARD_WPA_SUPPLICANT_PRIVATE_LIB_EVENT := "ON"
WIFI_DRIVER_STATE_CTRL_PARAM := "/dev/wlan"
WIFI_DRIVER_STATE_OFF := "OFF"
WIFI_DRIVER_STATE_ON := "ON"
WIFI_FEATURE_HOSTAPD_11AX := true
WIFI_FEATURE_SUPPLICANT_11AX := true
WIFI_HIDL_FEATURE_AWARE := true
WIFI_HIDL_FEATURE_DUAL_INTERFACE := true
WIFI_HIDL_UNIFIED_SUPPLICANT_SERVICE_RC_ENTRY := true
WPA_SUPPLICANT_VERSION := VER_0_8_X

# Kernel built from source together with its external modules. The prebuilt-kernel route
# fails in hardware/qcom-caf/sm8750, where linux/qti-smmu-proxy.h comes from the
# qcom/opensource/securemsm-kernel external module. kernel/nothing/sm8750 and
# kernel/nothing/sm8750-modules both exist locally.
TARGET_KERNEL_VERSION := 6.6

# The headers come from the kernel source through make headers_install: the branch above takes
# precedence whenever $(TARGET_KERNEL_SOURCE)/Makefile exists, so no prebuilt headers are needed.

# Module sources come from the kernel and its external modules, not from prebuilt/modules.
# upstream already wires BOARD_*_KERNEL_MODULES_LOAD and *_BLOCKLIST_FILE to the modules.load.*
# and modules.blocklist.* files in this tree, so nothing here needs overriding.

# The vendor blobs are installed with PRODUCT_COPY_FILES, which AOSP rejects for ELF files.
# This is the switch AOSP keeps for device trees that do so (build/make/core/board_config.mk:179);
# regenerating the blob makefile as soong prebuilt modules is the longer-term fix.
BUILD_BROKEN_ELF_PREBUILT_PRODUCT_COPY_FILES := true
