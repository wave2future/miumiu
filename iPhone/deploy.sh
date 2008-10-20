#!/bin/sh

CONFIG="$1"
IPHONE_IPADDR="$2"
APP=MiuMiu
XCODE_PROJ="$APP.xcodeproj"

PREFIX="[** DEPLOY TO $IPHONE_IPADDR **]"
AUTH=root@$IPHONE_IPADDR

if [ -z "$CONFIG" -o -z "$IPHONE_IPADDR" ]; then
    echo "Usage: deploy.sh (Debug|Release) [IP Address]"
    exit 1
fi

echo "$PREFIX Building..."
if ! xcodebuild -project $XCODE_PROJ -configuration $CONFIG; then
    echo "$PREFIX Compile error, aborting!"
    exit 1
fi

echo "$PREFIX Removing old version from iPhone..."
ssh $AUTH "rm -rf /Applications/$APP.app"

echo "$PREFIX Copying new version to iPhone..."
scp -r build/$CONFIG-iphoneos/$APP.app $AUTH:/Applications/

echo "$PREFIX Signing application on iPhone and restarting SpringBoard"
ssh $AUTH "ldid -S /Applications/$APP.app/$APP && killall -HUP SpringBoard"

echo "$PREFIX Done!"
