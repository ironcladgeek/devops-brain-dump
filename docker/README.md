## Installation methods

### Install using the repository


```bash
# Ubuntu

# set up the repository
$ sudo apt-get update
$ sudo apt-get install \
    ca-certificates \
    curl \
    gnupg \
    lsb-release
$ sudo mkdir -m 0755 -p /etc/apt/keyrings
$ curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
$ echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

#  install the latest version
$ sudo apt-get update
$ sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# add user to `docker` group
$ sudo usermod -aG docker <username>
```

## Uninstall docker completely
```bash
$ sudo apt-get purge docker-ce docker-ce-cli containerd.io docker-compose-plugin
$ sudo rm -rf /var/lib/docker
$ sudo rm -rf /var/lib/containerd
```

## docker services

### Check docker services

Use one of the following:
```bash
$ systemctl list-unit-files | grep -i 'state\|docker'
```

```bash
$ systemctl status docker
```

### Disable autostart docker services

```bash
$ sudo systemctl disable docker.service
$ sudo systemctl disable docker.socket
```

## docker commands

#### List running containers
```bash
$ docker ps
```

#### List all containers
```bash
$ docker ps -a
```

#### Show size of each running container
```bash
$ docker ps --size
```

#### List all images
```bash
$ docker image ls -a
```
