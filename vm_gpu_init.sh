#!/bin/bash

# Dont rerun
if test -f "/home/Ubuntu/skip_vm_gpu_init.txt"; then 
    echo "Already ran in the past, skipping"
    exit 0
fi

# Setup default apt packages
apt -y update && apt -y upgrade && apt -y install lshw wget build-essential git clang curl libssl-dev llvm libudev-dev make protobuf-compiler htop screen ca-certificates curl gnupg npm ufw software-properties-common && apt -y autoremove
apt -y install linux-headers-$(uname -r)

# Setup default UFW firewall rules
ufw allow 30333/tcp; ufw allow 22/tcp; ufw allow 8000:8999/tcp; ufw allow 8000:8999/udp; ufw enable

# Add Nvidia Drivers to APT
distribution=$(. /etc/os-release;echo $ID$VERSION_ID | sed -e 's/\.//g')
wget -O /tmp/cuda-keyring_1.0-1_all.deb https://developer.download.nvidia.com/compute/cuda/repos/$distribution/x86_64/cuda-keyring_1.0-1_all.deb
dpkg -i /tmp/cuda-keyring_1.0-1_all.deb

# Add Docker to APT:
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null

# Add  Nvidia Container toolkit to APT
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg \
  && curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
    sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
    tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

# Setup Nvidia/Cuda/Docker
apt -y update && apt -y install cuda-drivers cuda-toolkit docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin nvidia-container-toolkit && apt -y autoremove
nvidia-ctk runtime configure --runtime=docker
systemctl restart docker

# Install PM2 with log rotation
npm install pm2 -g; pm2 install pm2-logrotate; pm2 set pm2-logrotate:compress true

# Install NVI top
pip install -y nvitop

# Prevent rerunning script and reboot
touch /home/Ubuntu/skip_vm_gpu_init.txt
reboot
