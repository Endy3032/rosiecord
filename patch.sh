#!/bin/bash

# Global variablse
VERSION=161.0
IPA_DIR=IPA/Discord_$VERSION.ipa
PLIST=Payload/Discord.app/Info.plist

#-------------#
# Preparation #
#-------------#

# Build output
mkdir -p Dist/
rm -rf Dist/*
rm -rf Payload

echo "[*] Directory of IPA: $IPA_DIR"

# Wait for Discord IPA to download
[[ -f "$IPA_DIR" ]] && echo "[*] IPA already exists" || curl -o $IPA_DIR https://cdn.discordapp.com/attachments/1011346757214543875/1062287485025132604/Discord_161.0.ipa &
wait $!

# Wait for IPA to unzip
unzip $IPA_DIR &
wait $!

#--------------#
# Modification #
#--------------#

# App name
plutil -replace CFBundleName -string "Enmity" $PLIST
plutil -replace CFBundleDisplayName -string "Enmity" $PLIST

# Add Enmity URL scheme
plutil -insert CFBundleURLTypes.1 -xml "<dict><key>CFBundleURLName</key><string>Enmity</string><key>CFBundleURLSchemes</key><array><string>enmity</string></array></dict>" $PLIST

# Remove device limits
plutil -remove UISupportedDevices $PLIST

# Enable iTunes file sharing
plutil -replace UISupportsDocumentBrowser -bool true $PLIST
plutil -replace UIFileSharingEnabled -bool true $PLIST

# Replace Icons
cp -rf Plumpy/* Payload/Discord.app/assets/

# Package
zip -r dist/Enmity_v${VERSION}.ipa Payload
rm -rf Payload

#-------#
# Patch #
#-------#

# Get Azule
[[ -d "Azule" ]] && echo "[*] Azule already exists" || git clone https://github.com/Al4ise/Azule &
wait $!

# Inject patches into Enmity
for Patch in $(ls Patches)
do
    Azule/azule -i Dist/Enmity_v${VERSION}.ipa -f Patches/${Patch} -o Dist &
    wait $!
    mv Dist/Enmity_v${VERSION}+${Patch}.ipa Dist/Enmity_v${VERSION}.ipa
done
