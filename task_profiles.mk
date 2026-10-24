#
# SPDX-FileCopyrightText: The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#
# Vendor overlay for the task profile database, installed as vendor/etc/task_profiles.json.
#
# The stock vendor's vendor.noth.hardware.camera-service.rc starts the Nothing camera service with
#
#   task_profiles NtCamAlgoCapacity
#
# and that profile is defined by the stock system image, not by this one: the profile database here
# is AOSP's, and its 44 entries do not include that name. init loads /etc/task_profiles.json and
# then /vendor/etc/task_profiles.json, so installing the vendor half restores the name the stock
# rc asks for without touching either the rc or the AOSP database.
#
# Only that one profile is listed. The vendor file is loaded on top of the system one, so anything
# not named here keeps its AOSP definition.
PRODUCT_COPY_FILES += \
    device/nothing/froggerPro/task_profiles/task_profiles.json:$(TARGET_COPY_OUT_VENDOR)/etc/task_profiles.json
