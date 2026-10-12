# FroggerPro device tree (LineageOS 23.2)

Bring-up tree for the Nothing Phone (4a) Pro, codename **FroggerPro** (SM8750
family). It is a fork of `AmphibianArcade/android_device_nothing_FroggerPro`;
`NOTICE` records the provenance, the base commit and how local changes are
attributed.

## Scope

This is an experimental single-device bring-up tree and it is **not proposed for
upstream**. The delta mixes verified fixes with exploratory work, so it is kept
as a fork by design. Problems in the delta are this fork's responsibility, not
the upstream maintainer's.

## Building it

This tree alone does not build a bootable image. It also needs:

- the matching stock vendor blobs, extracted from the Nothing OS release; the
  vendor directory is not part of this repository;
- the local add-on makefiles referenced from `device.mk` with
  `inherit-product-if-exists`; those live in the vendor tree on the machines
  this was built on, so a plain clone will silently build without them.

## Known limitations of the current build

- **Face unlock cannot finish enrolment.** AOSP Settings opens the front camera
  for its own preview and does not pass a surface to the face HAL, so both
  clients open the camera, cameraserver evicts the HAL (score 200 against the
  Settings client) and enrolment fails with `cameraStatus -10008`. Stock uses
  `NothingSettings`, which hands the preview surface to the HAL; that app is not
  part of this tree.
- **Camera AI models are not installed.** The stock vendor image carries 154
  `lib64/bm5a*.bin` model files; the current makefiles do not install them.
- **USB** has been observed re-enumerating between its adb and MTP identities.
  The cause has not been identified.
- **Verified boot provides no protection.** `BoardConfig.mk` signs AVB with the
  AOSP public test key (`external/avb/test/data/testkey_rsa4096.pem`) and builds
  vbmeta with `--flags 3`, which disables verity and verification. Keep the
  bootloader unlocked: locking it against these images is not supported and can
  leave the device unbootable.
- Builds are `userdebug`.

## Verification

Every local change is verified on the device before it is released; the written
record of each one (file, before/after, reason, how it was verified) is kept in
the project CHANGELOG outside this repository. Parts of the local delta were
written with AI assistance and reviewed on device by the maintainer.
