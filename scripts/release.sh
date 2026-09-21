#!/usr/bin/env bash
#
# Memo release helper.
#
# Builds a Release archive, exports Memo.app, zips it, signs it with
# Sparkle's EdDSA key (from the login Keychain), and prints (optionally
# inserts) the appcast.xml <item> entry for the release.
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

echo "==> Archiving (Release configuration)"
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

ZIP_NAME="Memo-$VERSION.zip"
ZIP_PATH="$BUILD_DIR/$ZIP_NAME"

echo "==> Zipping app"
ditto -c -k --keepParent "$APP_PATH" "$ZIP_PATH"

echo "==> Locating Sparkle's sign_update tool"
SIGN_UPDATE=$(find "$HOME/Library/Developer/Xcode/DerivedData" -maxdepth 8 \
  -path "*/SourcePackages/artifacts/sparkle/Sparkle/bin/sign_update" -print -quit 2>/dev/null || true)

if [[ -z "$SIGN_UPDATE" ]]; then
  echo "Could not find Sparkle's sign_update tool." >&2
  echo "Open the project in Xcode at least once (so Swift Package Manager resolves Sparkle), then re-run this script." >&2
  exit 1
fi

echo "==> Signing update with Sparkle (using Keychain private key)"
SIGN_OUTPUT=$("$SIGN_UPDATE" "$ZIP_PATH")
echo "$SIGN_OUTPUT"

ED_SIGNATURE=$(echo "$SIGN_OUTPUT" | sed -n 's/.*sparkle:edSignature="\([^"]*\)".*/\1/p')
FILE_LENGTH=$(echo "$SIGN_OUTPUT" | sed -n 's/.*length="\([^"]*\)".*/\1/p')

if [[ -z "$FILE_LENGTH" ]]; then
  FILE_LENGTH=$(stat -f%z "$ZIP_PATH")
fi

if [[ -z "$ED_SIGNATURE" ]]; then
  echo "Could not parse edSignature from sign_update output. Check the output above and fill it in manually." >&2
fi

PUB_DATE=$(date -u "+%a, %d %b %Y %H:%M:%S +0000")
DOWNLOAD_URL="https://github.com/$REPO/releases/download/v$VERSION/$ZIP_NAME"

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
                type="application/octet-stream"
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
echo "==> Build artifact: $ZIP_PATH"
echo ""
echo "==> Next steps:"
echo "1. Review appcast.xml changes: git diff appcast.xml"
echo "2. Tag and push: git tag v$VERSION && git push origin v$VERSION"
echo "3. Create the GitHub release with the zip attached:"
echo "     gh release create v$VERSION \"$ZIP_PATH\" --title \"Memo $VERSION\" --generate-notes"
echo "4. Commit and push appcast.xml so the app's feed picks up the new version:"
echo "     git add appcast.xml && git commit -m \"Release v$VERSION\" && git push"
echo ""
echo "Note: this build is signed with whatever identity Xcode's automatic signing"
echo "picked (currently an Apple Development certificate). For a smoother experience"
echo "for people downloading directly from GitHub (no Gatekeeper warning), you'd want"
echo "a Developer ID Application certificate plus notarization — ask if you want that"
echo "added to this script."
