#!/bin/bash
 
# udhcpc script edited by Tim Riker <Tim@Rikers.org>

[ -z "$1" ] && logger -s "udhcpc_script. Error: should be called from udhcpc" && exit 1

RESOLV_CONF="/etc/resolv.conf"
[ -n "$broadcast" ] && BROADCAST="broadcast $broadcast"
[ -n "$subnet" ] && NETMASK="netmask $subnet"

case "$1" in
 	deconfig)
 		/sbin/ifconfig $interface 0.0.0.0
 		;;
 	renew|bound)
 	 	/sbin/ifconfig $interface $ip $BROADCAST $NETMASK
 	 	
 	 	if [ -n "$router" ] ; then
 	 	 	logger -s "udhcpc_script. deleting routers"
 	 	 	while /sbin/route del default gw 0.0.0.0 dev $interface ; do
 	 	 	 	:
 	 	 	done
 	 	 	
 	 	 	metric=0
 	 	 	for i in $router ; do
 	 	 		/sbin/route add default gw $i dev $interface metric $((metric++))
 	 	 	done
 	 	fi
 		
 		echo -n > $RESOLV_CONF
 		[ -n "$domain" ] && echo search $domain >> $RESOLV_CONF
 		for i in $dns ; do
 			logger -s "udhcpc_script. adding dns $i"
 			echo nameserver $i >> $RESOLV_CONF
 		done
 		
 		;;
esac

exit 0 
