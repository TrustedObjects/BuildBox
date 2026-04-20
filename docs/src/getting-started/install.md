# Installation

## Requirements

The following tools must be installed on the host system before using BuildBox.

### Ubuntu / Debian

```bash
sudo apt-get update
sudo apt-get install -y bash make python3 curl git openssh-client
```

Docker must be installed separately following the [official guide](https://docs.docker.com/engine/install/debian).

::: tip
The preferred way to install Docker on Ubuntu or Debian is using the official Docker `apt` repository.
:::

::: warning
Do not install Docker from Snap, and do not use Docker Desktop.
:::

### Fedora

```bash
sudo dnf install -y bash make python3 curl git openssh
```

Docker must be installed separately following the [official guide](https://docs.docker.com/engine/install/fedora).

### ArchLinux

```bash
sudo pacman -S --needed bash make python curl git openssh docker
```

## Docker settings

To be able to manage Docker, ensure your user is in the `docker` group. If it is not the case, do:
```
sudo usermod -aG docker $(whoami)
```

and reconnect your session.

::: warning
On Ubuntu, it seems you have to reboot to refresh groups. So, if after reconnecting, the `groups` command does not show the `docker` group, you have to reboot.
:::

## Install BuildBox

Clone BuildBox somewhere on your system, or get it from your organization's repository:
```
git clone https://github.com/TrustedObjects/BuildBox.git
```

Then install it system-wide using `make`:
```
cd BuildBox
sudo make install
```

This installs the `bbx` launcher to `/usr/local/bin` and all supporting files to
`/usr/local/share/buildbox`. A custom prefix can be passed if needed:
```
sudo make install PREFIX=/opt/buildbox
```

Then fetch the latest BuildBox container image from Docker Hub:
```
bbx image fetch
```

To verify everything works, go to a BuildBox project directory and run:
```
bbx --help
```

::: tip
Enable the [shell prompt plugin](../user/advanced.md#shell-prompt-integration) to display
the active BuildBox project and target in your prompt, and to get shell completion for `bbx`
commands. It takes a single line in your `~/.bashrc` or `~/.zshrc`.
:::

## SSH settings

If you access packages from private repositories, BuildBox is going to use your SSH client settings to clone them.
So, SSH client has to be configured correctly.

First of all, ensure you have an SSH key. If this is not the case, you have to generate one, without passphrase (leave it empty when asked):
```
ssh-keygen
```

::: warning
For now, BuildBox doesn't support SSH keys with passphrases, this is planned for later.
:::

If you use SSH RSA keys, edit your `.ssh/config` file and add at the end:
```
Host *
    PubkeyAcceptedKeyTypes +ssh-rsa
```

If you use SSH DSA keys, edit your `.ssh/config` file and add at the end:
```
Host *
    PubkeyAcceptedKeyTypes +ssh-dss
```

## TTY USB devices

If you plan to use TTY USB devices from BuildBox, you have to add the following udev rules on your host, in `/etc/udev/rules.d/99-buildbox.rules`:
```
ACTION=="add", SUBSYSTEM=="usb", RUN+="/usr/local/share/buildbox/docker/bin/buildbox_tty_usb_sync"
ACTION=="remove", SUBSYSTEM=="usb", RUN+="/usr/local/share/buildbox/docker/bin/buildbox_tty_usb_sync"
```
If you installed with a custom prefix, adjust the path accordingly.

Then, reload and trigger udev rules:
```
sudo udevadm control --reload-rules
sudo udevadm trigger
```
