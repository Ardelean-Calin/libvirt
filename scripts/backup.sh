#!/usr/bin/env bash

show_notification ()
{
  gdbus call --session \
    --dest=org.freedesktop.Notifications \
    --object-path=/org/freedesktop/Notifications \
    --method=org.freedesktop.Notifications.Notify \
    "" 0 "" "$1" "$2" \
    '[]' '{"urgency": <1>}' 5000
}

echo "Starting backup of virtual machines..."
show_notification "VM Backup ongoing" "Started backup of virtual machine images."
rsync $HOME/.libvirt/images/ -r --delete dietpi@10.134.6.112:/mnt/hdd/data/VMs
show_notification "VM Backup finised!" "Finished backup of all virtual machine images."
echo "Backup done."
