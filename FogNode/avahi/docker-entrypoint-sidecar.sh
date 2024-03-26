#!/bin/sh

# Remove the D-Bus PID file if it exists to avoid startup error
rm -f /run/dbus/dbus.pid

# Start dbus-daemon
dbus-daemon --system --nofork &

# Wait a moment to ensure D-Bus is fully up
sleep 1

# Start avahi-daemon
avahi-daemon --no-chroot --debug