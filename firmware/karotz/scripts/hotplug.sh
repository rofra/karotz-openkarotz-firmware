#!/bin/bash
# Hotplug script, automaticaly mount / umount usb key
#

# If hotplug not configured, we configure it
cat /proc/sys/kernel/hotplug | grep hotplug
if [ $? -ne 0 ]
then
	# echo /bin/hotplug.sh > /proc/sys/kernel/hotplug
	echo "Error during hotplug loading"
    exit 0
fi

HOTPLUG_FW_DIR=/karotz/firmware
echo 1 > /sys/$DEVPATH/loading
cat $HOTPLUG_FW_DIR/$FIRMWARE > /sys/$DEVPATH/data
echo 0 > /sys/$DEVPATH/loading

# If key inserted, mount it on /mnt/usbkey
if [ $ACTION = "add" ]
then
    ifconfig eth0 up
	echo $DEVPATH | grep uba1
	if [ "$?" = "0" ]
	then
		  logger -s "hotplug. Hotpluging USB device... uba1"
		  mount -t vfat /dev/uba1 /mnt/usbkey
		  logger -s "hotplug. USB Key mounted on /mnt/usbkey"
          echo -e 'password karotz_admin\n update' | nc  127.0.0.1 6600
	else                                 
		echo $DEVPATH | grep uba                         
		if [ "$?" = "0" ]
		then
			logger -s "hotplug. Hotpluging USB device... uba"
			mount -t vfat /dev/uba /mnt/usbkey
			logger -s "hotplug. USB Key mounted on /mnt/usbkey"
            echo -e 'password karotz_admin\n update' | nc  127.0.0.1 6600
            
            # # if there is a signed autorun in a usb key, let's run it
            # # the directory in which the autorun is located
            # GNUPGHOME=/karotz/etc/gpg
            # GPG="/bin/gpg -quiet --lock-never --ignore-time-conflict --homedir $GNUPGHOME"
            # if [ -x /mnt/usbkey/autorun -a -f /mnt/usbkey/autorun.sig ] ; then
            #     echo "Launching autorun if present"
            # 	$GPG --verify /mnt/usbkey/autorun.sig 2>/dev/null && /mnt/usbkey/autorun
            # fi
		fi
	fi
fi

# If key removed, umount the key
# Take care to kill every process started from the key before
# and to close the files opended !
if [ $ACTION = "remove" ]
then
	echo $DEVPATH | grep uba1
	if [ ! "$?" = "0" ]
	then
        echo -e 'password karotz_admin\n stop' | nc  127.0.0.1 6600
        logger -s "hotplug. USB Key (part1) unmounted from /mnt/usbkey uba1"
		umount /mnt/usbkey                           
		
        echo -e 'password karotz_admin\n update' | nc  127.0.0.1 6600
	else                                 
		echo $DEVPATH | grep uba
		if [ ! "$?" = "0" ]
		then
			umount /mnt/usbkey
			logger -s "hotplug. USB Key (disk) unmounted from /mnt/usbkey uba" > $output
		fi
	fi
fi
