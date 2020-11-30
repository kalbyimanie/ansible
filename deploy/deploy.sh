#!/usr/bin/env bash

ANSIBLE_CONFIG=~/playground/config/ansible.cfg ANSIBLE_DEBUG=$1 ansible-playbook ~/playground/playbooks/slave1-playbook.yml -i ~/playground/hosts/inventory