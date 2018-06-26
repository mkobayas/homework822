#!/bin/bash

base_dir=$(cd $(dirname $0); pwd)

ansible-playbook -f 20 -i $base_dir/hosts /usr/share/ansible/openshift-ansible/playbooks/prerequisites.yml

ansible-playbook -f 20 -i $base_dir/hosts /usr/share/ansible/openshift-ansible/playbooks/deploy_cluster.yml
