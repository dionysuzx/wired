# SleepSwitch

A native macOS menu bar app. One Swift file, no runtime dependencies.

## Install

Requires macOS 11 or later, Apple's Command Line Tools (`xcode-select --install`),
and [just](https://just.systems/man/en/) (`brew install just` if you use Homebrew).

```sh
git clone https://github.com/dionysuzx/SleepSwitch.git
cd SleepSwitch
just add-sudoers
just install-app
```

`add-sudoers` asks for your administrator password during setup. It validates and
installs a sudoers rule allowing your user to run only `/usr/bin/pmset disablesleep 0`
and `/usr/bin/pmset disablesleep 1` without a password. Other apps running as you
can also use this permission. No passwords are stored.

`install-app` builds for your Mac, installs in `~/Applications`, and launches the
app. Run it again to rebuild and update the installation.

## Use

Open **SleepSwitch.app**. Right-click its menu bar icon to toggle sleep prevention
directly, or left-click to open the menu and toggle **Prevent Sleep**.
Checked / filled coffee cup = prevention on. Unchecked / outlined cup = prevention off.

The toggle runs `sudo -n /usr/bin/pmset disablesleep 1` or `0`, with no password
prompt. If it fails, run `just add-sudoers` from the project folder to set up access.
The app reads the real setting at launch, whenever the menu opens, and after a toggle.
It changes no other power settings. Quitting leaves the setting as it is.

To print the current setting (`1` = sleep disabled, `0` = sleep allowed):

```sh
pmset -g | awk '$1 == "SleepDisabled" { print $2 }'
```

To build without installing:

```sh
sh build.sh
open SleepSwitch.app
```

No tests, timers, preferences, login items, or privileged helper.

To remove the passwordless permission:

```sh
sudo rm "/private/etc/sudoers.d/sleepswitch-$(id -u)"
```
