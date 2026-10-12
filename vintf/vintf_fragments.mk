# Device VINTF fragments.
# DEVICE_MANIFEST_FILE is the only supported route for these: PRODUCT_COPY_FILES is
# rejected for VINTF metadata (build/make/core/Makefile:148). A fragment that repeats an
# fqname already present in the merged manifest makes assemble_vintf fail with
# Conflicting FqInstance, so check the merged manifest before adding one.
DEVICE_MANIFEST_FILE += \
    $(DEVICE_PATH)/vintf/manifest_dedup.xml \
    vendor/nothing/FroggerPro/etc/vintf/manifest/android.hardware.sensors.froggerpro-multihal.xml
