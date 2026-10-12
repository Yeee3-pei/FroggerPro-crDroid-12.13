# Nothing Ndot fonts, extracted from the stock full OTA (system/fonts).
# Installed to /product/fonts/ because that is the directory the framework scans for OEM fonts;
# the matching families are declared in the /product/etc/fonts_customization.xml that
# packages/overlays/Lineage provides.
PRODUCT_COPY_FILES += \
    device/nothing/froggerPro/prebuilt_fonts/Ndot-55.otf:$(TARGET_COPY_OUT_PRODUCT)/fonts/Ndot-55.otf \
    device/nothing/froggerPro/prebuilt_fonts/Ndot-57.otf:$(TARGET_COPY_OUT_PRODUCT)/fonts/Ndot-57.otf \
    device/nothing/froggerPro/prebuilt_fonts/Ndot-57-Aligned.otf:$(TARGET_COPY_OUT_PRODUCT)/fonts/Ndot-57-Aligned.otf \
    device/nothing/froggerPro/prebuilt_fonts/NDot55Caps.otf:$(TARGET_COPY_OUT_PRODUCT)/fonts/NDot55Caps.otf \
    device/nothing/froggerPro/prebuilt_fonts/NDot57Caps.otf:$(TARGET_COPY_OUT_PRODUCT)/fonts/NDot57Caps.otf \
    device/nothing/froggerPro/prebuilt_fonts/Ndot77JPExtended.ttf:$(TARGET_COPY_OUT_PRODUCT)/fonts/Ndot77JPExtended.ttf
