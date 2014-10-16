import os
RED="FF0000"
GREEN="00FF00"
BLUE="0000FF"
VIOLET="660099"
CYAN="00FFFF"
YELLOW="FFFF00"
PINK="FFC0CB"
ORANGE="FFA500"

# ---------------------------------------------------------------------------
# LED_FIXE
# ---------------------------------------------------------------------------
# Sets the color of the led
#   args : the color, in hexadecimal form (ex: FF0000 for red) we want for
#          the led
#   return : nothing
# ---------------------------------------------------------------------------
def led_fixe (color):
    os.system("/bin/killall led > /dev/null")
    os.system("/karotz/bin/led -l " + color)		

# ---------------------------------------------------------------------------
# LED_PULSE
# ---------------------------------------------------------------------------
# Make the led pulse.
#   args : the color, in hexadecimal form (ex: FF0000 for red) we want to 
#          pulse in
#   return : nothing
# ---------------------------------------------------------------------------
def led_pulse(color):
    os.system("/bin/killall led > /dev/null")
    os.system("/karotz/bin/led -l " + color + " -p 000000 -d 700 &")


# ---------------------------------------------------------------------------
# LED_PULSE_FAST
# ---------------------------------------------------------------------------
# Make the led pulse fast.
#   args : the color, in hexadecimal form (ex: FF0000 for red) we want to 
#          pulse in
#   return : nothing
# ---------------------------------------------------------------------------
def led_pulse_fast(color):
    os.system("/bin/killall led > /dev/null")
    os.system("/karotz/bin/led -l " + color + " -p 000000 -d 300 &")


# ---------------------------------------------------------------------------
# DBUS_LED_PULSE
# ---------------------------------------------------------------------------
# Make the led pulse.
#   args : the color, in hexadecimal form (ex: FF0000 for red) we want to 
#          pulse in
#   return : nothing
# ---------------------------------------------------------------------------
def dbus_led_pulse(color):
    os.system("/bin/killall led > /dev/null")
    os.system("dbus-send --system --dest=com.mindscape.karotz.Led                                  \
                /com/mindscape/karotz/Led com.mindscape.karotz.KarotzInterface.pulse    \
                string:\"1\" string:\"" + color + "\" string:\"000000\" int32:500 int32:-1")


# ---------------------------------------------------------------------------
# DBUS_LED_PULSE_FIXED
# ---------------------------------------------------------------------------
# Sets the color of the led
#   args : the color, in hexadecimal form (ex: FF0000 for red) we want to 
#          pulse in
#   return : nothing
# ---------------------------------------------------------------------------
def dbus_led_fixed(color):
    os.system("/bin/killall led > /dev/null")
    os.system("dbus-send --system --dest=com.mindscape.karotz.Led                                  \
                /com/mindscape/karotz/Led com.mindscape.karotz.KarotzInterface.light    \
                string:\"$UUID\" string:\"" + color + "\"" )


# ---------------------------------------------------------------------------
# FUNCTIONS BASED ON THE LED BINARY (FOR FACTORY SYSTEMS)
# ---------------------------------------------------------------------------

def led_restauration_yaffs():
    led_pulse(YELLOW)


def led_no_conf():
    led_fixe(CYAN)

def led_end_of_boot():
    led_pulse(CYAN)


def led_internet():
    led_pulse(VIOLET)


def led_update_problem():
    led_fixe(PINK)


def led_rootfs_yaffs_update_download():
    led_pulse(ORANGE)


def led_rootfs_yaffs_update_install():
    led_pulse_fast(ORANGE)


def led_rootfs_yaffs_update_success():
    led_fixe(GREEN)


# ---------------------------------------------------------------------------
# FUNCTIONS BASED ON THE D-BUS METHODS (FOR ADVANCED/UPDATED SYSTEMS)
# ---------------------------------------------------------------------------

def dbus_led_end_of_boot():
    dbus_led_pulse(CYAN)


def dbus_led_internet():
    dbus_led_pulse(VIOLET)

