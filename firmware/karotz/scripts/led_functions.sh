#!/bin/bash

RED=FF0000
GREEN=00FF00
BLUE=0000FF
VIOLET=660099
CYAN=00FFFF
YELLOW=FFFF00
PINK=FFC0CB
ORANGE=FFA500

# ---------------------------------------------------------------------------
# LED_FIXE
# ---------------------------------------------------------------------------
# Sets the color of the led
#   args : the color, in hexadecimal form (ex: FF0000 for red) we want for
#          the led
#   return : nothing
# ---------------------------------------------------------------------------
function led_fixe {
    /bin/killall led > /dev/null
    /karotz/bin/led -l $1		
}

# ---------------------------------------------------------------------------
# LED_PULSE
# ---------------------------------------------------------------------------
# Make the led pulse.
#   args : the color, in hexadecimal form (ex: FF0000 for red) we want to 
#          pulse in
#   return : nothing
# ---------------------------------------------------------------------------
function led_pulse {
    /bin/killall led > /dev/null
    /karotz/bin/led -l $1 -p 000000 -d 700 &
}

# ---------------------------------------------------------------------------
# LED_PULSE_FAST
# ---------------------------------------------------------------------------
# Make the led pulse fast.
#   args : the color, in hexadecimal form (ex: FF0000 for red) we want to 
#          pulse in
#   return : nothing
# ---------------------------------------------------------------------------
function led_pulse_fast {
    /bin/killall led > /dev/null
    /karotz/bin/led -l $1 -p 000000 -d 300 &
}

# ---------------------------------------------------------------------------
# DBUS_LED_PULSE
# ---------------------------------------------------------------------------
# Make the led pulse.
#   args : the color, in hexadecimal form (ex: FF0000 for red) we want to 
#          pulse in
#   return : nothing
# ---------------------------------------------------------------------------
function dbus_led_pulse {
    /bin/killall led > /dev/null
    UUID=`cat /proc/sys/kernel/random/uuid`
    dbus-send --system --dest=com.mindscape.karotz.Led                                  \
                /com/mindscape/karotz/Led com.mindscape.karotz.KarotzInterface.pulse    \
                string:"$UUID" string:"$1" string:"000000" int32:500 int32:-1
}

# ---------------------------------------------------------------------------
# DBUS_LED_PULSE_FIXED
# ---------------------------------------------------------------------------
# Sets the color of the led
#   args : the color, in hexadecimal form (ex: FF0000 for red) we want to 
#          pulse in
#   return : nothing
# ---------------------------------------------------------------------------
function dbus_led_fixed {
    /bin/killall led > /dev/null
    UUID=`cat /proc/sys/kernel/random/uuid`
    dbus-send --system --dest=com.mindscape.karotz.Led                                  \
                /com/mindscape/karotz/Led com.mindscape.karotz.KarotzInterface.light    \
                string:"$UUID" string:"$1"
}


# ---------------------------------------------------------------------------
# FUNCTIONS BASED ON THE LED BINARY (FOR FACTORY SYSTEMS)
# ---------------------------------------------------------------------------

function led_restauration_yaffs {
    led_pulse $YELLOW
}

function led_no_conf {
    led_fixe $CYAN
}

function led_end_of_boot {
    led_pulse $CYAN
}

function led_internet {
    led_pulse $VIOLET
}

function led_update_problem {
    led_fixe $PINK
}

function led_rootfs_yaffs_update_download {
    led_pulse $ORANGE
}

function led_rootfs_yaffs_update_install {
    led_pulse_fast $ORANGE
}

function led_rootfs_yaffs_update_success {
    led_fixe $GREEN
}

# ---------------------------------------------------------------------------
# FUNCTIONS BASED ON THE D-BUS METHODS (FOR ADVANCED/UPDATED SYSTEMS)
# ---------------------------------------------------------------------------

function dbus_led_end_of_boot {
    dbus_led_pulse $CYAN
}

function dbus_led_internet {
    dbus_led_pulse $VIOLET
}
