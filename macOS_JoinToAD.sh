#!/bin/bash

### You must edit these for your specific environment

# 1) fully qualified DNS name of Active Directory Domain. 
domain="domain.tld"

# 2) username of a privileged network user.
udn="account"

# 3) password of a privileged network user.
password="password"

# 4) Distinguished name of container for the computer
ou="OU=Department,OU=Macs,DC=domain,DC=tld"

# 5) 'enable' or 'disable' automatic multi-domain authentication
alldomains="enable"

### End of configuration

# Get the local computer's name.
computerid='/usr/sbin/scutil --get LocalHostName'

# Activate the AD plugin, just to be sure
defaults write /Library/Preferences/DirectoryService/DirectoryService "Active Directory" "Active"
plutil -convert xml1 /Library/Preferences/DirectoryService/DirectoryService.plist

# Bind to AD
VERSION=`/usr/libexec/PlistBuddy -c "Print :ProductVersion" "/System/Library/CoreServices/SystemVersion.plist"`
case "$VERSION" in
    10.[5-6]*)
       dsconfigad -f -a $computerid -domain $domain -u "$udn" -p "$password" -ou "$ou"
        ;;
    10.[7-9]* | 10.10* | 10.11* | 10.12* | 10.13*)
        dsconfigad -force -add $domain -computer $computerid  -username "$udn" -password "$password" -ou "$ou"
        ;;
    *)
        echo "Unsupported version of OS"
        ;;
esac

dsconfigad -alldomains $alldomains

# Add the AD node to the search path
if [ "$alldomains" = "enable" ]; then
	csp="/Active Directory/All Domains"
else
	csp="/Active Directory/$domain"
fi

dscl /Search -append / CSPSearchPath "$csp"
dscl /Search -create / SearchPolicy dsAttrTypeStandard:CSPSearchPath
dscl /Search/Contacts -append / CSPSearchPath "$csp"
dscl /Search/Contacts -create / SearchPolicy dsAttrTypeStandard:CSPSearchPath

# Restart Directory Service
killall DirectoryService
sleep 2

exit 0