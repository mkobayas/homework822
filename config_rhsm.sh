#!/bin/bash

base_dir=$(cd $(dirname $0); pwd)

mkdir -p $base_dir/log

for node in oselab.example.com \
            loadbalancer1.example.com \
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
            node6.example.com
do
    echo "===== config $node ===="
    scp $base_dir/config_rhsm_work.sh $node:/root/config_rhsm_work.sh
    ssh -o StrictHostKeyChecking=no $node chmod +x /root/config_rhsm_work.sh
    ssh -o StrictHostKeyChecking=no $node "/root/config_rhsm_work.sh $1 $2 $3" &> $base_dir/log/$node.log &
done

tail -f $base_dir/log/*
