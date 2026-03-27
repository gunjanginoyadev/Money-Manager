#!/usr/bin/env bash
# Build Flutter web for static hosting (e.g. Vercel).
# Set as the Vercel "Build Command": bash build.sh
# Optional: add Firebase keys in Vercel → Project → Settings → Environment Variables
# (same names as .env.example) so a real .env is generated during build.

set -euo pipefail

cd "$(dirname "$0")"

# pubspec.yaml lists asset ".env" — the file must exist for `flutter build web`.
if [[ ! -f .env ]]; then
  if [[ -n "${FIREBASE_API_KEY:-}" ]]; then
    {
      echo "FIREBASE_API_KEY=${FIREBASE_API_KEY}"
      echo "FIREBASE_APP_ID=${FIREBASE_APP_ID:-}"
      echo "FIREBASE_MESSAGING_SENDER_ID=${FIREBASE_MESSAGING_SENDER_ID:-}"
      echo "FIREBASE_PROJECT_ID=${FIREBASE_PROJECT_ID:-}"
      echo "FIREBASE_AUTH_DOMAIN=${FIREBASE_AUTH_DOMAIN:-}"
      echo "FIREBASE_STORAGE_BUCKET=${FIREBASE_STORAGE_BUCKET:-}"
      echo "FIREBASE_MEASUREMENT_ID=${FIREBASE_MEASUREMENT_ID:-}"
    } > .env
  else
    touch .env
  fi
fi

FLUTTER_SDK="${FLUTTER_SDK:-$PWD/.flutter_sdk}"

if [[ ! -x "$FLUTTER_SDK/bin/flutter" ]]; then
  rm -rf "$FLUTTER_SDK"
  git clone https://github.com/flutter/flutter.git -b stable --depth 1 "$FLUTTER_SDK"
fi

export PATH="$FLUTTER_SDK/bin:$PATH"

flutter config --no-analytics >/dev/null
flutter pub get
flutter build web --release
