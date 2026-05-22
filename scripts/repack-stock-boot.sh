#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STOCK_BOOT="${1:-$ROOT_DIR/boot.img}"
KERNEL_IMAGE="${2:-$ROOT_DIR/work/downloaded-artifact/Image}"
OUT_BOOT="${3:-$ROOT_DIR/work/miui14-boot/repacked-boot.img}"
WORKDIR="${WORKDIR:-$ROOT_DIR/work/miui14-boot/repack}"

need_tool() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "missing required tool: $1" >&2
    echo "install android-tools first" >&2
    exit 1
  fi
}

need_tool unpack_bootimg
need_tool mkbootimg
need_tool avbtool
need_tool file

if [[ ! -s "$STOCK_BOOT" ]]; then
  echo "stock boot image not found: $STOCK_BOOT" >&2
  exit 1
fi

if [[ ! -s "$KERNEL_IMAGE" ]]; then
  echo "kernel Image not found: $KERNEL_IMAGE" >&2
  exit 1
fi

rm -rf "$WORKDIR"
mkdir -p "$WORKDIR" "$(dirname "$OUT_BOOT")"

unpack_log="$WORKDIR/unpack.log"
unpack_bootimg --boot_img "$STOCK_BOOT" --out "$WORKDIR/unpacked" | tee "$unpack_log"

ramdisk="$WORKDIR/unpacked/ramdisk"
if [[ ! -s "$ramdisk" ]]; then
  echo "stock boot ramdisk was not unpacked: $ramdisk" >&2
  exit 1
fi

header_version="$(sed -n 's/^boot image header version: //p' "$unpack_log" | tail -1)"
os_version="$(sed -n 's/^os version: //p' "$unpack_log" | tail -1)"
os_patch_level="$(sed -n 's/^os patch level: //p' "$unpack_log" | tail -1)"
cmdline="$(sed -n 's/^command line args: //p' "$unpack_log" | tail -1)"

mkboot_args=(
  --header_version "$header_version"
  --kernel "$KERNEL_IMAGE"
  --ramdisk "$ramdisk"
  --os_version "$os_version"
  --os_patch_level "$os_patch_level"
  -o "$OUT_BOOT"
)

if [[ -n "$cmdline" ]]; then
  mkboot_args+=(--cmdline "$cmdline")
fi

mkbootimg "${mkboot_args[@]}"

if avbtool info_image --image "$STOCK_BOOT" > "$WORKDIR/avb.log" 2>/dev/null; then
  algorithm="$(sed -n 's/^Algorithm:[[:space:]]*//p' "$WORKDIR/avb.log" | head -1)"
  partition_size="$(sed -n 's/^Image size:[[:space:]]*//p' "$WORKDIR/avb.log" | head -1 | awk '{print $1}')"
  partition_name="$(sed -n 's/^      Partition Name:[[:space:]]*//p' "$WORKDIR/avb.log" | head -1)"

  if [[ "$algorithm" == "NONE" && -n "$partition_size" && -n "$partition_name" ]]; then
    avb_args=(
      add_hash_footer
      --image "$OUT_BOOT"
      --partition_name "$partition_name"
      --partition_size "$partition_size"
      --algorithm NONE
    )

    while IFS= read -r prop; do
      key="${prop%% -> *}"
      value="${prop#* -> }"
      avb_args+=(--prop "$key:$value")
    done < <(sed -n "s/^    Prop: \\(.*\\) -> '\\(.*\\)'$/\\1 -> \\2/p" "$WORKDIR/avb.log")

    avbtool "${avb_args[@]}"
  else
    echo "warning: stock boot has AVB algorithm '$algorithm'; unsigned repack was left without copied AVB footer" >&2
  fi
fi

echo
file "$STOCK_BOOT" "$KERNEL_IMAGE" "$OUT_BOOT"
echo
unpack_bootimg --boot_img "$OUT_BOOT" --out "$WORKDIR/repacked-unpacked"
echo
avbtool info_image --image "$OUT_BOOT" || true
