#!/bin/bash

#Working directory for script to reference resources
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
  TARGET="$(readlink "$SOURCE")"
  if [[ $TARGET == /* ]]; then
    echo "SOURCE '$SOURCE' is an absolute symlink to '$TARGET'"
    SOURCE="$TARGET"
  else
    DIR="$( dirname "$SOURCE" )"
    echo "SOURCE '$SOURCE' is a relative symlink to '$TARGET' (relative to '$DIR')"
    SOURCE="$DIR/$TARGET" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
  fi
done
echo "SOURCE is '$SOURCE'"
RDIR="$( dirname "$SOURCE" )"
DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
if [ "$DIR" != "$RDIR" ]; then
  echo "DIR '$RDIR' resolves to '$DIR'"
fi
echo "DIR is '$DIR'"

# Determine OS version
osvers=$(sw_vers -productVersion | awk -F. '{print $2}')

#Variables for installer
#DMG="ScanSnap.dmg"
#DMGVolume="/Volumes/ScanSnap"
Installer="$DIR/PKG/Universal Type Client 6.1.2.pkg"

UTC () {
    /usr/bin/killall "Universal Type Client"
    /usr/bin/killall "FMCore"
    rm -rf /Applications/Universal\ Type\ Client.app/
    /usr/sbin/installer -pkg "$Installer" -target / -allowUntrusted
    "$DIR"/dockutil --replacing /Applications/Universal\ Type\ Client.app --allhomes
}

if [[ ${osvers} -ge 11 ]]; then
    UTC
fi

exit 0