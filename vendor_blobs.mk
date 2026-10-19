# Vendor blobs this tree installs itself.
#
# Camera AI models: the stock vendor image carries 154 lib64/bm5a*.bin files (about 634 MiB) and the
# generated FroggerPro-vendor.mk has no copy rule for any of them, so they never reached the image.
# The camera HAL loads them at runtime (logcat: "registerNetwork failed ... bm5a73v04s13n00.bin").
# Copied with a wildcard because the set is large and grows with every vendor drop.
$(foreach f,$(wildcard vendor/nothing/FroggerPro/lib64/bm5a*.bin),\
  $(eval PRODUCT_COPY_FILES += $(f):$(TARGET_COPY_OUT_VENDOR)/lib64/$(notdir $(f))))
