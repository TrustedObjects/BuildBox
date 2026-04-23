#!/bin/bash
# This file is part of BuildBox project
# Copyright (C) 2020-2026 Trusted Objects

# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# version 2, as published by the Free Software Foundation.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program; if not, see
# <https://www.gnu.org/licenses/>.

# Align user UID/GID with host user
USER_ID=${HOST_UID:-9001}
GROUP_ID=${HOST_GID:-9001}
usermod -u $USER_ID buildbox
# files owner in home directory are automatically changed by usermod
groupmod -g $GROUP_ID buildbox
# files group in home directory are NOT automatically changed by groupmod
chgrp -R buildbox $(echo ~buildbox)

# Create XDG runtime directory.
mkdir -p "/run/user/${USER_ID}"
chmod 700 "/run/user/${USER_ID}"
chown buildbox:buildbox "/run/user/${USER_ID}"

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
