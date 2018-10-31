#!/bin/bash
if [ `arch` = 'ppc' -o `arch` = 'ppc64' ]; then
    PartitionType=APMFormat
else
    PartitionType=GPTFormat
fi
 
sysVolType="Unknown"
 
if ( diskutil cs list | grep "No CoreStorage" > /dev/null )
then
    sysVolType="HFS"              # Normal Mac file storage
else
    if [ -e "/usr/bin/fdesetup" ]; then
        FullDiskEncrypt=`/usr/bin/fdesetup status`
    fi
    if [[ -n "$FullDiskEncrypt"  &&  "$FullDiskEncrypt" = "FileVault is On." ]]; then
        sysVolType="FV"            # FileVault
    else
        sysVolType="CS"           # CoreStorage Fusion device
    fi
fi
echo "sysVolType is $sysVolType"
 
if [ $sysVolType = "HFS" ]; then # This is the normal case for Macs with traditional HDD or SSD.
 
    /usr/sbin/diskutil partitionDisk disk0 $PartitionType "Journaled HFS+" "$KACE_SYSTEM_DRIVE_NAME" "100%"
    exit $?
 
elif [ $sysVolType = "CS" ]; then # This is the case for Macs with Fusion devices.
 
#    Handling of Apple_CoreStorage devices uses undocumented diskutil command verbs.
#    See http://blog.fosketts.net/2011/08/05/undocumented-corestorage-commands/
#    To disable this, comment out the sysVolType="CS" assignment near the top of this script.
 
    echo "This Mac has Apple_CoreStorage - may be a Fusion device"
    FusionLV=`diskutil cs list | grep "Logical Volume" | tail -n 1 | awk '{print $NF}'`
    diskutil cs resizeStack $FusionLV 0B 2> /dev/null
    exit 0
 
fi
 
exit 1