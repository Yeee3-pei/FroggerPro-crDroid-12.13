#!/usr/bin/env -S PYTHONPATH=../../../tools/extract-utils python3
#
# SPDX-FileCopyrightText: The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#

from extract_utils.fixups_blob import (
    blob_fixup,
    blob_fixups_user_type,
)
from extract_utils.fixups_lib import (
    lib_fixups,
    lib_fixups_user_type,
)
from extract_utils.main import (
    ExtractUtils,
    ExtractUtilsModule,
)

namespace_imports = [
    'hardware/qcom-caf/common/libqti-perfd-client',
    'hardware/qcom-caf/sm8750',
    'hardware/qcom-caf/wlan',
    'vendor/qcom/opensource/commonsys/display',
    'vendor/qcom/opensource/commonsys-intf/display',
    'vendor/qcom/opensource/dataservices',
]

def lib_fixup_vendor_suffix(lib: str, partition: str, *args, **kwargs):
    return f'{lib}_{partition}' if partition == 'vendor' else None

lib_fixups: lib_fixups_user_type = {
    **lib_fixups,
    (
        'vendor.qti.diaghal@1.0',
        'vendor.qti.diaghal-V1-ndk',
    ): lib_fixup_vendor_suffix,
}

def disable_qcril_poweron_opt(ctx, file, file_path, *args, **kwargs):
    """Keep inbound SMS flowing instead of buffering it in the modem.

    qcril_sms_mt_sms_ind_hdlr gates MT SMS delivery on atel_ui_status, which only
    the QTI OEM hook QCRIL_EVT_HOOK_SET_ATEL_UI_STATUS raises -- NothingOS calls it,
    LineageOS does not, and while power optimisation is on the messages sit in the
    modem. The flag is read from the DB by qcril_config_get(), not from the
    identically named Android property: that one read 0 while the flag read 1, and
    setting it to 0 also broke 10-digit dialling. VALUE overrides DEF_VAL, so both
    are set.
    """
    import sqlite3

    prop = 'persist.vendor.radio.poweron_opt'
    con = sqlite3.connect(file_path)
    try:
        cur = con.execute(
            'UPDATE qcril_properties_table SET def_val = ?, value = ? WHERE property = ?',
            ('0', '0', prop))
        if cur.rowcount != 1:
            # Loud but not fatal: a schema change must not break everyone's build,
            # and a silently skipped fixup costs inbound SMS without any sign until
            # someone texts the phone.
            print(f'{file}: expected 1 row for {prop}, updated {cur.rowcount}; '
                  'the qcril property table changed, re-check this fixup.')
        con.commit()
    finally:
        con.close()


