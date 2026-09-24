#!/usr/bin/env bash
#
# Memo release helper.
#
# Builds a Release archive, exports Memo.app, packages it into a .dmg
# (via create-dmg), signs it with Sparkle's EdDSA key (from the login
# Keychain), and prints (optionally inserts) the appcast.xml <item>
# entry for the release.
#
# Requires: create-dmg (brew install create-dmg)
#
# This script does NOT push to git, create a GitHub release, or upload
# anything — it only prepares local files and prints the exact commands
# to finish the release yourself.
#
# Usage:
#   scripts/release.sh                    # use version/build from the Xcode project
#   scripts/release.sh --version 1.1 --build 3

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
XCODEPROJ="$PROJECT_DIR/Memo Todo App.xcodeproj"
SCHEME="MyApp"
REPO="LaluIman/Memo"
BUILD_DIR="$PROJECT_DIR/build"
ARCHIVE_PATH="$BUILD_DIR/Memo.xcarchive"
APPCAST_PATH="$PROJECT_DIR/appcast.xml"
MARKER="<!-- RELEASE_ITEMS_START: scripts/release.sh inserts new <item> entries directly below this line. Do not remove or duplicate this comment. -->"

VERSION=""
BUILD_NUMBER=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --version) VERSION="$2"; shift 2 ;;
    --build) BUILD_NUMBER="$2"; shift 2 ;;
    *) echo "Unknown argument: $1" >&2; exit 1 ;;
  esac
done

echo "==> Reading build settings"
SETTINGS=$(xcodebuild -project "$XCODEPROJ" -scheme "$SCHEME" -configuration Release -showBuildSettings 2>/dev/null)

if [[ -z "$VERSION" ]]; then
  VERSION=$(echo "$SETTINGS" | awk -F' = ' '/ MARKETING_VERSION /{print $2; exit}')
fi
if [[ -z "$BUILD_NUMBER" ]]; then
  BUILD_NUMBER=$(echo "$SETTINGS" | awk -F' = ' '/ CURRENT_PROJECT_VERSION /{print $2; exit}')
fi

if [[ -z "$VERSION" || -z "$BUILD_NUMBER" ]]; then
  echo "Could not determine version/build number from the project." >&2
  echo "Pass them explicitly: scripts/release.sh --version 1.1 --build 3" >&2
  exit 1
fi

echo "==> Releasing Memo v$VERSION (build $BUILD_NUMBER)"

echo "==> Cleaning old build directory"
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

echo "==> Archiving (Release configuration, ad-hoc signed)"
if ! xcodebuild -project "$XCODEPROJ" -scheme "$SCHEME" -configuration Release \
  -archivePath "$ARCHIVE_PATH" archive; then
  echo "Archive failed." >&2
  exit 1
fi

APP_PATH="$ARCHIVE_PATH/Products/Applications/Memo.app"
if [[ ! -d "$APP_PATH" ]]; then
  echo "Archive did not produce Memo.app at expected path: $APP_PATH" >&2
  exit 1
fi

if ! command -v create-dmg >/dev/null 2>&1; then
  echo "create-dmg not found. Install it with: brew install create-dmg" >&2
  exit 1
fi

DMG_NAME="Memo-$VERSION.dmg"
DMG_PATH="$BUILD_DIR/$DMG_NAME"

echo "==> Building DMG"
rm -f "$DMG_PATH"
create-dmg \
  --volname "Memo $VERSION" \
  --window-size 600 400 \
  --icon-size 100 \
  --icon "Memo.app" 175 190 \
  --app-drop-link 425 190 \
  "$DMG_PATH" \
  "$APP_PATH" \
  || {
    # create-dmg exits non-zero even on success in some environments (e.g. AppleScript
    # warnings when Finder can't set icon positions); treat it as fatal only if no DMG appeared.
    if [[ ! -f "$DMG_PATH" ]]; then
      echo "create-dmg failed and no DMG was produced." >&2
      exit 1
    fi
    echo "create-dmg reported a non-fatal warning; DMG was created at $DMG_PATH" >&2
  }

echo "==> Locating Sparkle's sign_update tool"
SIGN_UPDATE="$PROJECT_DIR/Vendor/SparkleTools/sign_update"

