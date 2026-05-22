# ReSukiSU munch MIUI14 build

This repository builds a Redmi K40S (`munch`) MIUI14-targeted kernel package with ReSukiSU and SUSFS support.

## What it does

- Clones Xiaomi `munch-s-oss`
- Clones ReSukiSU into the kernel tree and runs its `setup.sh`
- Applies the Non-GKI 4.19 SUSFS patch with fuzz for Xiaomi's 4.19 tree
- Runs the Non-GKI SUSFS inline hook script for ReSukiSU integration
- Applies the Python 3 wrapper fix for the Xiaomi kernel tree
- Builds an AnyKernel3 zip plus `Image`, `kernel.config`, and `System.map`

## MIUI14 note

MiCode currently only publishes `munch-s-oss` for K40S/munch. This build is packaged for MIUI14/Android 13 by preserving the device's current boot ramdisk via AnyKernel3 and limiting the flashable zip to Android 13. Treat the first flash as a compatibility test and keep your stock MIUI14 `boot.img` ready for recovery.

## Default versions

- Xiaomi kernel: `munch-s-oss` (only public MiCode munch branch found)
- ReSukiSU: `main`
- SUSFS patch source: `JackA1ltman/NonGKI_Kernel_Build_2nd@mainline`
- GitHub Actions toolchain: AOSP `clang-r399163b`

## Local run

```bash
bash scripts/build-k40s.sh
```

Set `USE_AOSP_CLANG=1` on an x86_64 Linux host to match the GitHub Actions toolchain.

## GitHub Actions

The workflow is in `.github/workflows/build.yml`.
