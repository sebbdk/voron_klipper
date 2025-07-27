#!/bin/bash

# Klipper Docker firmware builder (macOS-safe)
# Author: ChatGPT + Seb

set -euo pipefail

KLIPPER_DIR="$(pwd)"

# Check we’re in the Klipper folder
if [ ! -f "$KLIPPER_DIR/Makefile" ]; then
  echo "❌ Not in the root of a Klipper repository!"
  exit 1
fi

# Check or build the Docker image
if ! docker image inspect klipper-builder > /dev/null 2>&1; then
  echo "📦 Docker image 'klipper-builder' not found. Building..."
  docker build -t klipper-builder -f scripts/Dockerfile .
fi

# Run menuconfig
echo "🛠 Running make menuconfig in Docker..."
docker run --rm -it \
  -v "$KLIPPER_DIR":/klipper \
  -w /klipper \
  klipper-builder make menuconfig

# Clean previous builds
echo "🧹 Cleaning previous builds..."
docker run --rm \
  -v "$KLIPPER_DIR":/klipper \
  -w /klipper \
  klipper-builder make clean

# Compile!
echo "🔨 Building firmware..."
docker run --rm \
  -v "$KLIPPER_DIR":/klipper \
  -w /klipper \
  klipper-builder make

# Show result
BIN_FILE=$(find "$KLIPPER_DIR/out/" -name "*.bin" | head -n 1)

if [ -f "$BIN_FILE" ]; then
  echo "✅ Firmware build complete: $BIN_FILE"
else
  echo "❌ Build failed: no .bin file found."
  exit 1
fi
