#!/bin/bash
set -e # Stop the script immediately if any command fails

# ==========================================
# VARIABLES CONFIGURATION
# ==========================================
# We use /output so files persist even if the container crashes
WORK_DIR="/output"
INST_DIR="/output/musl_libs"

# Compiler flags for MUSL (Static & Optimized)
export CC="musl-gcc"
export CFLAGS="-static -Os"
export LDFLAGS="-static"

# ==========================================
# 1. SETUP DEBIAN BUSTER ENVIRONMENT
# ==========================================
echo "=== 1. Setting up Repositories and Tools ==="

# Debian Buster is EOL (End Of Life), we must use 'archive' repositories
echo "deb http://archive.debian.org/debian buster main" > /etc/apt/sources.list
echo "deb http://archive.debian.org/debian-security buster/updates main" >> /etc/apt/sources.list

# Update and install dependencies (ignoring valid-until checks for old repos)
apt-get -o Acquire::Check-Valid-Until=false update
apt-get install -y --force-yes build-essential wget pkg-config musl-tools file

# Create installation directory for our custom libs
mkdir -p "$INST_DIR"

# ==========================================
# 2. COMPILE ZLIB (1.3.1)
# ==========================================
echo "=== 2. Compiling ZLIB 1.3.1 ==="
cd "$WORK_DIR"
rm -rf zlib-1.3.1 zlib*.tar.gz # Clean up previous attempts
wget -q --no-check-certificate https://zlib.net/zlib-1.3.1.tar.gz
tar xzf zlib-1.3.1.tar.gz
cd zlib-1.3.1

./configure --static --prefix="$INST_DIR"
make -j$(nproc)
make install

# ==========================================
# 3. COMPILE OPENSSL (1.1.1w)
# ==========================================
echo "=== 3. Compiling OpenSSL 1.1.1w ==="
cd "$WORK_DIR"
rm -rf openssl-1.1.1w openssl*.tar.gz
wget -q --no-check-certificate https://www.openssl.org/source/openssl-1.1.1w.tar.gz
tar xzf openssl-1.1.1w.tar.gz
cd openssl-1.1.1w

# CRITICAL FIX: 'no-afalgeng' prevents the "linux/version.h" error on MUSL
# CRITICAL FIX: 'linux-generic32' ensures compatibility with old ARMv5 kernels
./Configure linux-generic32 no-shared no-async no-afalgeng \
    --prefix="$INST_DIR" --openssldir="$INST_DIR" -DOPENSSL_NO_SECURE_MEMORY

make -j$(nproc)
make install_sw

# ==========================================
# 4. COMPILE CURL (8.11.0)
# ==========================================
echo "=== 4. Compiling cURL 8.11.0 ==="
cd "$WORK_DIR"
rm -rf curl-8.11.0 curl*.tar.gz
wget -q --no-check-certificate https://curl.se/download/curl-8.11.0.tar.gz
tar xzf curl-8.11.0.tar.gz
cd curl-8.11.0

# Configure cURL to use our custom Zlib and OpenSSL from $INST_DIR
./configure \
    --disable-shared \
    --enable-static \
    --disable-ldap --disable-ldaps \
    --with-zlib="$INST_DIR" \
    --with-openssl="$INST_DIR" \
    --without-libpsl \
    --without-libidn2 \
    --prefix=/usr/local \
    --disable-threaded-resolver \
    LDFLAGS="-static" \
    PKG_CONFIG="pkg-config --static"

# CRITICAL STEP:
# We invoke make with -all-static and explicitly point to the library path (-L)
echo "--- Linking final binary ---"
make -j$(nproc) LDFLAGS="-all-static -L$INST_DIR/lib"

# ==========================================
# 5. FINALIZE
# ==========================================
echo "=== 5. Packaging ==="
# Remove debug symbols to reduce file size
strip -s src/curl
# Copy to the output directory with a descriptive name
cp src/curl "$WORK_DIR/curl-armv5-musl-auto"

echo " "
echo "✅ BUILD SUCCESSFUL!"
echo "File location: build_curl/curl-armv5-musl-auto"
ls -lh "$WORK_DIR/curl-armv5-musl-auto"
