#!/bin/zsh

# Creates a local, unsigned DMG from the current Release build.
# This script deliberately does not upload anything to GitHub.

set -euo pipefail

script_dir="${0:A:h}"
project_dir="${script_dir:h}"
work_dir="$(mktemp -d "${TMPDIR:-/tmp}/i-panel-dmg.XXXXXX")"
derived_data_dir="${work_dir}/DerivedData"
staging_dir="${work_dir}/staging"

cleanup() {
    [[ -d "${work_dir}" ]] && /bin/rm -rf "${work_dir}"
}
trap cleanup EXIT

print "Building an unsigned Release app…"
xcodebuild \
    -project "${project_dir}/IPanel.xcodeproj" \
    -scheme IPanel \
    -configuration Release \
    -sdk macosx \
    -destination 'generic/platform=macOS' \
    -derivedDataPath "${derived_data_dir}" \
    ARCHS='arm64 x86_64' \
    ONLY_ACTIVE_ARCH=NO \
    CODE_SIGNING_ALLOWED=NO \
    build

app_path="${derived_data_dir}/Build/Products/Release/IPanel.app"
if [[ ! -d "${app_path}" ]]; then
    print -u2 "Release app was not created: ${app_path}"
    exit 1
fi

version="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "${app_path}/Contents/Info.plist")"
build="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "${app_path}/Contents/Info.plist")"
output_dir="${project_dir}/dist"
output_path="${output_dir}/i-Panel-${version}-build-${build}-unsigned.dmg"

if [[ -e "${output_path}" ]]; then
    print -u2 "A DMG already exists at ${output_path}. Move or rename it before running this script again."
    exit 1
fi

/bin/mkdir -p "${output_dir}" "${staging_dir}"
/usr/bin/ditto "${app_path}" "${staging_dir}/i-Panel.app"
/bin/ln -s /Applications "${staging_dir}/Applications"

print "Creating ${output_path}…"
/usr/bin/hdiutil create \
    -volname "i-Panel" \
    -srcfolder "${staging_dir}" \
    -format UDZO \
    -imagekey zlib-level=9 \
    "${output_path}"

print "Unsigned DMG created: ${output_path}"
print "Before public release, test the DMG on a separate local user account and prepare the Gatekeeper installation note."
