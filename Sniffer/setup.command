#!/bin/sh
THUNDER_VERSION="3.3.9"
THUNDER_INFO="/Applications/Thunder.app/Contents/Info.plist"
THUNDER_URL="http://down.sandai.net/mac/thunder_mac.dmg"
THUNDER_FILE="/tmp/thunder$$.dmg"
THUNDER_MOUNT="/tmp/thunder_dmg"
DIR=`dirname "$0"`
set -x
function install_thunder()
{
	killall Thunder
	sleep 1
	if [[ ! -e $THUNDER_FILE ]];then
		echo "\n ++Download thunder $FIX_VERSION from $THUNDER_URL\n"
		curl -o $THUNDER_FILE $THUNDER_URL
	fi
	echo "++start to convert..."
	 hdiutil convert $THUNDER_FILE -o ${THUNDER_FILE}.cdr -format UDTO
	if [[ -e ${THUNDER_FILE}.cdr ]];then
		mkdir -p $THUNDER_MOUNT
		echo "++start to attach..."
		 hdiutil attach ${THUNDER_FILE}.cdr -mountpoint ${THUNDER_MOUNT} -noverify -noautofsck -nobrowse
		if [[ -d  ${THUNDER_MOUNT}/Thunder.app ]];then
			 ditto $THUNDER_MOUNT/Thunder.app /Applications/Thunder.app
			 hdiutil detach  ${THUNDER_MOUNT}
			rm -Rf ${THUNDER_MOUNT}
			rm -Rf ${THUNDER_FILE}.cdr
		else 
			echo "**attaching failed!***"
		fi

	else
		echo "**converting failed!**"
	fi
}

function main()
{
	if [[ -e $THUNDER_INFO ]];then
		version=`defaults read ${THUNDER_INFO} CFBundleShortVersionString`
		echo "Version:$version"
		if ! [[ "$THUNDER_VERSION" == "$version" ]];then
			rm -Rf  /Applications/Thunder.app
			 install_thunder
		else
			echo "version is up-to-date!"
		fi
	else
		 install_thunder
	fi
	defaults write com.xunlei.Thunder MacThunderExtension "$DIR/Products"
	sleep 1
	ditto /Applications/Thunder.app/Contents/Frameworks/MacXLSDKs.framework "$DIR/Frameworks/MacXLSDKs.framework/"
	xcodebuild -project $DIR/../Spider.xcodeproj -scheme sniffer clean -configuration Release
	xcodebuild -project $DIR/../Spider.xcodeproj -scheme sniffer build -configuration Release
	open -a /Applications/Thunder.app/Contents/MacOS/Thunder 
}
main
