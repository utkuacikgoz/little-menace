#!/bin/sh
# Runs the MenaceCore logic tests. Works on macOS (Xcode toolchain) and Linux (swift.org toolchain).
set -e
cd "$(dirname "$0")/../MenaceCore"
swift test "$@"
