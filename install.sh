#!/bin/bash

# Bootstrap a WSL2 instance to support systemd

if [ "$LOGNAME" != "root" ]; then
    sudo -E -p 'root privileges required, password: ' bash $0 "$@"
    exit $?
fi

if [ -z "$WSL_DISTRO_NAME" ]; then
    echo "Running this outside of a WSL environment is a terrible idea"
    exit
fi

if [ "$1" != "--force" ]; then
   if [ -f /etc/wsl.conf ]; then
       echo "This distro already has a custom wsl.conf. If you really want"
       echo "to do this, re-run this script with the \`--force\` parameter."
       exit
   fi
fi

# The installation process will attempt to thunk over to Windows to
# setup WSLENV. If for some odd reason Windows interop is disabled,
# force it on
echo Enabling WSL/Windows interop...
echo 1 > /proc/sys/fs/binfmt_misc/WSLInterop

this_dir="$(dirname $0)"

echo Installing wsl.conf...
cp "$this_dir/etc/wsl.conf" /etc

echo Installing systemd namespace support...
cp "$this_dir/etc/00-wsl2-systemd.sh" /etc/profile.d

echo Installing systemd units for wslg...
cp "$this_dir/units/wslg-xwayland.socket" /etc/systemd/system
cp "$this_dir/units/wslg-xwayland.service" /etc/systemd/system
cp "$this_dir/units/user-runtime-dir.override" "/etc/systemd/system/user-runtime-dir@.service.d/override.conf"

systemctl enable wslg-xwayland.socket
systemctl enable wslg-xwayland.service

echo Updating sudoers...
cp "$this_dir/etc/wsl2-systemd.sudoers" /etc/sudoers.d

echo "Done. You will need to restart your WSL instance to enable systemd."
read -r -p "Reboot WSL now? [y/N]: " response
if [[ "$response" =~ ^([Yy][Ee][Ss]|[Yy])$ ]]; then
    /mnt/c/Windows/System32/wsl.exe -d "$WSL_DISTRO_NAME" --shutdown
fi
