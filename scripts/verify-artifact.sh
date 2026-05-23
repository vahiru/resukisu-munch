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

ARTIFACT_DIR="${1:?artifact directory is required}"
TRACK="${2:-main}"

need_file() {
  if [[ ! -s "$1" ]]; then
    echo "missing or empty artifact: $1" >&2
    exit 1
  fi
}

need_config() {
  local key="$1"
  if ! grep -qx "$key=y" "$ARTIFACT_DIR/kernel.config"; then
    echo "missing required config: $key=y" >&2
    exit 1
  fi
}

need_not_config() {
  local key="$1"
  if grep -qx "$key=y" "$ARTIFACT_DIR/kernel.config"; then
    echo "unexpected enabled config: $key=y" >&2
    exit 1
  fi
}

need_file "$ARTIFACT_DIR/Image"
need_file "$ARTIFACT_DIR/kernel.config"
need_file "$ARTIFACT_DIR/System.map"
need_file "$ARTIFACT_DIR/build-info.txt"

if ! file "$ARTIFACT_DIR/Image" | grep -q 'Linux kernel ARM64 boot executable Image'; then
  echo "artifact Image is not an ARM64 boot Image" >&2
  file "$ARTIFACT_DIR/Image" >&2
  exit 1
fi

need_config CONFIG_KSU
need_config CONFIG_KSU_SUSFS
need_not_config CONFIG_KPM

case "$TRACK" in
  main)
    need_file "$ARTIFACT_DIR/munch-miui14-resukisu.zip"
    grep -qx 'display_mi=fallback-weak-stubs' "$ARTIFACT_DIR/build-info.txt"
    grep -qx '# CONFIG_RANDOMIZE_BASE is not set' "$ARTIFACT_DIR/kernel.config"
    ;;
  ref)
    need_file "$ARTIFACT_DIR/munch-miui14-resukisu-ref-strict-experimental.zip"
    grep -qx 'track=reference-strict-experimental' "$ARTIFACT_DIR/build-info.txt"
    grep -qx 'display_mi=reference-miui' "$ARTIFACT_DIR/build-info.txt"
    grep -qx 'susfs=strict-v2.1.0' "$ARTIFACT_DIR/build-info.txt"
    grep -qx 'susfs_version=v2.1.0' "$ARTIFACT_DIR/build-info.txt"
    need_config CONFIG_XIAOMI_MIUI
    need_config CONFIG_KSU_SUSFS_SUS_PATH
    need_config CONFIG_KSU_SUSFS_SUS_MOUNT
    need_config CONFIG_KSU_SUSFS_SUS_KSTAT
    need_config CONFIG_KSU_SUSFS_SPOOF_UNAME
    need_config CONFIG_KSU_SUSFS_ENABLE_LOG
    need_config CONFIG_KSU_SUSFS_HIDE_KSU_SUSFS_SYMBOLS
    need_config CONFIG_KSU_SUSFS_SPOOF_CMDLINE_OR_BOOTCONFIG
    need_config CONFIG_KSU_SUSFS_OPEN_REDIRECT
    need_config CONFIG_KSU_SUSFS_SUS_MAP
    if grep -q 'v1\.5\.7\|KSU_REF_SUSFS_V157' "$ARTIFACT_DIR/build-info.txt"; then
      echo "unexpected legacy SUSFS v1.5.7 compatibility marker in build-info" >&2
      exit 1
    fi
    ;;
  *)
    echo "unknown artifact track: $TRACK" >&2
    exit 1
    ;;
esac

echo "artifact verification passed: $TRACK"
