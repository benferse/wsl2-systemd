# You don't need this any longer

Check out the [announcement](https://devblogs.microsoft.com/commandline/systemd-support-is-now-available-in-wsl/) for the official support of systemd in WSL. What a time to be alive.

# wsl2-systemd

Enable basic systemd service management support for WSL2

This is a fork and some minor updates to other attempts at this based on a rough set of
instructions on the Snapcraft forums, and extended with some additional WSL2/wslg support.

## Usage

Fork the repo and run the install script.

```sh
sudo apt install -y git
git clone https://github.com/benferse/wsl2-systemd
cd wsl2-systemd
./install.sh
```

Once the installer finishes, restart a WSL shell, and see if you can talk to the service manager

```sh
systemctl
```

## Supported distros

Find WSL distributions in [the store](https://aka.ms/wslstore)

- Ubuntu 20.04

## Limitations

- Assumes bash in lots of places, sorry

## Shout outs

- [Dani](https://github.com/diddledani)
- [Damion](https://github.com/damiongans)
- [Daniel](https://forum.snapcraft.io/u/daniel)
