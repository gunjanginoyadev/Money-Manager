#!/usr/bin/env bash
# Build Flutter web for static hosting (e.g. Vercel).
# Set as the Vercel "Build Command": bash build.sh
# Firebase config is defined statically in lib/core/config/app_env.dart.

set -euo pipefail

cd "$(dirname "$0")"

FLUTTER_SDK="${FLUTTER_SDK:-$PWD/.flutter_sdk}"

if [[ ! -x "$FLUTTER_SDK/bin/flutter" ]]; then
  rm -rf "$FLUTTER_SDK"
  git clone https://github.com/flutter/flutter.git -b stable --depth 1 "$FLUTTER_SDK"
fix

export PATH="$FLUTTER_SDK/bin:$PATH"

flutter config --no-analytics >/dev/null
flutter pub get
flutter build web --release
