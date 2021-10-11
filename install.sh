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
   if [ -f /usr/sbin/launch-systemd-ns ]; then
       echo "This may have already been installed. If you really want"
       echo "to do this, re-run this script with the \`--force\` parameter."
       exit
   fi
fi

# The installation process will attempt to thunk over to Windows to
# setup WSLENV. If for some odd reason Windows interop is disabled,
# force it on
echo 1 > /proc/sys/fs/binfmt_misc/WSLInterop

# Make sure the packages we need are installed
echo Installing dependencies...
apt update -qq
if ! apt install -yqq daemonize dbus-user-session fontconfig; then
    echo "Failed to install required packages"
    exit
fi

this_dir="$(dirname $0)"

cp "$this_dir/scripts/enter-systemd-ns" /usr/sbin/enter-systemd-ns
cp "$this_dir/scripts/launch-systemd-ns" /usr/sbin/launch-systemd-ns
chmod 755 /usr/sbin/enter-systemd-ns

cp "$this_dir/units/wslg-xwayland.socket" /etc/systemd/system
cp "$this_dir/units/wslg-xwayland.service" /etc/systemd/system

systemctl enable wslg-xwayland.socket
systemctl enable wslg-xwayland.service

sudo tee /etc/sudoers.d/systemd-ns >/dev/null <<EOF
Defaults     env_keep += WSLPATH
Defaults     env_keep += WSLENV
Defaults     env_keep += WSL_INTEROP
Defaults     env_keep += WSL_DISTRO_NAME
Defaults     env_keep += PRE_NAMESPACE_PATH
Defaults     env_keep += PRE_NAMESPACE_PWD
%sudo ALL=(ALL) NOPASSWD: /usr/sbin/enter-systemd-ns
EOF

if ! grep 'launch-systemd-ns' /etc/bash.bashrc >/dev/null; then
    sed -i 2a"# launch-system-ns\nsource /usr/sbin/launch-systemd-ns\n" /etc/bash.bashrc
fi

sudo rm -f /etc/systemd/user/sockets.target.wants/dirmngr.socket
sudo rm -f /etc/systemd/user/sockets.target.wants/gpg-agent*.socket
sudo rm -f /lib/systemd/system/sysinit.target.wants/proc-sys-fs-binfmt_misc.automount
sudo rm -f /lib/systemd/system/sysinit.target.wants/proc-sys-fs-binfmt_misc.mount
sudo rm -f /lib/systemd/system/sysinit.target.wants/systemd-binfmt.service

>/dev/null 2>&1 /mnt/c/Windows/System32/cmd.exe /C setx WSLENV BASH_ENV
>/dev/null 2>&1 /mnt/c/Windows/System32/cmd.exe /C setx BASH_ENV /etc/bash.bashrc

echo "Done."
