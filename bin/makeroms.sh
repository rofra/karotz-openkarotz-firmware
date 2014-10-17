#/bin/basho

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
  echo "Dependency mkcramfs not found"
  exit 1
fi

cp -fR firmware/ firmware.new/
mkcramfs -p firmware.new/ rootfs.img
gzip  -c rootfs.img > rootfs.img.img.gz
rm -f rootfs.img
rm -fr firmware.new/

echo "DONE"
