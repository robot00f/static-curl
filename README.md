:mechanical_arm: Static curl (ARMv5 Legacy Support) :mechanical_arm:
-----------

This project provides scripts to build a **fully static curl binary** using MUSL Libc. 

**Main Feature:**
This build is specifically patched to bypass the `FATAL: kernel too old` error. It is designed for legacy embedded devices (IP Cameras, HiSilicon Hi3518, old routers, etc.) running very old Linux Kernels (2.6.x - 3.x).

### :inbox_tray: Download Latest Release

You can download the **ARMv5 MUSL** binary directly from the link below:

- **[curl-armv5-musl](https://github.com/robot00f/static-curl/releases/download/v8.11.0-armv5-static/curl-armv5-musl)**
  *(Features: Static linked, OpenSSL 1.1.1w, Zlib, TLS 1.3 support, Kernel version check bypassed)*

**Full Release Page:**
[https://github.com/robot00f/static-curl/releases/tag/v8.11.0-armv5-static](https://github.com/robot00f/static-curl/releases/tag/v8.11.0-armv5-static)

### Usage on Embedded Devices

Since older devices often lack modern CA Certificates, use `-k` (insecure) or provide your own certificate bundle:

```bash
# 1. Make it executable
chmod +x curl-armv5-musl

# 2. Run
./curl-armv5-musl -k -I https://www.google.com
