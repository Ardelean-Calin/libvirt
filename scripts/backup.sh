#!/usr/bin/env bash

echo "Starting backup of virtual machines..."
rsync $HOME/.libvirt/images/ -r --delete dietpi@10.134.6.112:/mnt/hdd/data/VMs
echo "Backup done."
