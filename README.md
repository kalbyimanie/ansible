# Learning ansible with ansible-playbook
This repository is meant to be a playground to learn ansible or ansible-playbook.

## Quick Setup (Recommended)

Use the Makefile for automated setup:

```bash
make setup
```

This will automatically:
- Generate SSH keys
- Create vault password file (interactive)
- Create vault file (interactive)
- Build and start Docker containers

Then access the ansible-server container:
```bash
make shell
```

## Manual Setup

If you prefer manual setup or want to understand each step:

__Setup the environment as docker containers :__<br>

- Go to directory _ansible-init_
- Create new directory named _ssh_keys_ under directory _ansible-init_
- Generate new ssh key :<br>
```$: ssh-keygen -t rsa -f playground```
- Create _.vault_password_ file under the root directory and enter your arbitrary password for later decryption use<br>(the file will be ignored by git—it has been listed in _.gitignore_ file)</br>
- Create new ansible vault file named _vault.yml_ under the root directory : <br>
```$: ansible-vault create vault.yml```<br>
then fill in your password which has to match with the password you created in _.vault_password_
- Go to directory _ansible-init_
- Setup the playground :<br>
```$: docker-compose up --build --remove-orphans --force-recreate```
- Wait until all of the containers have been successfully running
- Go to the _ansible-server_ container : <br>
```$: docker exec -it ansible-server bash```
- Play it.

## Makefile Commands

Run `make help` to see all available commands:

- `make setup` - Complete automated setup
- `make ssh-keys` - Generate SSH keys only
- `make vault-password` - Create vault password file
- `make vault` - Create vault file
- `make build` - Build Docker containers
- `make up` - Start containers
- `make down` - Stop containers
- `make restart` - Restart containers
- `make shell` - Access ansible-server container
- `make test` - Run sample echo playbook
- `make status` - Check setup status
- `make clean` - Clean up containers (keeps SSH keys and vault files)
- `make clean-all` - Clean up everything (WARNING: removes SSH keys and vault files)

__Sample :__<br>
`$: ansible-playbook playbook/echo.yml -i hosts/inventory`

```PLAY [echo messages] **************************************************************************************************************************

TASK [Gathering Facts] ************************************************************************************************************************
ok: [slave1]
ok: [slave2]

TASK [echo messages] **************************************************************************************************************************
changed: [slave1]
changed: [slave2]

TASK [debug] **********************************************************************************************************************************
ok: [slave1] => {
    "msg": "echo \"some messages\"\n"
}
ok: [slave2] => {
    "msg": "echo \"some messages\"\n"
}

PLAY RECAP ************************************************************************************************************************************
slave1                     : ok=3    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
slave2                     : ok=3    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0```


