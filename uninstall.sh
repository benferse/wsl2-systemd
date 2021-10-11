#!/bin/bash

# Undoes changes made by install.sh

if [ "$LOGNAME" != "root" ]; then
    sudo -E -p 'root privileges required, password: ' bash $0 "$@"
    exit $?
fi

if [ -z "$WSL_DISTRO_NAME" ]; then
    echo "Running this outside of a WSL environment is a terrible idea"
    exit
fi

# The uninstall process will attempt to thunk over to Windows to
# setup WSLENV. If for some odd reason Windows interop is disabled,
# force it on
echo Enabling WSL/Windows interop...
echo 1 > /proc/sys/fs/binfmt_misc/WSLInterop

echo Removing custom wsl.conf...
rm -f /etc/wsl.conf

echo Removing systemd configuration...
rm -f /etc/profile.d/00-wsl2-systemd.sh
rm -f /usr/sbin/launch-systemd-ns

echo Removing systemd units for wslg...
rm -f /etc/systemd/system/wslg-xwayland.service
rm -f /etc/systemd/system/wslg-xwayland.socket
rm -f /etc/systemd/system/user-runtime-dir@.service.d/override.conf
rm -f /etc/systemd/system/multi-user.target.wants/wslg-xwayland.service
rm -f /etc/systemd/system/multi-user.target.wants/wslg-xwayland.socket

echo Updating sudoers...
rm -f /etc/sudoers.d/wsl2-systemd-sudoers

echo Fixing the wslg Wayland runtime dir...
rm -rf /tmp/.X11-unix
ln -s /mnt/wslg/.X11-unix /tmp

echo "Done. You should restart your WSL instance to cleanup."
read -r -p "Reboot WSL now? [y/N]: " response
if [[ "$response" =~ ^([Yy][Ee][Ss]|[Yy])$ ]]; then
    /mnt/c/Windows/System32/wsl.exe -d "$WSL_DISTRO_NAME" --shutdown
fi
