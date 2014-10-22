#/bin/bash

if [ "$(id -u)" != "0" ]; then
  echo "This script must be run as root" 1>&2
  exit 1
fi

if [ ! -d "firmware/" ]; then
  echo "firmware not found, please use this script at the root of the source"
  exit 1 
fi

which mkcramfs > /dev/null 2>&1
if [ $? -ne 0 ]; then
  echo "Dependency bashaa not found"
  exit 1
fi

cp -fR firmware/ firmware.new/
find firmware.new/ -type f -name .gitignore -delete
chown -R root.root firmware.new/
mkcramfs firmware.new/ rootfs.img 
gzip -c rootfs.img > rootfs.img.gz
rm -f rootfs.img
md5sum rootfs.img.gz > rootfs.img.gz.md5
rm -fr firmware.new/

echo "DONE"
