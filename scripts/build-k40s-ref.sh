#!/usr/bin/env bash
# This file is tri-licensed under GPLv2, Apache 2.0, or the SQLite Blessing.
# You may choose any of these licenses to use this code.
#
# In place of a legal notice, here is a blessing:
#  - May you do good and not evil.
#  - May you find forgiveness for yourself and forgive others.
#  - May you share freely, never taking more than you give.
#
# SPDX-License-Identifier: GPL-2.0-only OR Apache-2.0 OR blessing

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORKDIR="${WORKDIR:-$ROOT_DIR/work}"
ARTIFACT_DIR="$WORKDIR/artifacts-ref"
KERNEL_DIR="$WORKDIR/ref-kernel-sm8250-build"
ANYKERNEL_DIR="$WORKDIR/AnyKernel3-ref"
CLANG_PREBUILT_DIR="$WORKDIR/aosp-clang-ref"
REF_KERNEL_REPO="${REF_KERNEL_REPO:-https://github.com/liyafe1997/kernel_xiaomi_sm8250_mod.git}"
REF_KERNEL_REF="${REF_KERNEL_REF:-android15-lineage22-mod}"
RESUKISU_REPO="${RESUKISU_REPO:-https://github.com/ReSukiSU/ReSukiSU.git}"
RESUKISU_REF="${RESUKISU_REF:-main}"
ANYKERNEL_REPO="${ANYKERNEL_REPO:-https://github.com/osm0sis/AnyKernel3.git}"
AOSP_CLANG_REPO="${AOSP_CLANG_REPO:-https://android.googlesource.com/platform/prebuilts/clang/host/linux-x86}"
AOSP_CLANG_REF="${AOSP_CLANG_REF:-android-msm-redbull-4.19-android12-qpr3}"
AOSP_CLANG_VERSION="${AOSP_CLANG_VERSION:-clang-r399163b}"
USE_AOSP_CLANG="${USE_AOSP_CLANG:-0}"
ARCH="${ARCH:-arm64}"
TARGET_DEVICE="${TARGET_DEVICE:-munch}"
CROSS_COMPILE="${CROSS_COMPILE:-aarch64-linux-gnu-}"
CROSS_COMPILE_ARM32="${CROSS_COMPILE_ARM32:-arm-linux-gnueabi-}"
CLANG_TRIPLE="${CLANG_TRIPLE:-aarch64-linux-gnu-}"
PYTHON_BIN="${PYTHON_BIN:-python3}"
JOBS="${JOBS:-$(nproc)}"
ZIP_NAME="${ZIP_NAME:-munch-miui14-resukisu-ref-strict-experimental.zip}"

mkdir -p "$WORKDIR"
rm -rf "$KERNEL_DIR" "$ANYKERNEL_DIR" "$ARTIFACT_DIR" "$WORKDIR/ref-out"
mkdir -p "$ARTIFACT_DIR"

if [[ "$USE_AOSP_CLANG" == "1" ]]; then
  rm -rf "$CLANG_PREBUILT_DIR"
  git clone --depth 1 --branch "$AOSP_CLANG_REF" "$AOSP_CLANG_REPO" "$CLANG_PREBUILT_DIR"
  export PATH="$CLANG_PREBUILT_DIR/$AOSP_CLANG_VERSION/bin:$PATH"
fi

git clone --depth 1 --branch "$REF_KERNEL_REF" "$REF_KERNEL_REPO" "$KERNEL_DIR"
git -C "$KERNEL_DIR" apply "$ROOT_DIR/patches/ref-susfs-v210-strict.patch"
git clone --depth 1 --branch "$RESUKISU_REF" "$RESUKISU_REPO" "$KERNEL_DIR/KernelSU"

pushd "$KERNEL_DIR" >/dev/null
bash KernelSU/kernel/setup.sh "$RESUKISU_REF"
git apply "$ROOT_DIR/patches/ref-resukisu-inline-hooks.patch"

MAKE_ARGS=(
  ARCH="$ARCH"
  SUBARCH="$ARCH"
  O="$WORKDIR/ref-out"
  CC=clang
  PYTHON="$PYTHON_BIN"
  CROSS_COMPILE="$CROSS_COMPILE"
  CROSS_COMPILE_ARM32="$CROSS_COMPILE_ARM32"
  CROSS_COMPILE_COMPAT="$CROSS_COMPILE_ARM32"
  CLANG_TRIPLE="$CLANG_TRIPLE"
)

make "${MAKE_ARGS[@]}" "${TARGET_DEVICE}_defconfig"

