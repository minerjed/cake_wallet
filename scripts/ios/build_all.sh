#!/bin/sh

if [ -z "$APP_IOS_TYPE" ]; then
	echo "Please set APP_IOS_TYPE"
	exit 1
fi

DIR=$(dirname "$0")

case $APP_IOS_TYPE in
	"monero.com") $DIR/build_monero_all.sh ;;
	"cakewallet") $DIR/build_monero_all.sh && $DIR/build_haven.sh && $DIR/build_xcash.sh;;
	"haven")      $DIR/build_haven_all.sh ;;
	"xcash")      $DIR/build_xcash_all.sh ;;
esac
