#!/bin/bash
ADDONNAME=$(jq -r '.name' manifest.json)
ADDONVERSION=$(jq -r '.version' manifest.json)
echo "Building $ADDONNAME $ADDONVERSION"
echo "Requirements:"
echo "- jq"
echo "- git"
echo "- web-ext"
echo "- npm"

if [[ ! -f "browser-polyfill.min.js" ]]; then
	git clone https://github.com/mozilla/webextension-polyfill polyfill
	cd polyfill
	npm install
	npm run build
	npm run test
	cp dist/browser-polyfill.min.js ../browser-polyfill.min.js
	cd ..
	rm -rf polyfill
fi

rm -rf build 2>/dev/null

# Build ZIP - Chrome
mkdir build
shopt -s extglob  # to enable extglob
cp -r !(build*) build/

cd build
rm -rf web-ext-artifacts
#jq -r 'del(.applications) | del(.browser_action.browser_style) | del(.options_ui.browser_style)' manifest.json > manifest-chrome.json #Chrome
#jq -r '.background |= with_entries(if .key == "scripts" then .key = "service_worker" else . end)' manifest.json > manifest-chrome.json
jq -r '.background |= with_entries(if .key == "scripts" then {key: "service_worker", value: .value[0]} else . end)' manifest.json > manifest-chrome2.json
jq -r 'del(.browser_specific_settings)' manifest-chrome2.json > manifest-chrome.json
rm manifest.json #Chrome
rm manifest-chrome2.json #Chrome
mv manifest-chrome.json manifest.json #Chrome

cp browser-polyfill.min.js fastnav.js.temp
cat fastnav.js >> fastnav.js.temp
rm fastnav.js
mv fastnav.js.temp fastnav.js

cp browser-polyfill.min.js options.js.temp
cat options.js >> options.js.temp
rm options.js
mv options.js.temp options.js

cp browser-polyfill.min.js background.js.temp
cat background.js >> background.js.temp
rm background.js
mv background.js.temp background.js

echo ""
echo "Building ZIP for Chrome.."
web-ext build --ignore-files *.sh images *.md *.txt .gitignore LICENSE

cd web-ext-artifacts
filenamechrome=$(ls *.zip)
mv "$filenamechrome" "${filenamechrome/zip/chrome.zip}"

cd ../..
yes | cp build/web-ext-artifacts/* web-ext-artifacts/

rm -rf build/web-ext-artifacts
rm -rf build

# Build ZIP - Firefox
mkdir build
shopt -s extglob  # to enable extglob
cp -r !(build*) build/

cd build
rm -rf web-ext-artifacts
rm browser-polyfill.min.js
echo ""
echo "Building ZIP for Firefox.."
web-ext build --ignore-files build.sh images *.md *.txt .gitignore LICENSE

cd web-ext-artifacts
filenamefirefox=$(ls *.zip)
mv "$filenamefirefox" "${filenamefirefox/zip/firefox.zip}"

cd ../..
yes | cp build/web-ext-artifacts/* web-ext-artifacts/

rm -rf build
rm browser-polyfill.min.js

echo ""
echo "Done building $ADDONNAME"
find web-ext-artifacts -mmin -1 -type f -print
