SYSTEMD_EXE="/usr/lib/systemd/systemd --unit=multi-user.target" # snapd requires multi-user.target not basic.target
SYSTEMD_PID="$(ps -C systemd -o pid= | head -n1)"

# If systemd wasn't started at boot time by wsl's init process,
# then there's nothing else to do here
if [ -z "$SYSTEMD_PID" ]; then
    exit
fi

# If systemd does not appear to be PID 1, then attempt to enter its
# namespace
if [ "$SYSTEMD_PID" -ne 1 ]; then
    # If we're not already in an su environment, then capture our environment before
    # attempting to elevate so it can be resumed later
	if [ -z "$SUDO_USER" ]; then
		[ -f "$HOME/.systemd.env" ] && rm -f "$HOME/.systemd.env"
		export > "$HOME/.systemd.env"
	fi

    # If we're not root, we need to be. Relaunch ourselves with sudo.
	if [ "$USER" != "root" ]; then
        exec sudo /bin/sh /etc/profile.d/00-wsl2-systemd.sh
    fi

    # If we're here, we are running as root, but still haven't entered the systemd namespace.
    # Make any changes we need to make to the environment.
	if ! grep -q WSL_INTEROP /etc/environment; then
		echo "WSL_INTEROP='/run/WSL/$(ls -rv /run/WSL | head -n1)'" >> /etc/environment
	else
		sed -i "s|WSL_INTEROP=.*|WSL_INTEROP='/run/WSL/$(ls -rv /run/WSL | head -n1)'|" /etc/environment
	fi

	if ! grep -q WSL_DISTRO_NAME /etc/environment; then
		echo "WSL_DISTRO_NAME='$WSL_DISTRO_NAME'" >> /etc/environment
	fi

	if [ -z "$DISPLAY" ]; then
		if [ -f "/tmp/.X11-unix/X0" ]; then
			echo "DISPLAY=:0" >> /etc/environment
		else
			echo "DISPLAY=$(awk '/nameserver/ { print $2":0" }' /etc/resolv.conf)" >> /etc/environment
		fi
	elif ! grep -q DISPLAY /etc/environment; then
		echo "DISPLAY='$DISPLAY'" >> /etc/environment
	else
		sed -i "s/DISPLAY=.*/DISPLAY='$DISPLAY'/" /etc/environment
	fi

	IS_SYSTEMD_READY_CMD="/usr/bin/nsenter --mount --pid --target $SYSTEMD_PID -- systemctl is-system-running"
	WAITMSG="$($IS_SYSTEMD_READY_CMD 2>&1)"
	if [ "$WAITMSG" = "initializing" ] || [ "$WAITMSG" = "starting" ] || [ "$WAITMSG" = "Failed to connect to bus: No such file or directory" ]; then
		echo "Waiting for systemd to finish booting"
	fi
	while [ "$WAITMSG" = "initializing" ] || [ "$WAITMSG" = "starting" ] || [ "$WAITMSG" = "Failed to connect to bus: No such file or directory" ]; do
		echo -n "."
		sleep 1
		WAITMSG="$($IS_SYSTEMD_READY_CMD 2>&1)"
	done
	echo "\nSystemd is ready. Logging in."

    exec /usr/bin/nsenter --mount --pid --target "$SYSTEMD_PID" -- su - "$SUDO_USER"
fi

# If we're here, we're already in the systemd namespace. However, we've exec'd over
# the process that would have run the rest of the profile, so we have to do that
# ourselves

unset SYSTEMD_EXE
unset SYSTEMD_PID

for script in /etc/profile.d/*.sh; do
	if [ "$script" = "/etc/profile.d/00-wsl2-systemd.sh" ]; then
		continue
	fi
	source "$script"
done

if [ -f "$HOME/.systemd.env" ]; then
	set -a
	source "$HOME/.systemd.env"
	set +a
	rm "$HOME/.systemd.env"
fi

cd "$PWD"

if [ -d "$HOME/.wslprofile.d" ]; then
	for script in "$HOME/.wslprofile.d/"*; do
		source "$script"
	done
	unset script
fi
