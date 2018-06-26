#!/bin/bash

echo "disable httpd"
systemctl stop httpd.service
systemctl disable httpd.service

echo "install package"
yum -y bind bind-utils haproxy

echo "variables"
guid=`hostname|cut -f2 -d-|cut -f1 -d.`
infraIP1=`host infranode1-$guid.oslab.opentlc.com 8.8.8.8  | grep $guid | awk '{ print $4 }'`
infraIP2=`host infranode2-$guid.oslab.opentlc.com 8.8.8.8  | grep $guid | awk '{ print $4 }'`
lbIP=`host oselab-$guid.oslab.opentlc.com 8.8.8.8  | grep $guid | awk '{ print $4 }'`
domain="cloudapps-$guid.oslab.opentlc.com"

echo "\$guid $guid"
echo "\$infraIP1 $infraIP1"
echo "\$infraIP2 $infraIP2"
echo "\$lbIP $lbIP"
echo "\$domain $domain"

echo "#############################"
echo "# HAProxy(LB for Routers)"
echo "#############################"

echo "create haproxy file"
echo "global
    log         127.0.0.1 local2
    chroot      /var/lib/haproxy
    pidfile     /var/run/haproxy.pid
    maxconn     4000
    user        haproxy
    group       haproxy
    daemon
    stats socket /var/lib/haproxy/stats

defaults
    mode                    http
    log                     global
    option                  httplog
    option                  dontlognull
    option http-server-close
    option forwardfor       except 127.0.0.0/8
    option                  redispatch
    retries                 3
    timeout http-request    10s
    timeout queue           1m
    timeout connect         10s
    timeout client          1m
    timeout server          1m
    timeout http-keep-alive 10s
    timeout check           10s
    maxconn                 3000

frontend  http_front *:80
    default_backend             http_app

frontend  https_front *:443
    default_backend             https_app
    
backend http_app
    balance     source
    server  infranode1 $infraIP1:80 check
    server  infranode2 $infraIP2:80 check

backend https_app
    balance     source
    server  infranode1 $infraIP1:443 check
    server  infranode2 $infraIP2:443 check" > /etc/haproxy/haproxy.cfg

cat /etc/haproxy/haproxy.cfg

echo "set iptables for haproxy"
iptables -I INPUT -p tcp --dport 80 -j ACCEPT
iptables -I INPUT -p tcp --dport 443 -j ACCEPT
iptables-save > /etc/sysconfig/iptables

echo "start haproxy"
systemctl enable haproxy.service
systemctl start haproxy.service

echo "#################################"
echo "# DNS (for wildcard sub domain)"
echo "#################################"

echo "create DNS zone file"

mkdir -p /var/named/zones
echo "\$ORIGIN  .
\$TTL 1  ;  1 seconds (for testing only)
${domain} IN SOA master.${domain}.  root.${domain}.  (
  2011112904  ;  serial
  60  ;  refresh (1 minute)
  15  ;  retry (15 seconds)
  1800  ;  expire (30 minutes)
  10  ; minimum (10 seconds)
)
  NS master.${domain}.
\$ORIGIN ${domain}.
test A ${lbIP}
* A ${lbIP}"  >  /var/named/zones/${domain}.db

chgrp named -R /var/named
chown named -R /var/named/zones
restorecon -R /var/named

echo "create named.con file"

echo "options {
  listen-on port 53 { any; };
  directory \"/var/named\";
  dump-file \"/var/named/data/cache_dump.db\";
  statistics-file \"/var/named/data/named_stats.txt\";
  memstatistics-file \"/var/named/data/named_mem_stats.txt\";
  allow-query { any; };
  recursion yes;
  /* Path to ISC DLV key */
  bindkeys-file \"/etc/named.iscdlv.key\";
};
logging {
  channel default_debug {
    file \"data/named.run\";
    severity dynamic;
  };
};
zone \"${domain}\" IN {
  type master;
  file \"zones/${domain}.db\";
  allow-update { key ${domain} ; } ;
};" > /etc/named.conf

chown root:named /etc/named.conf
restorecon /etc/named.conf

echo "set iptables for haproxy"
iptables -I INPUT 1 -p tcp --dport 53 -s 0.0.0.0/0 -j ACCEPT ;
iptables -I INPUT 1 -p udp --dport 53 -s 0.0.0.0/0 -j ACCEPT ;
iptables-save > /etc/sysconfig/iptables

echo "start DNS"
systemctl enable named
systemctl start named


