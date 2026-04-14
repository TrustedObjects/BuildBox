#!/bin/bash

# Align user UID/GID with host user
USER_ID=${HOST_UID:-9001}
GROUP_ID=${HOST_GID:-9001}
usermod -u $USER_ID buildbox
# files owner in home directory are automatically changed by usermod
groupmod -g $GROUP_ID buildbox
# files group in home directory are NOT automatically changed by groupmod
chgrp -R buildbox $(echo ~buildbox)

# Align docker group GID with the host docker socket GID so buildbox can
# access /var/run/docker.sock (bind-mounted from the host).
# The container's docker group GID may differ from the host's GID.
if [ -S /var/run/docker.sock ]; then
	DOCKER_SOCK_GID=$(stat -c '%g' /var/run/docker.sock)
	existing_group=$(getent group "${DOCKER_SOCK_GID}" | cut -d: -f1)
	if [ -z "${existing_group}" ]; then
		groupmod -g "${DOCKER_SOCK_GID}" docker
	elif [ "${existing_group}" != "docker" ]; then
		usermod -aG "${existing_group}" buildbox
	fi
	usermod -aG docker buildbox
fi

# Configure host name resolution
echo "127.0.0.1 buildbox" >> /etc/hosts

# Apply kernel settings
sysctl --system

# Start udev daemon
/usr/lib/systemd/systemd-udevd
