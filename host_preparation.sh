#!/bin/bash

if [ $# -ne 3 ]; then
  echo "host_preparation.sh <username> <password> <pool>"
  exit 1
fi

base_dir=$(cd $(dirname $0); pwd)
mkdir -p $base_dir/log

########################################
# host list
########################################

bastion=oselab.example.com

nodes=(loadbalancer1.example.com \
       master1.example.com \
       master2.example.com \
       master3.example.com \
       infranode1.example.com \
       infranode2.example.com \
       infranode3.example.com \
       node1.example.com \
       node2.example.com \
       node3.example.com \
       node4.example.com \
       node5.example.com \
       node6.example.com)

echo "Host Preparation ${nodes[@]}"


#######################################################
# Configure and install package for OCP cluster hosts
#######################################################

echo "Host Preparation ${nodes[@]}"
pids=()
for node in ${nodes[@]} 
do
   echo "===== config $node ===="
   scp $base_dir/host_preparation_work.sh $node:/root/host_preparation_work.sh
   ssh -o StrictHostKeyChecking=no $node chmod +x /root/host_preparation_work.sh
   ssh -o StrictHostKeyChecking=no $node "/root/host_preparation_work.sh $1 $2 $3" &> $base_dir/log/$node.log &
   pids+=($!)
done


######################################################
# Configure bastion
######################################################

$base_dir/bastion_preparation_.sh $1 $2 $3
$base_dir/lb_dns.sh

######################################################
# wait host_preparation_work
######################################################
echo "wait host_preparation_work"
for pid in ${pids[@]}; do
  wait $pid
done

tail -n 2  $base_dir/log/*
