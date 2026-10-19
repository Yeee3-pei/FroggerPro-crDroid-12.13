# Media profile override, installed as media_profiles_froggerpro.xml.
#
# system.prop points ro.media.xml_variant.profiles at this file. It is the vendor profile verbatim
# with two changes:
#   - camera 0's 2160p entry is raised from 30 to 60 fps, the combination measured on this device.
#   - camera 1's 1080p entry is raised from 30 to 60 fps. That camera tops out below 4K: the HAL
#     advertises no 3840x2160 stream for it (largest output 3280x2464, and 2400x1080 in 16:9), but
#     it does report a 16.67 ms minimum frame duration for 1920x1080.
# The vendor's own media_profiles_kera_v1.xml declares 60 fps for cameras 2/3/4 only, so apps that
# go through CamcorderProfile had no 60 fps option on the main or the front camera.
#
# Installed under our own name on purpose: the vendor tree already installs media_profiles_kera_v1.xml,
# and a PRODUCT_COPY_FILES rule for that path would abort the build with "overriding commands".
PRODUCT_COPY_FILES += \
    device/nothing/froggerPro/media/media_profiles_froggerpro.xml:$(TARGET_COPY_OUT_VENDOR)/etc/media_profiles_froggerpro.xml
