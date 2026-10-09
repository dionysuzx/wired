default:
    @just --list

# Allow only disablesleep 0 and 1 without a password.
# Keep the sudoers filename stable for existing installations.
add-sudoers:
    #!/bin/sh
    set -eu
    rule="$(mktemp)"
    trap 'rm -f "$rule"' EXIT
    printf '%s ALL=(root) NOPASSWD: /usr/bin/pmset disablesleep 0, /usr/bin/pmset disablesleep 1\n' "$(id -un)" > "$rule"
    /usr/sbin/visudo -cf "$rule"
    sudo mkdir -p /private/etc/sudoers.d
    sudo /usr/bin/install -o root -g wheel -m 0440 "$rule" "/private/etc/sudoers.d/sleepswitch-$(id -u)"
    sudo /usr/sbin/visudo -c

# Build, install for the current user, and launch.
install-app:
    #!/bin/sh
    set -eu
    sh build.sh
    mkdir -p "$HOME/Applications"
    if pgrep -x wired > /dev/null; then
        pkill -x wired
    fi
    ditto wired.app "$HOME/Applications/wired.app"
    open "$HOME/Applications/wired.app"
