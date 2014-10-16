#!/bin/bash

. /karotz/scripts/led_functions.sh

TMPDIR=/tmp/update_yaffs/
YAFFS_FILE_PATH=/usr/yaffs.tar.gz
YAFFS_INSTALL_PATH=/tmp/update_yaffs/install
ROOTFS_FILE_PATH=/tmp/update_yaffs/rootfs.tar.gz

# ---------------------------------------------------------------------------
# LOAD_VERSION
# ---------------------------------------------------------------------------
# Loads file versions from Mindscape servers
#   $1     : rootfs or yaffs
#   return : 0 if ok
#            1 if wget failed
#            2 if gpg check failed
#            3 if an error occured
#   sets   : TYPE the type of update check
#            SERVER_(ROOT|YAF)FS_VERSION : the latest version number
#            SERVER_YAFFS_DEPENDENCY : if $1==yaffs, the minimal rootfs
#             version number needed by this yaffs
#            SERVER_(ROOT|YAF)FS_MAIN_URL : the url where to download the
#             latest version of the rootfs/yaffs
#            SERVER_(ROOT|YAF)FS_MAIN_URL_MD5 : the md5 of the latest
#             rootfs/yaffs
# ---------------------------------------------------------------------------
function load_version ()
{
    [ -z $1 ] && return 3
    [ $# -ne 1 ] && return 3

    if [ $1 != "rootfs" ] && [ $1 != "yaffs" ]; then
        return 3
    fi

    KAROTZ_SERVER=http://update.karotz.com/eabi
    ENCODED=$(mktemp /tmp/XXXXXXXXXX)
    GPG="gpg -quiet --lock-never --ignore-time-conflict --homedir /karotz/etc/gpg"

    # add a parameter if we have an id
    PARAMS=""
    config_get_id && [ "$RETVAL" ] && PARAMS="?id=$RETVAL"

    wget -q $KAROTZ_SERVER/$1_version$PARAMS -O $ENCODED || { rm -f $ENCODED ; return 1 ; }
    
    DECODED=$(mktemp /tmp/XXXXXXXXXX)
    $GPG --decrypt $ENCODED > $DECODED 2> /dev/null || { logger -s "update. BAD HACKER" ; rm -f $ENCODED $DECODED ; return 2 ; } 

    if [ $1 = "rootfs" ]; then
        SERVER_ROOTFS_VERSION=$(< $DECODED head -n1)
        SERVER_ROOTFS_MAIN_URL=$(< $DECODED head -n3 | tail -n1 | cut -d' ' -f1)
        SERVER_ROOTFS_MAIN_URL_MD5=$(< $DECODED head -n3 | tail -n1 | cut -d' ' -f2)
        return 0
    elif [ $1 = "yaffs" ]; then
        SERVER_YAFFS_VERSION=$(< $DECODED head -n1)
        SERVER_YAFFS_DEPENDENCY=$(< $DECODED head -n2 | tail -n1)
        SERVER_YAFFS_MAIN_URL=$(< $DECODED head -n3 | tail -n1 | cut -d' ' -f1)
        SERVER_YAFFS_MAIN_URL_MD5=$(< $DECODED head -n3 | tail -n1 | cut -d' ' -f2)
        return 0
    else
        return 3
    fi
    rm -f $ENCODED $DECODED
}

# ---------------------------------------------------------------------------
# CHECK_NEW_VERSION
# ---------------------------------------------------------------------------
# Checks if a new version exists on Mindscape server
#   $1     : karotz_version (ex: 10.05.20.00)
#   $2     : server_version (ex: 10.07.15.24)
#   return : 0  if karotz is out of date
#            1  if karotz is up to date
#            2  if an error occured
# ---------------------------------------------------------------------------
function check_new_version {
    [ "$1" -a "$2" ] || return 2

    [[ "$1" =~ ^([0-9]{2}.){3}[0-9]{2}$ ]] || return 2
    [[ "$2" =~ ^([0-9]{2}.){3}[0-9]{2}$ ]] || return 2

    CURRENT_VERSION=${1//.}
    LATEST_VERSION=${2//.}

    [ $CURRENT_VERSION -lt $LATEST_VERSION ]
}

# ---------------------------------------------------------------------------
# DOWNLOAD_YAFFS
# ---------------------------------------------------------------------------
# Downloads yaffs archive (karotz system) from Mindscape server
#   return : 0  if the file has been correctly downloaded
#            1  if an error occured
# ---------------------------------------------------------------------------
function download_yaffs {
    [ -e $TMPDIR ] && rm -rf $TMPDIR
    mkdir -p $TMPDIR
    [ -e $YAFFS_FILE_PATH ] && rm $YAFFS_FILE_PATH
    wget -q $SERVER_YAFFS_MAIN_URL -O $YAFFS_FILE_PATH || return 1
    return 0
}

# ---------------------------------------------------------------------------
# DOWNLOAD_ROOTFS
# ---------------------------------------------------------------------------
# Downloads rootfs archive (linux system) from Mindscape server
#   return : 0  if the file has been correctly downloaded
#            1  if an error occured
# ---------------------------------------------------------------------------
function download_rootfs {
    [ -e $TMPDIR ] && rm -rf $TMPDIR
    mkdir -p $TMPDIR
    [ -e $ROOTFS_FILE_PATH ] && rm $ROOTFS_FILE_PATH
    wget -q $SERVER_ROOTFS_MAIN_URL -O $ROOTFS_FILE_PATH || return 1 
    return 0
}

# ---------------------------------------------------------------------------
# EXTRACT_SYS_FILES
# ---------------------------------------------------------------------------
# Extracts Yaffs files into temporary folder
#   return : none
# ---------------------------------------------------------------------------
function extract_sys_files {
	gzip -d < $YAFFS_FILE_PATH | tar xf - -C /usr/
}

# ---------------------------------------------------------------------------
# EXTRACT_INSTALL_FILES
# ---------------------------------------------------------------------------
# Extracts Yaffs install files into temporary folder
#   return : none
# ---------------------------------------------------------------------------
function extract_install_files {
    gzip -d < $YAFFS_FILE_PATH | tar xf - ./install -C $TMPDIR
}

# ---------------------------------------------------------------------------
# EXTRACT_ROOTFS_FILES
# ---------------------------------------------------------------------------
# Extracts Rootfs install files (rootfs image and kernel) into
# temporary folder 
#   return : none
# ---------------------------------------------------------------------------
function extract_rootfs_files {
	gzip -d < "$ROOTFS_FILE_PATH" | tar xf - -C "$TMPDIR"
}

# ---------------------------------------------------------------------------
# INSTALL_ROOTFS_FILES
# ---------------------------------------------------------------------------
# Installs Rootfs install files (rootfs image and kernel)
#   return : none
# ---------------------------------------------------------------------------
function install_rootfs_files {
    
    [ -f "$TMPDIR/zImage" -a -f "$TMPDIR/rootfs.img.gz" ] || return 0
   
    # zImage
    logger -s "[ROOTFS INSTALL] flash erasing /dev/mtd1"
    /sbin/flash_eraseall /dev/mtd1 
    logger -s "[ROOTFS INSTALL] writing new zImage"
    /sbin/nandwrite -pm /dev/mtd1 "$TMPDIR/zImage"
    
    # rootfs
    logger -s "[ROOTFS INSTALL] flash erasing /dev/mtd2"
    /sbin/flash_eraseall /dev/mtd2
    logger -s "[ROOTFS INSTALL] writing new rootfs"
    /sbin/nandwrite -pm /dev/mtd2 "$TMPDIR/rootfs.img.gz"
}


# ---------------------------------------------------------------------------
# CHECK_INTEGRITY
# ---------------------------------------------------------------------------
# Checks file integrity with md5 hashes
#   $1     : file_path
#   $2     : md5 checksum
#   return : 0  if integrity is good
#            1  if integrity is not good
#            2  if an error occured
# ---------------------------------------------------------------------------
function check_integrity () {
    [ $# != 2 ] && return 2
    [ ! -e $1 ] && return 2

    if [ -z $1 ] || [ -z $2 ]; then
        return 2
    fi

    MD5=$(echo $(md5sum $1) | cut -d ' ' -f1)
    if [ $MD5 = $2 ]; then
        return 0
    else
        return 1
    fi
}

# ---------------
# CHECK_FILE
# ---------------
function check_file () {
    # test archive structure, ...

	FILELIST=$TMPDIR/yaffs_update_filelist
    # TODO
	echo "TODO check the structure of the archive"

	[ -f "$TMPDIR/karotz_sys/sys_version" ] || die "no sys_version file"
	[ \! -z "$(awk 'NR == 1 && \$0 == $VERSION { print $0 }' $TMPDIR/karotz_sys/sys_version)" ] || die "bad version number"

    # check is fits our yaffs update structure
    # need : rep YAFFS, and files version, post_install script. some crypting stuff to verify integrity ?
    # need : no files erasing protected ones
}

# ---------------------------------------------------------------------------
# RUN_PRE_INSTALL_INSTALL
# ---------------------------------------------------------------------------
# Runs pre-installation script
#   return : 0  if pre_install script has terminated with success
#            1  if an error occured
# ---------------------------------------------------------------------------
function run_pre_install () {
	[ -x $YAFFS_INSTALL_PATH/pre_install.sh ] || return 1
	$YAFFS_INSTALL_PATH/pre_install.sh || return 1
    return 0
}

# ---------------------------------------------------------------------------
# RUN_POST_INSTALL_INSTALL
# ---------------------------------------------------------------------------
# Runs post-installation script
#   return : 0  if post_install script has terminated with success
#            1  if an error occured
# ---------------------------------------------------------------------------
function run_post_install {
	[ -x $YAFFS_INSTALL_PATH/post_install.sh ] || return 1
	$YAFFS_INSTALL_PATH/post_install.sh || return 0
    return 0
}


# ---------------------------------------------------------------------------
# CLEANUP_YAFFS
# ---------------------------------------------------------------------------
# Cleans every files in the yaffs before an update
#   return : 0  if cleanup script has terminated with success
#            1  if an error occured
# ---------------------------------------------------------------------------
function cleanup_yaffs {
    find /usr \
        | grep -v "^/usr/yaffs_restart.sh$" \
        | grep -v "^/usr/yaffs_start.sh$" \
        | grep -v "^/usr/yaffs_stop.sh$" \
        | grep -v "^/usr/.install_yaffs_start$" \
        | grep -v "^/usr/karotz/apps" \
        | grep -v "^/usr/karotz/messages" \
        | grep -v "^/usr/etc$" \
        | grep -v "^/usr/etc/conf" \
        | grep -v "^/usr$" \
        | grep -v "^/usr/yaffs.tar.gz$" \
        | grep -v "^/usr/lost+found$" \
        | xargs rm -rf {}

    [ ! -e /usr/etc/conf ] && mkdir -p /usr/etc/conf
    [ ! -e /usr/etc/conf/sys_version ] && touch /usr/etc/conf/sys_version
    echo "00.01.01.00" > /usr/etc/conf/sys_version
    
    return 0
}

# ---------------------------------------------------------------------------
# YAFFS_RESTAURATION
# ---------------------------------------------------------------------------
# Erase yaffs partition and goes to the factory state
#   return : 0  if restauration script has terminated with success
#            1  if an error occured
# ---------------------------------------------------------------------------
function restauration_yaffs {

    led_restauration_yaffs
    logger -s "[RESTORATION] YAFFS (/dev/mtd6) partition will be restored to factory configuration."

    # erase and remount /usr
    /bin/umount -f /usr
    /sbin/flash_eraseall -q /dev/mtd6 || return 1
    /bin/mount -t yaffs /dev/mtdblock6 /usr || return 1
    
    logger -s "[RESTORATION] dumping yaffs rescue system"

    # get yaffs_rescue
    /sbin/nanddump -nbo -f /tmp/yaffs_rescue /dev/mtd5 || return 1

    logger -s "[RESTORATION] writing from factory partition"

    # write it
    touch /usr/.install_yaffs_start
    /sbin/yaffs_rescue_decode /tmp/yaffs_rescue - | gzip -d -c | tar x -C /usr/ || return 1
    touch /usr/.install_yaffs_stop
    # clean
    rm /tmp/yaffs_rescue || return 1

    logger -s "[RESTORATION] done"

    return 0
}

# ---------------------------------------------------------------------------
# CLEANUP
# ---------------------------------------------------------------------------
# Cleans temporary and installation files
#   return : 0  if cleanup script has terminated with success
#            1  if an error occured
# ---------------------------------------------------------------------------
function cleanup {
    [ -e $TMPDIR ] && rm -rf $TMPDIR || return 1
    [ -e $YAFFS_FILE_PATH ] && rm -r $YAFFS_FILE_PATH || return 1
    [ -e /usr/install ] && rm -rf /usr/install || return 1
    return 0
}



# ---------------------------------------------------------------------------
# IS_CONFIGURED
# ---------------------------------------------------------------------------
# Checks if the system has been configured or not
#   return : 0  if there is a config
#            1  if not
# ---------------------------------------------------------------------------
function is_configured {
    [ -f /etc/conf/voos.conf -a -f /etc/conf/network.conf ]
}

# ---------------------------------------------------------------------------
# CONFIG_GET_ID
# ---------------------------------------------------------------------------
# Reads the voos config if it exists. If so, sets RETVAL variable to the id.
#   return : 0  if there is a config and an id
#            1  if not
# ---------------------------------------------------------------------------
function config_get_id {
    [ -f /etc/conf/voos.conf ] || return 1
    RETVAL="$(grep '^id=' /etc/conf/voos.conf | cut -d'=' -f2)"
    [ -z "$RETVAL" ] && return 1
    return 0
}
