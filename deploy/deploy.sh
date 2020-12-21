#!/usr/bin/env bash

ANSIBLE_CONFIG=~/playground/config/ansible.cfg ANSIBLE_DEBUG=$1 ansible-playbook ~/playground/playbooks/setup-nginx-playbook.yml -i ~/playground/hosts/inventory --vault-password-file=../.vault_password