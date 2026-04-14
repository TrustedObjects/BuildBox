FROM debian:12-slim
ARG VERSION=2.0.0-rc1

# Update packages list and upgrade packages
RUN apt update
RUN apt upgrade --yes

# Locale
RUN apt install --yes locales
RUN echo en_US.UTF-8 UTF-8 > /etc/locale.gen
RUN locale-gen

# Timezone
ENV TZ=Europe/Paris
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

###############################################################################
# Install packages
###############################################################################

RUN dpkg --add-architecture i386
RUN apt update
RUN apt install --yes \
	libc6:i386

# Developemnt
RUN apt install --yes \
	binutils \
	gcc \
	m4 \
	make \
	patch \
	cmake \
	automake \
	autoconf \
	libtool \
	pkg-config \
	golang-go \
	nodejs \
	npm \
	gdb \
	valgrind \
	strace \
	stlink-tools \
	python3 \
	python3-pip \
	python3.11-venv \
	python3-numpy \
	python3-pycryptodome

# System
RUN apt install --yes \
	sudo \
	libasound2 \
	dmidecode \
	debootstrap \
	udev libudev-dev \
	iproute2 \
	acl \
	efitools

# SCM
RUN apt install --yes \
	git \
	tig \
	mercurial

# Text editors
RUN apt install --yes \
	vim \
	nano

# Utilities
RUN apt install --yes \
	dos2unix \
	bison \
	flex \
	cscope \
	quilt \
	jq \
	gpp \
	wget \
	curl \
	tree \
	usbutils \
	lsof \
	rsync \
	inotify-tools \
	bc \
	mc \
	iputils-ping \
	inetutils-telnet \
	inetutils-telnetd \
	inetutils-ftp \
	inetutils-ftpd \
	netcat-openbsd \
	libncurses5 ncurses-bin \
	nanomsg-utils libnanomsg5 libnanomsg-dev \
	uuid-runtime \
	libxml2-dev \
	picocom \
	pwgen

# Disk utilities
RUN apt install --yes \
	parted \
	xorriso \
	dosfstools

# Archiving
RUN apt install --yes \
	zip \
	unzip \
	gzip \
	bzip2 \
	pigz \
	cpio \
	libarchive-tools \
	zlib1g zlib1g:i386

# Shell
RUN apt install --yes \
	zsh \
	zsh-syntax-highlighting \
	openssh-client

# Qemu
RUN apt install --yes \
	qemu-system-x86 \
	qemu-system-arm \
	qemu-user-static \
	qemu-utils

# Containers and isolation
RUN apt install --yes \
	uidmap \
	fuse-overlayfs \
	slirp4netns

# Windows tools
RUN apt install --yes \
	wine

# Documentation
RUN apt install --yes \
	man-db \
	texlive-binaries \
	texlive-latex-extra \
	texlive-pictures \
	texlive-luatex \
	texlive-extra-utils \
	texlive-base \
	latexmk \
	doxygen \
	inkscape \
	python3-sphinx \
	python3-breathe \
	python3-seqdiag \
	python3-blockdiag \
	python3-sphinxcontrib.seqdiag \
	python3-sphinxcontrib.blockdiag \
	python3-sphinxcontrib.bibtex \
	fonts-cmu

# Docker (from official distribution)
RUN apt-get install --yes ca-certificates curl gnupg
RUN install -m 0755 -d /etc/apt/keyrings
RUN curl -fsSL https://download.docker.com/linux/debian/gpg \
	| gpg --dearmor -o /etc/apt/keyrings/docker.gpg
RUN chmod a+r /etc/apt/keyrings/docker.gpg
RUN echo \
	"deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
	"$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
	tee /etc/apt/sources.list.d/docker.list > /dev/null
RUN apt-get update
RUN apt-get install --yes \
	docker-ce \
	docker-ce-cli \
	containerd.io \
	docker-buildx-plugin \
	docker-compose-plugin \
	docker-ce-rootless-extras

# ESP-IDF requirements
RUN pip install --break-system-packages \
	"setuptools>=21" \
	"click>=7.0" \
	"pyserial>=3.3" \
	"future>=0.15.2" \
	"cryptography>=2.1.4" \
	"pyparsing>=2.0.3,<2.4.0" \
	"pyelftools>=0.22" \
	"reedsolo>=1.5.3,<=1.5.4" \
	"idf-component-manager>=0.2.99-beta" \
	"pygdbmi<=0.11.0.0" \
	"python-socketio<5" \
	"kconfiglib==13.7.1" \
	"construct==2.10.54" \
	"bitstring>=3.1.6" \
	"ecdsa>=0.16.0"

###############################################################################
# Settings
###############################################################################

RUN useradd -s /bin/zsh buildbox
RUN mkdir /home/buildbox && chown buildbox:buildbox /home/buildbox
RUN echo $VERSION > /etc/version

# Sudo
RUN echo "Defaults env_keep += \" BB_* BUILDBOX* DOCKER_* BUILDX_* XDG_* TMPDIR PATH PYTHONPATH LD_LIBRARY_PATH PKG_CONFIG_PATH ACLOCAL_PATH CHOST PREFIX LDFLAGS CFLAGS CPU CPUDEF CPU_FAMILY\"" > /etc/sudoers.d/buildbox
RUN echo "buildbox ALL=(ALL:ALL) ALL" >> /etc/sudoers.d/buildbox

# Docker
RUN chmod u+s /usr/bin/newuidmap /usr/bin/newgidmap
RUN echo "kernel.unprivileged_userns_clone=1" >> /etc/sysctl.d/rootless-docker.conf
RUN echo "net.ipv4.ping_group_range = 0 2147483647" >> /etc/sysctl.d/rootless-docker.conf
RUN echo "net.ipv4.ip_unprivileged_port_start=0" >> /etc/sysctl.d/rootless-docker.conf
RUN usermod -aG docker buildbox
RUN usermod -aG uucp buildbox
RUN usermod -aG dialout buildbox
RUN usermod -aG plugdev buildbox
# rootlesskit-docker-proxy is no longer part of Docker distribution, and is in conflict with it if installed from rootlesskit Debian package
RUN ln -s /usr/bin/docker-proxy /usr/local/bin/rootlesskit-docker-proxy

# System-wide environment
RUN echo "PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin" >> /etc/environment
# DEFAULT_PATH is the baseline PATH restored by bb_reset_sys_env before
# applying per-project overrides; must match the system PATH above.
ENV DEFAULT_PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# Python
RUN ln -s /usr/bin/python3 /usr/local/bin/python

# Users and capabilities
RUN passwd -d buildbox
RUN passwd -d root
RUN setcap cap_sys_ptrace=eip /usr/bin/gdb
RUN chmod u+s /usr/sbin/dmidecode

# Udev
COPY 99-custom-ttyUSB-permissions.rules /etc/udev/rules.d/99-custom-ttyUSB-permissions.rules

# Run
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
