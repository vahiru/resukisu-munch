# ReSukiSU munch build

This repository builds a Redmi K40S (`munch`) kernel with ReSukiSU and SUSFS support.

## What it does

- Clones Xiaomi `munch-s-oss`
- Clones ReSukiSU into the kernel tree
- Applies SUSFS kernel patches with fuzz for Xiaomi's 4.19 tree
- Applies munch-specific ReSukiSU hook edits
- Applies the Python 3 wrapper fix for the Xiaomi kernel tree
- Builds an AnyKernel3 zip plus `Image`, `kernel.config`, and `System.map`

## Default versions

- Xiaomi kernel: `munch-s-oss`
- ReSukiSU: `main`
- SUSFS: `1.4.2-kernel-4.19`
- GitHub Actions toolchain: AOSP `clang-r399163b`

## Local run

```bash
bash scripts/build-k40s.sh
```

Set `USE_AOSP_CLANG=1` on an x86_64 Linux host to match the GitHub Actions toolchain.

## GitHub Actions

The workflow is in `.github/workflows/build.yml`.
