#!/bin/sh
# log will display in /var/log/install.log
DBGLOG=/dev/stdout
# log for automation test
TMLOG_DIR="/var/log/TrendMicro"
UNINSTALL_LOG="${TMLOG_DIR}/TMSM_Uninstall.log"
DAT=`date`
echo "$0 $DAT" >> $DBGLOG
export >> $DBGLOG

# check if iTIS exists
BDL_ID_TMSM_MAINUI="com.trendmicro.tmsm.MainUI"
BDL_ID_ITIS_UIMGMT="com.trendmicro.iTIS.UIMgmt"
BDL_ID_ITIS_MAINUI="com.trendmicro.iTIS.MainUI"

TM_LIBRARY_PATH="/Library/Application Support/TrendMicro"
APPLICATIONS_PATH="/Applications"

ITIS_APP_NAME="iTIS.app"
TMCC_CORE_CONFIG="/Library/Application Support/TrendMicro/common/conf/*.plist"

DEFAULT_UIMGMT_PATH="$TM_LIBRARY_PATH/TmccMac/UIMgmt.app"
DEFAULT_MAINUI_PATH="$APPLICATIONS_PATH/$ITIS_APP_NAME"

MDFIND=/usr/bin/mdfind
MDLS=/usr/bin/mdls
HEAD=/usr/bin/head
DEFAULTS=/usr/bin/defaults

OS_VERSION=`sw_vers | grep 'ProductVersion:' | egrep -o '[0-9]*(\.[0-9]*){1,2}'` 
OS_MAJOR_VERSION=`echo $OS_VERSION | cut -f 1 -d . -`
OS_MINOR_VERSION=`echo $OS_VERSION | cut -f 2 -d . -`

PKG_IDS="com.trendmicro.icore.autostart.pkg
         com.trendmicro.icore.kextention.pkg
         com.trendmicro.icore.service.pkg
         com.trendmicro.tmsm.application.trendMicroSecurity.tmcoreinst.pkg
         com.trendmicro.tmsm.application.trendMicroSecurity.tmsecurity.pkg
         com.trendmicro.tmsm.application.trendMicroSecurity.tmsecurityextra.pkg
         com.trendmicro.tmsm.tmappextra
         com.trendmicro.uninstaller"

unregister_pkgID_from_OS()
{
    if [ $OS_MAJOR_VERSION -eq 10 -a $OS_MINOR_VERSION -ge 6 ] ; then
        # 10.6 specific. Receipts are now in a package database
       	echo "Remove PKG ID from 10.6 package database" >> $DBGLOG

        for p in $PKG_IDS; do
            pkgutil --forget $p
        done
    fi
}

get_valueByKey()
{
    kMDFile="$1"
    kMDItem="$2"
    if [ ! -e "$kMDFile" ] || [ -z "$kMDItem" ]; then
        kMDItemValue=""
        return 1;
    fi
    if [ -d "$kMDFile" -a ! -z "echo $kMDFile | grep '\.app\$'" ]; then
        kMDItemValue=$($MDLS -name $kMDItem "$kMDFile" | grep $kMDItem | sed "s/$kMDItem = \"\([^\"]*\)\"/\1/")
    elif [ -f "$kMDFile" -a ! -z "echo $kMDFile | grep '\.plist\$'" ]; then
        kMDItemValue=$($DEFAULTS read "${kMDFile%.plist}" "$kMDItem")
    fi
}

chk_itis_exist ()
{
        UIMGMT_APP=$($MDFIND -onlyin "$TM_LIBRARY_PATH" "kMDItemCFBundleIdentifier = '$BDL_ID_ITIS_UIMGMT'")

        # check iTIS 1.5 whether installed
        if [ -z "$UIMGMT_APP" ]; then
            UIMGMT_APP="$DEFAULT_UIMGMT_PATH"
            get_valueByKey "${UIMGMT_APP}$DEFAULT_INFO_PLIST" CFBundleIdentifier
            if [ -z "$kMDItemValue" ]; then
                get_valueByKey "$UIMGMT_APP" kMDItemCFBundleIdentifier
            fi

            if [ "$kMDItemValue" = "$BDL_ID_ITIS_UIMGMT" ]; then
               return 1;
            fi
	else
	    return 1;
        fi

      # check itis whether installed (because that the BID of iTIS-1.0 is the same as tmsm-sa)
      CUR_ITIS_APP_PATH=$($MDFIND -onlyin "$APPLICATIONS_PATH" "kMDItemCFBundleIdentifier = '$
BDL_ID_TMSM_MAINUI'" | $HEAD -n 1)
      [ x"$CUR_ITIS_APP_PATH" = "x" ] && CUR_ITIS_APP_PATH="$DEFAULT_MAINUI_PATH"

      if [ -d $CUR_ITIS_APP_PATH ]; then
          get_valueByKey "$CUR_ITIS_APP_PATH" kMDItemFSName
          CUR_ITIS_APP_NAME=$kMDItemValue
          if [ "$CUR_ITIS_APP_NAME" = "$ITIS_APP_NAME" ]; then
              return 1;
          fi
      fi

        return 0;
}

#main logic
mkdir -m 777 -p $TMLOG_DIR
echo "[UninstallResult]" > $UNINSTALL_LOG
date -u "+StartTime=%Y-%m-%dT%H:%M:%SZ" >> $UNINSTALL_LOG

unregister_pkgID_from_OS
chk_itis_exist
if [ $? -eq 1 ]; then
	# iTIS exists, quit the uninstallation process
        exit 0
fi


# remove TMSM_SA
UNINSTALL_SH="/Library/Application Support/TrendMicro/uninstall/uninstall.sh"

if [ -f "$UNINSTALL_SH" ]; then
        "$UNINSTALL_SH"
fi

#TMUNINSTCMD="${PACKAGE_PATH}/../../Resources/TMUninstCmd.app/Contents/MacOS/TMUninstCmd"
TMUNINSTCMD="${PACKAGE_PATH}/../../Resources/TMUninstaller"
TMUNINSTPLIST="${PACKAGE_PATH}/../../Resources/TMUninstall.plist"
if [ ! -f "$TMUNINSTCMD" ]; then
	echo "$TMUNINSTCMD is not found, skip it."
fi

if [ ! -f "$TMUNINSTPLIST" ]; then
	echo "$TMUNINSTPLIST is not found, skip it."
fi

if [ ! -x "$TMUNINSTCMD" ]; then
	chmod 755 "$TMUNINSTCMD"
fi
"$TMUNINSTCMD" "$TMUNINSTPLIST"

rm -f /tmuninstaller.sh
rm -rf /Library/Receipts/com.trendmicro.uninstaller.pkg
# remove dir if empty
rmdir "/Library/Application Support/TrendMicro"
rm -rf /System/Library/TrendMicro/com.trendmicro.kext.KERedirect.sym*
rmdir /System/Library/TrendMicro

# for automation test
echo "Status=5" >> $UNINSTALL_LOG
echo "Error=0" >> $UNINSTALL_LOG
date -u "+FinishTime=%Y-%m-%dT%H:%M:%SZ" >> $UNINSTALL_LOG

exit 0
