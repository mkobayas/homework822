#!/bin/bash

base_dir=$(cd $(dirname $0); pwd)

#########################################
echo "oc bash completion setting"

echo "
source <(oc completion bash)" >> ~/.bashrc
source <(oc completion bash)

##########################################
echo "fetch kube config"

ansible -i $base_dir/hosts masters[0] -b -m fetch -a "src=/root/.kube/config dest=/root/.kube/config flat=yes"


