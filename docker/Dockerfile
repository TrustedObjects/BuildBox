FROM debian:12-slim
ARG VERSION=2.0.0-rc2

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

# Development
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
	gdb \
	strace \
	python3 \
	python3-pip \
	python3.11-venv

# System
RUN apt install --yes \
	sudo \
	dmidecode \
	udev libudev1 \
	iproute2 \
	acl

# SCM
RUN apt install --yes \
	git

# Text editors
RUN apt install --yes \
	nano

# Utilities
RUN apt install --yes \
	bison \
	flex \
	cscope \
	quilt \
	jq \
	wget \
	curl \
	usbutils \
	lsof \
	rsync \
	inotify-tools \
	bc \
	iputils-ping \
	inetutils-telnet \
	inetutils-ftp \
	netcat-openbsd \
	libncurses5 ncurses-bin \
	uuid-runtime \
	libxml2-dev

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

###############################################################################
# Settings
###############################################################################

RUN useradd -s /bin/zsh buildbox
RUN mkdir /home/buildbox && chown buildbox:buildbox /home/buildbox
RUN echo $VERSION > /etc/version

# Sudo
RUN echo "Defaults env_keep += \" BB_* BUILDBOX* DOCKER_* BUILDX_* XDG_* TMPDIR PATH PYTHONPATH LD_LIBRARY_PATH PKG_CONFIG_PATH ACLOCAL_PATH CHOST PREFIX LDFLAGS CFLAGS CPU CPUDEF CPU_FAMILY\"" > /etc/sudoers.d/buildbox
RUN echo "buildbox ALL=(ALL:ALL) ALL" >> /etc/sudoers.d/buildbox

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
