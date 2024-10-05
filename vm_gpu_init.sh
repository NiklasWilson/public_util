#!/bin/bash

# Dont rerun
if test -f "/home/Ubuntu/skip_vm_gpu_init.txt"; then 
    echo "Already ran in the past, skipping"
    exit 0
fi

# init
apt update
apt -y install htop screen
apt -y upgrade

# Install Nvidia Drivers
distribution=$(. /etc/os-release;echo $ID$VERSION_ID | sed -e 's/\.//g')
wget -O /home/Ubuntu/cuda-keyring_1.0-1_all.deb https://developer.download.nvidia.com/compute/cuda/repos/$distribution/x86_64/cuda-keyring_1.0-1_all.deb
dpkg -i /home/Ubuntu/cuda-keyring_1.0-1_all.deb
apt update
apt -y install cuda-drivers

# Add Docker's official GPG key:
apt update
apt install -y ca-certificates curl gnupg
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null
apt -y update
apt -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Install Nvidia Container toolkit
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg \
  && curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
    sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
    tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

apt -y update
apt -y install nvidia-container-toolkit cuda-toolkit
nvidia-ctk runtime configure --runtime=docker
systemctl restart docker

apt update; apt -y install npm; npm install pm2 -g; pm2 install pm2-logrotate; pm2 set pm2-logrotate:compress true
pip install -y nvitop
apt install -y ufw; ufw allow 30333/tcp; ufw allow 22/tcp; ufw allow 8000:8999/tcp; ufw allow 8000:8999/udp; ufw enable

# Default Packages
apt update && apt -y upgrade && apt -y install build-essential git clang curl libssl-dev llvm libudev-dev make protobuf-compiler && apt -y autoremove
touch /home/Ubuntu/skip_vm_gpu_init.txt
reboot
