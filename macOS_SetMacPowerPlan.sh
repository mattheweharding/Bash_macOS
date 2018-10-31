###
#!/bin/sh
# set power management preferences
# set scheduled events for startup and shutdown

# settings for desktops
setDesktopPrefs(){
pmset -a sleep 0 2>/dev/null # system does not go to sleep automatically
pmset -a powerbutton 0 2>/dev/null # do not allow power button to sleep the computer
pmset -a displaysleep 60 2>/dev/null # sets display sleep time
pmset -a disksleep 0 2>/dev/null # does not spindown hard drives
pmset -a womp 1 2>/dev/null # wake up computer if it receives wake-on-lan magic packet

# set scheduled startup and shutdown
pmset repeat cancel # clear all repeating startup and shutdown events
sleep 1
pmset repeat wakeorpoweron MTWRFSU 20:00:00
sleep 1
}

# settings for laptops
setLaptopPrefs(){
pmset -a sleep 0 2>/dev/null # system does not go to sleep automatically
pmset -a powerbutton 0 2>/dev/null # do not allow power button to sleep the computer
pmset -a displaysleep 30 2>/dev/null # sets display sleep time
pmset -a disksleep 0 2>/dev/null # does not spindown hard drives
pmset -a womp 1 2>/dev/null # wake up computer if it receives wake-on-lan magic packet
pmset -a lidwake 1 2>/dev/null # wake up computer when lid is opened
pmset -a acwake 0 2>/dev/null # do not wake up computer when power adapter is connected
pmset -a halfdim 1 2>/dev/null # sets display to halfdim before display sleep
pmset -a sms 1 2>/dev/null # use Sudden Motion Sensor to park disk heads on sudden changes in G force

# set prefs when using battery only
pmset -b sleep 20 2>/dev/null # system goes to sleep after idle time
pmset -b displaysleep 15 2>/dev/null # sets display sleep time
pmset -b disksleep 10 2>/dev/null # spindown hard drives

# set scheduled startup and shutdown
pmset repeat cancel # clear all repeating startup and shutdown events
sleep 1
pmset repeat wakeorpoweron MTWRFSU 21:00:00
sleep 1
}

checkIfLaptop=$(sysctl -n hw.model | grep -i -c book 2>/dev/null)
if [ $checkIfLaptop -gt 0 ]; then
    echo "Setting power management for laptop..."
    setLaptopPrefs
else
    echo "Setting power management for desktop..."
    setDesktopPrefs
fi
pmset -g
echo
pmset -g sched
sleep 1
exit 0
###