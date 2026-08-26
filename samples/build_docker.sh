#!/bin/bash
#------------------------------------------------------
# Copyright (c) 2026, Elehobica
# Released under the BSD-2-Clause
# refer to https://opensource.org/licenses/BSD-2-Clause
#------------------------------------------------------
#
# Local Docker build script that mirrors .github/workflows/build-binaries.yml.
# Uses the same SDK image as CI (elehobica/pico-sdk-dev-docker:sdk-2.3.0)
# and runs cmake/make inside the container.
#
# The sample to build is taken from the current working directory, so run it
# from inside the sample folder you want to build, e.g.:
#   cd samples/sine_wave_i2s_32b
#   ../build_docker.sh          # both targets -> build/ , build2/

set -e

IMAGE="elehobica/pico-sdk-dev-docker:sdk-2.3.0"
SDK_PATH_IN_IMAGE="/home/rp2dev/pico/pico-sdk"   # PICO_SDK_PATH inside the container
SAMPLES_DIR="$(cd "$(dirname "$0")" && pwd)"     # .../samples
PROJECT_ROOT="$(cd "$SAMPLES_DIR/.." && pwd)"    # repository root

# Read the Pico SDK version from pico_sdk_version.cmake inside the container.
sdk_version() {
  docker run --rm "$IMAGE" bash -c '
    f="'"$SDK_PATH_IN_IMAGE"'/pico_sdk_version.cmake"
    maj=$(sed -n "s/^[[:space:]]*set(PICO_SDK_VERSION_MAJOR \([0-9]*\)).*/\1/p" "$f")
    min=$(sed -n "s/^[[:space:]]*set(PICO_SDK_VERSION_MINOR \([0-9]*\)).*/\1/p" "$f")
    rev=$(sed -n "s/^[[:space:]]*set(PICO_SDK_VERSION_REVISION \([0-9]*\)).*/\1/p" "$f")
    if [[ -n "$maj$min$rev" ]]; then echo "${maj}.${min}.${rev}"; else echo "unknown"; fi
  '
}

# Sample is determined by the caller's current working directory.
SAMPLE_DIR="$PWD"
SAMPLE_NAME="$(basename "$SAMPLE_DIR")"

usage() {
  cat <<EOF
Usage: (cd samples/<sample> && ../$(basename "$0") [target] [options])

The sample to build is taken from the current working directory. Run this
script from inside the sample folder you want to build.

Targets:
  pico    Build for Pico     (rp2040, output: build/)
  pico2   Build for Pico 2   (rp2350, output: build2/)
  all     Build both (default)

Options:
  -h, --help     Show this help
  -k, --keep     Keep build directory contents (incremental build)
EOF
}

TARGET=all
KEEP=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    pico|pico2|all) TARGET="$1" ;;
    -h|--help)      usage; exit 0 ;;
    -k|--keep)      KEEP=1 ;;
    *) echo "Unknown option: $1" >&2; usage; exit 1 ;;
  esac
  shift
done

# Must be run from a sample directory directly under samples/ that has a CMakeLists.txt.
if [[ "$(dirname "$SAMPLE_DIR")" != "$SAMPLES_DIR" || ! -f "$SAMPLE_DIR/CMakeLists.txt" ]]; then
  echo "error: run this from inside a sample folder under samples/ (current: $SAMPLE_DIR)" >&2
  usage
  exit 1
fi

# Path of the sample relative to the repository root (mounted at /workspace).
SAMPLE_REL="samples/$SAMPLE_NAME"

echo "Sample: $SAMPLE_REL"
echo "Pico SDK version: $(sdk_version) (from $SDK_PATH_IN_IMAGE)"

# Run cmake/make inside the SDK container.
# Args: $1=build_dir  $2=extra cmake options (may be empty)
run_build() {
  local build_dir="$1"
  local cmake_extra="$2"

  if [[ "$KEEP" -eq 0 ]]; then
    rm -rf "$SAMPLE_DIR/$build_dir"
  fi
  mkdir -p "$SAMPLE_DIR/$build_dir"

  docker run --rm \
    --user "$(id -u):$(id -g)" \
    -e HOME=/tmp \
    -e PICO_SDK_PATH="$SDK_PATH_IN_IMAGE" \
    -e PICO_EXTRAS_PATH=/home/rp2dev/pico/pico-extras \
    -e PICO_EXAMPLES_PATH=/home/rp2dev/pico/pico-examples \
    -v "$PROJECT_ROOT":/workspace \
    -w "/workspace/$SAMPLE_REL/$build_dir" \
    "$IMAGE" \
    bash -c "cmake $cmake_extra /workspace/$SAMPLE_REL && make -j\$(nproc)"
}

BUILT_DIRS=()

case "$TARGET" in
  pico|all)
    echo "===== Build Pico (rp2040) ====="
    run_build build ""
    BUILT_DIRS+=(build)
    ;;
esac
case "$TARGET" in
  pico2|all)
    echo "===== Build Pico 2 (rp2350) ====="
    run_build build2 "-DPICO_PLATFORM=rp2350 -DPICO_BOARD=pico2"
    BUILT_DIRS+=(build2)
    ;;
esac

echo ""
echo "===== Output ====="
for d in "${BUILT_DIRS[@]}"; do
  for uf2 in "$SAMPLE_DIR/$d"/*.uf2; do
    [[ -f "$uf2" ]] && echo "  $SAMPLE_REL/$d/$(basename "$uf2")"
  done
done
