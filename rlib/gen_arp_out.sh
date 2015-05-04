#!/bin/bash
#Note, on the cluster the arp tables need to be increased in size
#ping: sendmsg: No buffer space available 
#
#To fix this, I had to increase the ARP table space. To do this permanently:
#Edit /etc/sysctl.conf and add the following lines:
#net.ipv4.neigh.default.gc_thresh3 = 4096
#net.ipv4.neigh.default.gc_thresh2 = 2048
#net.ipv4.neigh.default.gc_thresh1 = 1024
#
# sysctl -p 
#
#For a temporary fix:
#echo 1024 > /proc/sys/net/ipv4/neigh/default/gc_thresh1
#echo 2048 > /proc/sys/net/ipv4/neigh/default/gc_thresh2
#echo 4096 > /proc/sys/net/ipv4/neigh/default/gc_thresh3

/usr/bin/fping -C 1 -q -f /etc/hosts > /dev/null 2>&1

/bin/mv ~rbur004/rlib/arp.out ~rbur004/rlib/arp-prev.out
/sbin/arp -a > ~rbur004/rlib/arp.out

#Xcat itself doesn't show up in arp tables as it is the local host.
#Should change this to get Mac addresses of the local interfaces
#From ifconfig.
cat >> ~rbur004/rlib/arp.out << EOF
#compute-a1-030-ib (10.0.133.30) at A0:00:01:00:FE:80:00:00:00 [infiniband] on ib0
#compute-a1-045-p (10.0.102.45) at 5C:F3:FC:A8:3E:76 [ether] on eth2
xcat (130.216.161.5) at 00:07:43:07:B9:35 [ether] on bond0
xcat-p (10.0.101.206) at 5C:F3:FC:E2:36:3C [ether] on eth2
xcat-tsm (10.19.99.106) at 5C:F3:FC:E2:36:3E [ether] on eth3
xcat-m (172.29.102.1) at 5C:F3:FC:DA:36:3C [ether] on IMM
xcat-ib (10.0.132.206) at 80:00:00:48:FE:80:00:00 [infiniband] on ib0 
EOF

cp  ~rbur004/rlib/arp.out  ~rbur004/switchtopology/rlib/arp.out
cp  ~rbur004/rlib/arp.out  /root/bin/switchtopology/rlib/arp.out
