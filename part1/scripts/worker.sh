
#!/bin/bash

PURPLE="\033[35m"
RED="\033[31m"
RESET="\033[0m"

apt-get update 
apt-get install -y net-tools
sudo alias k='kubectl'


if export INSTALL_K3S_EXEC="agent -s https://192.168.56.110:6443 -t $(cat /vagrant/token.env) --node-ip=192.168.56.111"; then
        echo -e "${PURPLE}export INSTALL_K3S_EXEC SUCCEEDED${RESET}"
else
        echo -e "${RED}export INSTALL_K3S_EXEC FAILED${RESET}"
fi 

if curl -sfL https://get.k3s.io | sh -; then
	echo -e "${PURPLE}K3s WORKER installation SUCCEEDED${RESET}"
else
	echo -e "${RED}K3s WORKER installation FAILED${RESET}"
fi

if sudo ip link add eth1 type dummy && sudo ip addr add 192.168.56.111/24 dev eth1 && sudo ip link set eth1 up; then
        echo -e "${PURPLE}adding IP address on interface eth1 SUCCEEDED${RESET}"
else
        echo -e "${RED}adding IP address on interface eth1 FAILED${RESET}"
fi

# We delete the token for security, and also so that when restarting, a new token is used and not the previously created one

sudo rm /vagrant/token.env
