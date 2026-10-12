#
# SPDX-FileCopyrightText: The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#
# Privacy variant. Both products share one device tree (config.fs, sepolicy, rro_overlays,
# system.prop), so a fix in either one benefits both; this file overrides only product-level
# differences such as the package list and properties.
#
# The OEM component exclusion list is deliberately still empty: it needs an item-by-item audit of
# which stock components conflict with the privacy limits, to be applied afterwards with
# PRODUCT_PACKAGES := $(filter-out ...) rather than by guesswork.

$(call inherit-product, device/nothing/froggerPro/lineage_FroggerPro.mk)

# PRODUCT_NAME must differ from lineage_FroggerPro, or out/ and the OTA collide.
PRODUCT_NAME := lineage_FroggerPro_privacy

# Privacy settings app, with the switches that actually take effect plus the level selector.
# It lives in the device tree rather than in hardware/nothing so that no upstream repo is forked.
PRODUCT_PACKAGES += \
    FroggerProPrivacy

# Marks which variant a device is running.
PRODUCT_PROPERTY_OVERRIDES += \
    ro.froggerpro.variant=privacy

PRODUCT_MODEL := A069P
PRODUCT_BRAND := Nothing
PRODUCT_DEVICE := FroggerPro
PRODUCT_MANUFACTURER := Nothing

# No adb default of its own: turning USB debugging off is the developer options' job.
# Filtering vendor properties here does not work, because persist.sys.usb.config comes from
# system.prop:10 and build/make/core/config.mk:1277 pulls it into both products.
# A published build with adb off by default would have to change system.prop per variant and
# handle ro.adb.secure before the inherit (vendor/lineage/config/common.mk:31-48).

# Privacy baseline, build-time only and not runtime-switchable, to be filled in after the audit:
#   - PRODUCT_PACKAGES := $(filter-out <stock components...>, $(PRODUCT_PACKAGES))
#   - the telemetry and statistics flags that come from upstream
