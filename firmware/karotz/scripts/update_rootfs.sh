#!/bin/bash

logger-s "[OpenKarotz] rootfs update disabled"
exit 0 

. /karotz/scripts/update_functions.sh
. /karotz/scripts/led_functions.sh

logger -s "[UPDATE] updating rootfs."

FORCE=0
if [ $# -eq 1 ] && [ "$1" == "-f" ]; then
    FORCE=1
fi

if [ -e /karotz/etc/rootfs_version ]; then
    ROOTFS_VERSION=$(cat /karotz/etc/rootfs_version)
else
    ROOTFS_VERSION="00.01.01.00"
fi

logger -s "[UPDATE] rootfs version: $ROOTFS_VERSION"

load_version "rootfs" || { logger -s "[UPDATE] could not load version." ; exit 1 ; }

if [ -n $SERVER_ROOTFS_VERSION -a \
     -n $SERVER_ROOTFS_MAIN_URL -a \
     -n $SERVER_ROOTFS_MAIN_URL_MD5 ]
then
    check_new_version $ROOTFS_VERSION $SERVER_ROOTFS_VERSION
    ROOTFS_STATUS=$?
    [ $FORCE -eq 1 ] && ROOTFS_STATUS=0 # Forcing update

    if [ -z $ROOTFS_STATUS ]; then
        logger -s "[UPDATE] version checking error."
        exit 1
    fi

    case $ROOTFS_STATUS in
        1)
            logger -s "[UPDATE] up to date."
            exit 0
        ;;
        0)
            logger -s "[UPDATE] downloading new rootfs."
            killall madplay
            madplay /usr/karotz/res/sounds/karotz_loop2.mp3 -r &
            /usr/yaffs_stop.sh
            led_rootfs_yaffs_update_download
            cleanup
            download_rootfs

            if [ ! $? ]; then
                logger -s "[UPDATE] download failed."
                exit 1
            fi

            if [ -e $ROOTFS_FILE_PATH ]; then
                logger -s "[UPDATE] Checking integrity."
                check_integrity $ROOTFS_FILE_PATH $SERVER_ROOTFS_MAIN_URL_MD5
                ROOTFS_INTEGRITY=$?

                case $ROOTFS_INTEGRITY in
                    0)
                        logger -s "[UPDATE] installing new rootfs."
                        led_rootfs_yaffs_update_install
                        extract_rootfs_files
                        install_rootfs_files
                        cleanup

                        led_rootfs_yaffs_update_success
                        sleep 1
                        [ -e /etc/ld.so.cache ] && rm /etc/ld.so.cache

                        logger -s "[UPDATE] Reboot !"
                        reboot
                    ;;
                    1)
                        logger -s "[UPDATE] integrity error."
                        cleanup
                        exit 1
                    ;;
                    -1)
                        logger -s "[UPDATE] check integrity calling error."
                        cleanup
                        exit 1
                    ;;
                esac
            else
                # ROOTFS_FILE_PATH is missing
                logger -s "[UPDATE] download error."
                exit 1
            fi
        ;;
        2)
            # An error occured while version checking
            logger -s "[UPDATE] error while version checking."
            exit 1
        ;;
    esac
else
    # Missing variables
    logger -s "[UPDATE] error missing variables."
    exit 1
fi
