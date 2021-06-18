#!/usr/bin/env bash

echo "> WatchFlower packager (macOS x86_64)"

export APP_NAME="WatchFlower";
export APP_VERSION=2.0;
export GIT_VERSION=$(git rev-parse --short HEAD);

## CHECKS ######################################################################

if [ "$(id -u)" == "0" ]; then
  echo "This script MUST NOT be run as root" 1>&2
  exit 1
fi

if [ ${PWD##*/} != "WatchFlower" ]; then
  echo "This script MUST be run from the WatchFlower/ directory"
  exit 1
fi

## SETTINGS ####################################################################

use_contribs=false
create_package=false
upload_package=false

while [[ $# -gt 0 ]]
do
case $1 in
  -c|--contribs)
  use_contribs=true
  ;;
  -p|--package)
  create_package=true
  ;;
  -u|--upload)
  upload_package=true
  ;;
  *)
  echo "> Unknown argument '$1'"
  ;;
esac
shift # skip argument or value
done

## APP INSTALL #################################################################

#echo '---- Running make install'
#make INSTALL_ROOT=bin/ install;

#echo '---- Installation directory content recap:'
#find bin/;

## DEPLOY ######################################################################

if [[ $use_contribs = true ]] ; then
  export LD_LIBRARY_PATH=$(pwd)/contribs/src/env/macOS_x86_64/usr/lib/;
else
  export LD_LIBRARY_PATH=/usr/local/lib/;
fi

echo '---- Running macdeployqt'
macdeployqt bin/$APP_NAME.app -qmldir=qml/ -appstore-compliant;

#echo '---- Installation directory content recap:'
#find bin/;

## PACKAGE #####################################################################

if [[ $create_package = true ]] ; then
  echo '---- Compressing package'
  cd bin/;
  zip -r -X $APP_NAME-$APP_VERSION-macos.zip $APP_NAME.app;
fi

## UPLOAD ######################################################################

if [[ $upload_package = true ]] ; then
  echo '---- Uploading to transfer.sh'
  curl --upload-file $APP_NAME*.zip https://transfer.sh/$APP_NAME-git.$APP_VERSION-macOS.zip;
fi
