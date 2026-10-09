# wired

Automatically sets `pmset disablesleep 1` on external power and `0` on battery/UPS.
Runs at launch and on power-source changes. One Swift file, no polling.

Filled cup = sleep disabled. Outlined cup = sleep allowed. `?` = error; hover for details.
Quitting leaves the current setting in place. Sleep follows normal macOS rules when allowed.

Requires macOS 11+, Apple's Command Line Tools (`xcode-select --install`),
and [just](https://just.systems/man/en/) (`brew install just`).

```sh
git clone https://github.com/dionysuzx/wired.git
cd wired
just add-sudoers
just install-app
```

`add-sudoers` requires an admin password once. It grants your user passwordless
access to only the two commands above; any app running as you can use that permission.
`install-app` builds, installs in `~/Applications`, and launches the app.

- Update: `git pull && just install-app`.
- Check: `pmset -g | awk '$1 == "SleepDisabled" { print $2 }'`.
- Remove permission: `sudo rm "/private/etc/sudoers.d/sleepswitch-$(id -u)"`.