blob_fixups: blob_fixups_user_type = {
    'vendor/etc/qcril_database/qcrilNr.db': blob_fixup()
        .call(disable_qcril_poweron_opt, need_tmp_dir=False),
    (
        'vendor/bin/hw/android.hardware.security.keymint-service-spu-qti',
        'vendor/lib64/libspukeymint.so',
    ): blob_fixup()
        .replace_needed('android.hardware.security.sharedsecret-V2-ndk.so', 'android.hardware.security.sharedsecret-V1-ndk.so'),
    (
        'vendor/bin/hw/android.hardware.security.keymint-service.strongbox-thales',
        'vendor/lib64/libjc_keymint-thales.so',
    ): blob_fixup()
        .replace_needed('android.hardware.security.keymint-V3-ndk.so', 'android.hardware.security.keymint-V4-ndk.so'),
    (
        'vendor/bin/poweropt-service',
        'vendor/lib64/libaodoptfeature.so',
        'vendor/lib64/libapengine.so',
        'vendor/lib64/libcamerapoweroptfeature.so',
        'vendor/lib64/libgamepoweroptfeature.so',
        'vendor/lib64/liblearningmodule.so',
        'vendor/lib64/liboffscreenpoweroptfeature.so',
        'vendor/lib64/libpowercore.so',
        'vendor/lib64/libpsmoptfeature.so',
        'vendor/lib64/libstandbyfeature.so',
        'vendor/lib64/libvideooptfeature.so',
        'vendor/lib64/soundfx/libquasar.so',
        'vendor/lib64/hw/libaudioeffecthal.qti.so',
    ): blob_fixup()
        .replace_needed('libtinyxml2.so', 'libtinyxml2-v34.so'),
    'vendor/etc/init/qms.rc': blob_fixup()
        .regex_replace(
            r'(service\s+vendor\.qms\s+/vendor/bin/qms\s*\n)',
            r'\1    user root\n'
        ),
    'vendor/etc/init/vendor.dpmd.rc': blob_fixup()
        .regex_replace(
            r'(service\s+vendor\.dpmd\s+/vendor/bin/vendor\.dpmd\s*\n)',
            r'\1    user root\n'
        ),
    'vendor/etc/libnfc-hal-st.conf': blob_fixup()
        .regex_replace(
            r'STNFC_HAL_LOGLEVEL=0x13',
            r'STNFC_HAL_LOGLEVEL=0x12'
        ),
    (
        'vendor/lib64/camera/components/com.qti.node.dewarp.so',
        'vendor/lib64/com.nothing.camera.postproc@1.0-service-impl.so',
        'vendor/lib64/hw/com.qti.chi.override.so',
        'vendor/lib64/libchifeature2.so',
        'vendor/lib64/vendor.qti.hardware.camera.offlinecamera-service-impl.so',
    ): blob_fixup()
        .replace_needed('android.hardware.graphics.allocator-V1-ndk.so', 'android.hardware.graphics.allocator-V2-ndk.so'),
    (
        'vendor/lib64/com.nothing.camera.postproc-V1-ndk_platform.so',
        'vendor/lib64/libsxrservice.so',
    ): blob_fixup()
        .replace_needed('android.hardware.common-V2-ndk_platform.so', 'android.hardware.common-V2-ndk.so'),
    (
        'vendor/lib64/libVoiceSdk.so',
        'vendor/lib64/libcapiv2uvvendor.so',
        'vendor/lib64/liblistensoundmodel2vendor.so',
    ): blob_fixup()
        .replace_needed('libtensorflowlite_c.so', 'libtensorflowlite_c_vendor.so'),
    (
        'vendor/lib64/libapengine.so',
        'vendor/lib64/libqti-perfd.so',
    ): blob_fixup()
        .replace_needed('vendor.qti.hardware.display.config-V5-ndk.so', 'vendor.qti.hardware.display.config-V12-ndk.so'),
    'vendor/lib64/libmorpho_RapidEffect.so': blob_fixup()
        .clear_symbol_version('AHardwareBuffer_allocate')
        .clear_symbol_version('AHardwareBuffer_describe')
        .clear_symbol_version('AHardwareBuffer_lockPlanes')
        .clear_symbol_version('AHardwareBuffer_release')
        .clear_symbol_version('AHardwareBuffer_unlock'),
    'vendor/lib64/libntcamskia.so': blob_fixup()
        .add_needed('libnativewindow.so'),
    'vendor/lib64/libqcodec2_core.so': blob_fixup()
        .replace_needed('android.hardware.graphics.common-V5-ndk.so', 'android.hardware.graphics.common-V7-ndk.so'),
    'vendor/lib64/libspukeymintprovision.so': blob_fixup()
        .replace_needed('android.hardware.security.keymint-V2-ndk.so', 'android.hardware.security.keymint-V3-ndk.so'),
    'vendor/lib64/soundfx/libbundleaidl.so':blob_fixup()
        .replace_needed('libaudio_aidl_conversion_common_ndk.so', 'libaudio_aidl_conversion_common_ndk_prebuilt.so'),
    'vendor/lib64/hw/libaudiocorehal.qti.so':blob_fixup()
        .replace_needed('android.hardware.audio.core.sounddose-V1-ndk.so','android.hardware.audio.core.sounddose-V2-ndk.so')
        .replace_needed('libaudio_aidl_conversion_common_ndk.so', 'libaudio_aidl_conversion_common_ndk_prebuilt.so'),
    'vendor/lib64/android.hardware.bluetooth.audio-impl_prebuilt.so': blob_fixup()
        .replace_needed('libbluetooth_audio_session_aidl.so', 'libbluetooth_audio_session_aidl_prebuilt.so'),
    'vendor/lib64/libaudioserviceexampleimpl.so': blob_fixup()
        .add_needed('libaudioutils_shim.so')
        .replace_needed('android.hardware.bluetooth.audio-impl.so', 'android.hardware.bluetooth.audio-impl_prebuilt.so')
        .replace_needed('libaudio_aidl_conversion_common_ndk.so', 'libaudio_aidl_conversion_common_ndk_prebuilt.so')
        .replace_needed('libbluetooth_audio_session_aidl.so', 'libbluetooth_audio_session_aidl_prebuilt.so'),
    'vendor/etc/init/vendor.qti.media.c2@1.0-service.rc': blob_fixup()
        .regex_replace(r'writepid\s+/dev/cpuset/foreground/tasks', 'task_profiles ProcessCapacityHigh HighPerformance'),
}  # fmt: skip

module = ExtractUtilsModule(
    'FroggerPro',
    'nothing',
    blob_fixups=blob_fixups,
    lib_fixups=lib_fixups,
    namespace_imports=namespace_imports,
    add_firmware_proprietary_file=True,
)

if __name__ == '__main__':
    utils = ExtractUtils.device(module)
    utils.run()
