#!/usr/bin/env bash
set -euo pipefail

# Love Call Boys — Firebase setup for devlancehub@gmail.com
# Run once after: firebase login:add  (choose devlancehub@gmail.com)

ACCOUNT="devlancehub@gmail.com"
APP_DIR="$(cd "$(dirname "$0")/.." && pwd)"

echo "==> Checking Firebase account: $ACCOUNT"
if ! firebase login:list 2>/dev/null | grep -q "$ACCOUNT"; then
  echo "ERROR: $ACCOUNT is not logged in."
  echo "Run: firebase login:add"
  echo "Then select: $ACCOUNT"
  exit 1
fi

echo "==> Firebase projects for $ACCOUNT"
firebase projects:list --account="$ACCOUNT"

echo ""
echo "==> Configuring FlutterFire (android + ios)"
cd "$APP_DIR"
flutterfire configure \
  --account="$ACCOUNT" \
  --project=audioboyscall-1 \
  --platforms=android,ios \
  --android-package-name=com.lovecall.love_call_boys \
  --ios-bundle-id=com.lovecall.loveCallBoys \
  --yes \
  --overwrite-firebase-options

echo ""
echo "==> Done. Files created:"
echo "  - lib/firebase_options.dart"
echo "  - android/app/google-services.json"
echo "  - ios/Runner/GoogleService-Info.plist"
