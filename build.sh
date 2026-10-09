#!/bin/sh
set -eu
cd "$(dirname "$0")"

app="SleepSwitch.app/Contents"
mkdir -p "$app/MacOS"
/usr/bin/xcrun swiftc -O -parse-as-library -target "$(/usr/bin/uname -m)-apple-macosx11.0" \
    -module-cache-path "${TMPDIR:-/tmp}/SleepSwitch-module-cache" \
    SleepSwitch.swift -o "$app/MacOS/SleepSwitch"

cat > "$app/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
    <key>CFBundleExecutable</key><string>SleepSwitch</string>
    <key>CFBundleIdentifier</key><string>local.sleepswitch</string>
    <key>CFBundleName</key><string>SleepSwitch</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleVersion</key><string>1</string>
    <key>LSMinimumSystemVersion</key><string>11.0</string>
    <key>LSUIElement</key><true/>
</dict></plist>
PLIST

/usr/bin/codesign --force --sign - "SleepSwitch.app"
printf 'Built %s/SleepSwitch.app\n' "$PWD"