scripts/config --file "$WORKDIR/ref-out/.config" \
  --set-str STATIC_USERMODEHELPER_PATH /system/bin/micd \
  --enable KSU \
  --enable KSU_SUSFS \
  --enable KSU_SUSFS_SUS_PATH \
  --enable KSU_SUSFS_SUS_MOUNT \
  --enable KSU_SUSFS_SUS_KSTAT \
  --enable KSU_SUSFS_SPOOF_UNAME \
  --enable KSU_SUSFS_ENABLE_LOG \
  --enable KSU_SUSFS_HIDE_KSU_SUSFS_SYMBOLS \
  --enable KSU_SUSFS_SPOOF_CMDLINE_OR_BOOTCONFIG \
  --enable KSU_SUSFS_OPEN_REDIRECT \
  --enable KSU_SUSFS_SUS_MAP \
  --disable KPM \
  --disable KSU_TRACEPOINT_HOOK \
  --disable KSU_MANUAL_HOOK \
  --enable XIAOMI_MIUI \
  --enable MIHW \
  --enable PACKAGE_RUNTIME_INFO \
  --enable MIGT \
  --enable MIGT_ENERGY_MODEL \
  --enable MILLET \
  --enable PERF_CRITICAL_RT_TASK \
  --enable SF_BINDER \
  --enable BINDER_OPT \
  --enable KPERFEVENTS \
  --enable PERF_HUMANTASK \
  --enable TASK_DELAY_ACCT \
  --enable MIUI_ZRAM_MEMORY_TRACKING \
  --enable MI_FRAGMENTION \
  --enable PERF_HELPER \
  --enable BOOTUP_RECLAIM \
  --enable MI_RECLAIM \
  --enable RTMM \
  --enable OVERLAY_FS \
  --disable DEBUG_FS \
  --disable MI_MEMORY_SYSFS \
  --disable LTO_CLANG \
  --disable LOCALVERSION_AUTO

make "${MAKE_ARGS[@]}" olddefconfig
make "${MAKE_ARGS[@]}" -j"$JOBS" Image

test -s "$WORKDIR/ref-out/arch/$ARCH/boot/Image"
test -s "$WORKDIR/ref-out/System.map"
popd >/dev/null

git clone --depth 1 "$ANYKERNEL_REPO" "$ANYKERNEL_DIR"

cat > "$ANYKERNEL_DIR/anykernel.sh" <<EOF
### AnyKernel3 Ramdisk Mod Script
## strict experimental reference-kernel package for Redmi K40S / munch MIUI14

properties() { '
kernel.string=ReSukiSU munch MIUI14 reference strict experimental
do.devicecheck=1
do.modules=0
do.systemless=1
do.cleanup=1
do.cleanuponabort=1
device.name1=munch
device.name2=22021211RC
device.name3=22021211RG
supported.versions=13
supported.patchlevels=
supported.vendorpatchlevels=
'; }

boot_attributes() {
set_perm_recursive 0 0 755 644 \$RAMDISK/*
set_perm_recursive 0 0 750 750 \$RAMDISK/init* \$RAMDISK/sbin
}

BLOCK=/dev/block/bootdevice/by-name/boot
IS_SLOT_DEVICE=1
RAMDISK_COMPRESSION=auto
PATCH_VBMETA_FLAG=auto

. tools/ak3-core.sh

dump_boot
write_boot
EOF

cp "$WORKDIR/ref-out/arch/$ARCH/boot/Image" "$ANYKERNEL_DIR/Image"
(cd "$ANYKERNEL_DIR" && zip -r9 "$ARTIFACT_DIR/$ZIP_NAME" . -x '*.git*')
cp "$WORKDIR/ref-out/arch/$ARCH/boot/Image" "$ARTIFACT_DIR/Image"
cp "$WORKDIR/ref-out/.config" "$ARTIFACT_DIR/kernel.config"
cp "$WORKDIR/ref-out/System.map" "$ARTIFACT_DIR/System.map"

cat > "$ARTIFACT_DIR/build-info.txt" <<EOF
track=reference-strict-experimental
kernel_ref=$REF_KERNEL_REF
kernel_sha=$(git -C "$KERNEL_DIR" rev-parse HEAD)
resukisu_ref=$RESUKISU_REF
resukisu_sha=$(git -C "$KERNEL_DIR/KernelSU" rev-parse HEAD)
susfs=strict-v2.1.0
susfs_version=v2.1.0
use_aosp_clang=$USE_AOSP_CLANG
aosp_clang_ref=$AOSP_CLANG_REF
aosp_clang_version=$AOSP_CLANG_VERSION
display_mi=reference-miui
zip_name=$ZIP_NAME
EOF

bash "$ROOT_DIR/scripts/verify-artifact.sh" "$ARTIFACT_DIR" ref

echo "Reference strict experimental artifacts are in $ARTIFACT_DIR"
