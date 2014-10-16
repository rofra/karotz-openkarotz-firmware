#!/bin/bash

#----------------------------------------------------------------------------
# OPEN KAROTZ SYSTEM
# ---------------------------------------------------------------------------
. /karotz/scripts/update_functions.sh
. /karotz/scripts/led_functions.sh
. /usr/scripts/yaffs_start_functions.sh

function led_internet_ok {
    led_fixe $VIOLET
}

function led_check_update_ok {
    led_fixe $GREEN
}


# ---------------------------------------------------------------------------
# KILLALL_KAROTZ_SYSTEM
# ---------------------------------------------------------------------------
# Something failed. Let's kill the remaining parts of the system, if any.
#   return : nothing
# ---------------------------------------------------------------------------
function killall_karotz_system {
    logger -s "[START] killall karotz system."
    /bin/killall immortaldog > /dev/null
}

logger -s "[START] starting yaffs."

led_no_conf

if [ -f /etc/conf/playsounds ] ; then
        madplay /usr/karotz/res/sounds/Karotz_lumiere_bleuCiel.mp3 &
        logger -s "[START] playsounds TRUE"
    else
        logger -s "[START] playsounds FALSE"
fi
    
/usr/bin/python /usr/scripts/wait_until_connected.py

if [ $? -eq 0 ]; then
    start_dbus
    #dbus_led_internet
    led_internet_ok
    [ "$AUTO_UPDATE" = "yes" ] && check_updates
    led_check_update_ok
    /bin/killall led > /dev/null
 
# ----------------------------------------
# Open Karotz modification
# ----------------------------------------   
    #start_karotz_bricks
    #/usr/karotz/bin/immortaldog /var/run/karotz/controller.pid /usr/karotz/bin/controller
# ----------------------------------------    
    killall madplay
    if [ -f /etc/conf/playsounds ] ; then
        madplay /usr/karotz/res/sounds/karotz_allume.mp3 
        logger -s "[START] playsounds TRUE"
    else
        logger -s "[START] playsounds FALSE"
    fi
else
    logger -s "[START] karotz not connected"
fi

# ----------------------------------------
# Open Karotz modification
# ----------------------------------------
logger -s "[START] Mount usb key (if Present)"
/bin/mount /dev/uba1 /mnt/usbkey

logger -s "[START] Adjusting time"
ntpd -q -p pool.ntp.org

logger -s "[START] Starting scheduler"
/sbin/crond -c /usr/spool/cron/crontabs

logger -s "[START] OpenKarotz Daemon"
/usr/www/cgi-bin/start_ok

logger -s "[START] Restarting Inetd"
killall inetd
# ----------------------------------------
