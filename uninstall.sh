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
echo 1 > /proc/sys/fs/binfmt_misc/WSLInterop

rm -f /usr/sbin/launch-systemd-ns
rm -f /usr/sbin/enter-systemd-ns
rm -f /etc/sudoers.d/systemd-ns
sed -i '/launch-systemd-ns/d' /etc/bash.bashrc

>/dev/null 2>&1 /mnt/c/Windows/System32/reg.exe delete "HKCU\Environment" /F /V "BASH_ENV"
>/dev/null 2>&1 /mnt/c/Windows/System32/reg.exe delete "HKCU\Environment" /F /V "WSLENV"
