#
# Ship the three Adreno library names at /vendor/lib64 as symlinks into lib64/egl/,
# matching the stock image. PRODUCT_COPY_FILES cannot create symlinks and previously
# shipped real files in their place.
#
# Kept in Android.mk because $(TARGET_OUT_VENDOR) is not yet defined while product
# makefiles are parsed (kati resolved it to /lib64/... and failed with "writing to
# readonly directory"). A FORCE target is not an option either: kati rejects a real
# file that depends on a PHONY target.
#
LOCAL_PATH := $(call my-dir)

ADRENO_TOP_SYMLINKS := libEGL_adreno.so libGLESv2_adreno.so libq3dtools_adreno.so

$(foreach f,$(ADRENO_TOP_SYMLINKS),\
  $(eval $(TARGET_OUT_VENDOR)/lib64/$(f): $(TARGET_OUT_VENDOR)/lib64/egl/$(f))\
  $(eval $(TARGET_OUT_VENDOR)/lib64/$(f): ; $$(hide) rm -f $$@ && ln -sf /vendor/lib64/egl/$(f) $$@)\
  $(eval ALL_DEFAULT_INSTALLED_MODULES += $(TARGET_OUT_VENDOR)/lib64/$(f)))
