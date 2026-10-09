# SleepSwitch

A native macOS menu bar app. One Swift file, no dependencies.

Open **SleepSwitch.app**, click its menu bar icon, and toggle **Prevent Sleep**.
Checked / filled coffee cup = prevention on. Unchecked / outlined cup = prevention off.

The toggle runs `/usr/bin/pmset disablesleep 1` or `0` through macOS's administrator
prompt, equivalent to using `sudo`. Cancelling the prompt leaves the setting alone.
The app reads the real setting at launch, whenever the menu opens, and after a toggle.
It changes no other power settings. Quitting leaves the setting as it is.

To rebuild with Apple's Command Line Tools installed:

```sh
sh build.sh
open SleepSwitch.app
```

macOS 11 or later. The build targets the Mac you build it on.
No tests, timers, preferences, login items, or privileged helper.
