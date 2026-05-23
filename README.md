<!--
This file is tri-licensed under GPLv2, Apache 2.0, or the SQLite Blessing.
You may choose any of these licenses to use this code.

In place of a legal notice, here is a blessing:
 - May you do good and not evil.
 - May you find forgiveness for yourself and forgive others.
 - May you share freely, never taking more than you give.

SPDX-License-Identifier: GPL-2.0-only OR Apache-2.0 OR blessing
-->

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

The default package is the conservative mainline track. It builds from Xiaomi's
public `munch-s-oss` source and uses fallback weak stubs for several Xiaomi MIUI
display extension callbacks that are missing from this tree. Core display may
still work, but MIUI display extras such as panel info, MIPI register access,
doze brightness, HBM/FOD status, and smart FPS need real-device validation.

An experimental reference track is also available. It builds the `munch` MIUI
variant from `liyafe1997/kernel_xiaomi_sm8250_mod@android15-lineage22-mod` with
ReSukiSU enabled instead of the original SukiSU flow. Use it only as a comparison
package if the conservative package shows display or vendor-interface problems.

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

Experimental reference build:

```bash
bash scripts/build-k40s-ref.sh
```

## Stock boot repack check

If you have a MIUI14 stock `boot.img`, keep it local in the repository root and do not commit it. After downloading or building an `Image`, this script can verify that the stock boot layout can be repacked with the new kernel:

```bash
bash scripts/repack-stock-boot.sh boot.img work/downloaded-artifact/Image work/miui14-boot/repacked-boot.img
```

Prefer flashing the AnyKernel3 zip for first testing because it uses the phone's current boot image as the template. The repacked boot image is mainly for offline structure checks and recovery testing.

## GitHub Actions

- Conservative mainline: `.github/workflows/build.yml`
- Reference experimental: `.github/workflows/build-ref.yml`
