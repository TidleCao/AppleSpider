#!/bin/sh
THUNDER_VERSION="4170"
EXTENSION_PATH="$HOME/Library/Application Support/Thunder/Extensions/"
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
		version=`defaults read ${THUNDER_INFO} CFBundleVersion`
		echo "Version:$version"
		if  [[ $THUNDER_VERSION -gt $version ]];then
			rm -Rf  /Applications/Thunder.app
			 install_thunder
		else
			echo "version is up-to-date!"
		fi
	else
		 install_thunder
	fi
	mkdir -p "$EXTENSION_PATH"
	cd "$EXTENSION_PATH"
	defaults write com.xunlei.Thunder MacThunderExtension "$EXTENSION_PATH"
	ditto "$DIR/sniffer.xlplugin"  ./sniffer.xlplugin
	xattr -rc sniffer.xlplugin
	killall Thunder
	sleep 1
	open -a /Applications/Thunder.app/Contents/MacOS/Thunder 
}
main
