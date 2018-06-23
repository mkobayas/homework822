#!/bin/bash

if [ -f /etc/rhsm/rhsm.conf.rpmnew ]; then
  cat /etc/rhsm/rhsm.conf.rpmnew > /etc/rhsm/rhsm.conf
fi

if [ -f /etc/yum.repos.d/open.repo ]; then
  rm -f /etc/yum.repos.d/open.repo
fi

subscription-manager register --username=$1 --password=$2

subscription-manager refresh

subscription-manager attach --pool=$3

subscription-manager repos --disable="*"

subscription-manager repos \
    --enable="rhel-7-server-rpms" \
    --enable="rhel-7-server-extras-rpms" \
    --enable="rhel-7-server-ose-3.9-rpms" \
    --enable="rhel-7-fast-datapath-rpms" \
    --enable="rhel-7-server-ansible-2.4-rpms"

yum clean all
yum -y update

yum install -y wget git net-tools bind-utils iptables-services bridge-utils bash-completion kexec-tools sos psacct vim NetworkManager atomic-openshift-utils
yum -y update

echo "====== FINISH $HOSTNAME ====="

