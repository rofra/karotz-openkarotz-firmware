#!/bin/bash

. /karotz/scripts/update_functions.sh
. /karotz/scripts/led_functions.sh

logger -s "[UPDATE] updating yaffs."

FORCE=0
if [ $# -eq 1 ] && [ "$1" == "-f" ]; then
    FORCE=1
fi

if [ -e /etc/conf/sys_version ]; then
    YAFFS_VERSION=$(cat /etc/conf/sys_version)
else
    YAFFS_VERSION="00.01.01.00"
fi

logger -s "[UPDATE] sys version: $YAFFS_VERSION."

if [ -e /etc/conf/rootfs_version ]; then
    ROOTFS_VERSION=$(cat /etc/conf/rootfs_version)
else
    ROOTFS_VERSION="00.01.01.00"
fi

logger -s "[UPDATE] rootfs version: $ROOTFS_VERSION."

load_version "yaffs" || { logger -s "[UPDATE] could not load yaffs version." ; exit 1 ; }

if [ -n $SERVER_YAFFS_VERSION -a \
     -n $SERVER_YAFFS_DEPENDENCY -a \
     -n $SERVER_YAFFS_MAIN_URL -a \
     -n $SERVER_YAFFS_MAIN_URL_MD5 ]
then
    check_new_version $YAFFS_VERSION $SERVER_YAFFS_VERSION
    YAFFS_STATUS=$?
    [ $FORCE -eq 1 ] && YAFFS_STATUS=0 # Forcing update
    check_new_version $ROOTFS_VERSION $SERVER_YAFFS_DEPENDENCY
    ROOTFS_STATUS=$?

    if [ -z $YAFFS_STATUS ] || [ -z $ROOTFS_STATUS ]; then
		logger -s "[UPDATE] version checking error."
        exit 1
    fi

    if [[ $ROOTFS_STATUS -eq 0 || $ROOTFS_STATUS -eq 2 ]]; then
		logger -s "[UPDATE] rootfs dependency error."
        exit 1;
    fi

    case $YAFFS_STATUS in
        1)
            logger -s "[UPDATE] up to date."
            exit 0
        ;;
        0)
            logger -s "[UPDATE] downloading."
            killall madplay
            cp /usr/karotz/res/sounds/karotz_loop2.mp3 /tmp/karotz_loop2.mp3
            mplayer -afm libmad -loop 10  /tmp/karotz_loop2.mp3 & 
            /usr/yaffs_stop.sh
            led_rootfs_yaffs_update_download
            download_yaffs
            if [ ! $? ]; then
                logger -s "[UPDATE] downloading failed."
                exit 1
            fi

            if [ -e $YAFFS_FILE_PATH ]; then
                logger -s "[UPDATE] checking integrity."
                check_integrity $YAFFS_FILE_PATH $SERVER_YAFFS_MAIN_URL_MD5
                YAFFS_INTEGRITY=$?

                case $YAFFS_INTEGRITY in
                    0)
                        if [[ ! -e /usr/yaffs_start.sh || ! -e /usr/yaffs_stop.sh ]]; then
                            logger -s "[UPDATE] corrupted system."
                            restauration_yaffs
                            reboot
                            exit 1
                        else
                            /usr/yaffs_stop.sh
                        fi

                        touch /usr/.install_yaffs_start
                        
                        led_rootfs_yaffs_update_install

						logger -s "[UPDATE] cleanup_yaffs."
                        cleanup_yaffs

						logger -s "[UPDATE] extract."
                        extract_install_files
                        
						logger -s "[UPDATE] pre_install."
                        run_pre_install
                        
						logger -s "[UPDATE] extract_sys."
                        extract_sys_files
                        
                        [ -e /etc/ld.so.cache ] && rm /etc/ld.so.cache
						
                        logger -s "[UPDATE] post_install."
                        run_post_install
                       
                        touch /usr/.install_yaffs_stop
                        
						logger -s "[UPDATE] cleanup."
                        cleanup

                        led_rootfs_yaffs_update_success
                        sleep 1
                        
                        logger -s "[UPDATE] Reboot !"
                        reboot
                    ;;
                    1)
						logger -s "[UPDATE] integrity error."
                        cleanup
                        exit 1
                    ;;
                    2)
						logger -s "[UPDATE] check integrity calling error."
                        cleanup
                        exit 1
                    ;;
                esac
            else
                # YAFFS_FILE_PATH is missing
				logger -s "[UPDATE] dowload failed."
                exit 1
            fi
        ;;
        2)
            # An error occured while version checking
            logger -s "[UPDATE] error."
            exit 1
        ;;
    esac
else
    # Missing variables
    logger -s "[UPDATE] error (missing variables)."
    exit 1
fi