if [[ ! -x "$SIGN_UPDATE" ]]; then
  echo "Could not find Sparkle's sign_update tool at $SIGN_UPDATE." >&2
  echo "It should be vendored in the repo under Vendor/SparkleTools/. Re-download it from:" >&2
  echo "  https://github.com/sparkle-project/Sparkle/releases (Sparkle-for-Swift-Package-Manager.zip, bin/ folder)" >&2
  exit 1
fi

echo "==> Signing update with Sparkle (using Keychain private key)"
SIGN_OUTPUT=$("$SIGN_UPDATE" "$DMG_PATH")
echo "$SIGN_OUTPUT"

ED_SIGNATURE=$(echo "$SIGN_OUTPUT" | sed -n 's/.*sparkle:edSignature="\([^"]*\)".*/\1/p')
FILE_LENGTH=$(echo "$SIGN_OUTPUT" | sed -n 's/.*length="\([^"]*\)".*/\1/p')

if [[ -z "$FILE_LENGTH" ]]; then
  FILE_LENGTH=$(stat -f%z "$DMG_PATH")
fi

if [[ -z "$ED_SIGNATURE" ]]; then
  echo "Could not parse edSignature from sign_update output. Check the output above and fill it in manually." >&2
fi

PUB_DATE=$(date -u "+%a, %d %b %Y %H:%M:%S +0000")
DOWNLOAD_URL="https://github.com/$REPO/releases/download/v$VERSION/$DMG_NAME"

ITEM_FILE=$(mktemp)
cat > "$ITEM_FILE" <<EOF
        <item>
            <title>Version $VERSION</title>
            <sparkle:releaseNotesLink>https://github.com/$REPO/releases/tag/v$VERSION</sparkle:releaseNotesLink>
            <pubDate>$PUB_DATE</pubDate>
            <enclosure
                url="$DOWNLOAD_URL"
                sparkle:version="$BUILD_NUMBER"
                sparkle:shortVersionString="$VERSION"
                length="$FILE_LENGTH"
                type="application/x-apple-diskimage"
                sparkle:edSignature="$ED_SIGNATURE"
            />
            <sparkle:minimumSystemVersion>27.0</sparkle:minimumSystemVersion>
        </item>
EOF

echo ""
echo "==> Appcast entry for v$VERSION:"
cat "$ITEM_FILE"

if [[ ! -f "$APPCAST_PATH" ]]; then
  echo "appcast.xml not found at $APPCAST_PATH — skipping auto-insert." >&2
elif ! grep -qF "$MARKER" "$APPCAST_PATH"; then
  echo "Could not find the insertion marker in appcast.xml — skipping auto-insert. Paste the entry above manually." >&2
else
  read -r -p "Insert this entry into appcast.xml automatically? [y/N] " CONFIRM
  if [[ "$CONFIRM" =~ ^[Yy]$ ]]; then
    ESCAPED_MARKER=$(printf '%s\n' "$MARKER" | sed 's/[.[\*^$/]/\\&/g')
    sed -i '' "/$ESCAPED_MARKER/r $ITEM_FILE" "$APPCAST_PATH"
    echo "Inserted into appcast.xml. Review the diff before committing."
  fi
fi

rm -f "$ITEM_FILE"

echo ""
echo "==> Build artifact: $DMG_PATH"
echo ""
echo "==> Next steps:"
echo "1. Review appcast.xml changes: git diff appcast.xml"
echo "2. Tag and push: git tag v$VERSION && git push origin v$VERSION"
echo "3. Create the GitHub release with the DMG attached:"
echo "     gh release create v$VERSION \"$DMG_PATH\" --title \"Memo $VERSION\" --generate-notes"
echo "4. Commit and push appcast.xml so the app's feed picks up the new version:"
echo "     git add appcast.xml && git commit -m \"Release v$VERSION\" && git push"
echo ""
echo "Note: this build is ad-hoc signed (no Apple Developer Program membership)."
echo "First-time installers still need to approve it once via System Settings ->"
echo "Privacy & Security -> Open Anyway. Updates delivered through Sparkle after"
echo "that do not require repeating this step."
