<!--
This file is tri-licensed under GPLv2, Apache 2.0, or the SQLite Blessing.
You may choose any of these licenses to use this code.

In place of a legal notice, here is a blessing:
 - May you do good and not evil.
 - May you find forgiveness for yourself and forgive others.
 - May you share freely, never taking more than you give.

SPDX-License-Identifier: GPL-2.0-only OR Apache-2.0 OR blessing
-->

# License notice

This repository uses per-file licensing. The top-level project files are kept
under GPLv2, Apache 2.0, or the SQLite Blessing where that is appropriate.
Kernel patch files are not relicensed under this tri-license because they are
intended to be applied to the Linux/Xiaomi kernel tree.

## Repository files

- `README.md`, `.gitignore`, `.github/workflows/build.yml`,
  `packaging/anykernel.env`, `NOTICE.md`, and `scripts/*.sh`:
  GPL-2.0-only OR Apache-2.0 OR SQLite Blessing (`blessing`).
- `LICENSE`: repository license summary for the tri-licensed files.
- `LICENSES/`: full text for GPL-2.0-only, Apache-2.0, and SQLite Blessing.
- `patches/*.patch`: GPL-2.0-only, matching the Linux kernel source files they
  patch.

## Downloaded build inputs

The workflow downloads and builds third-party projects. Their licenses are not
changed by this repository:

- Xiaomi/MiCode kernel source: upstream Linux/Xiaomi kernel licensing.
- ReSukiSU: upstream ReSukiSU licensing.
- Non-GKI SUSFS patch source: upstream Non-GKI/SUSFS licensing.
- AnyKernel3 and its bundled tools: upstream AnyKernel3 licensing and bundled
  binary licenses.
- Android/AOSP clang and platform tools: upstream Android/AOSP licensing.

Generated artifacts combine these components and remain subject to their
respective upstream license terms. Stock `boot.img`, `vendor_boot.img`, `dtbo.img`
and other firmware images are local user-supplied files and must not be
committed to this repository.
