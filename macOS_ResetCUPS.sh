#!/bin/bash

#This script will reset printing system

#Stop CUPS
launchctl stop org.cups.cupsd

#Backup Installed Printers Property List
if [ -e "/Library/Printers/InstalledPrinters.plist" ]
    then
    mv /Library/Printers/InstalledPrinters.plist /Library/Printers/InstalledPrinters.plist.bak
fi

#Backup the CUPS config file
if [ -e "/etc/cups/cupsd.conf" ]
    then
    mv /etc/cups/cupsd.conf /etc/cups/cupsd.conf.bak
fi

#Restore the default config by copying it
if [ ! -e "/etc/cups/cupsd.conf" ]
    then
    cp /etc/cups/cupsd.conf.default /etc/cups/cupsd.conf
fi

#Backup the printers config file
if [ -e "/etc/cups/printers.conf" ]
    then
    mv /etc/cups/printers.conf /etc/cups/printers.conf.bak
fi

#Remove all printers
lpstat -p | cut -d' ' -f2 | xargs -I{} lpadmin -x {}

#Start CUPS
launchctl start org.cups.cupsd


exit 0