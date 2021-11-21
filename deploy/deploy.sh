#!/usr/bin/env bash

ANSIBLE_CONFIG=~/playground/config/ansible.cfg ansible-playbook ~/playground/playbooks/$1.yml -i ~/playground/hosts/inventory --extra-vars "new_group_name=de user_config_file=user_config.yml host_deployment=local user_name=adib retry=1" --vault-password-file=~/playground/.vault_password --tags $2