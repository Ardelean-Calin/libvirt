#!/usr/bin/env bash

systemd-notify --ready --status="Starting VM sync..."
rsync $HOME/.libvirt/images/ -r --delete dietpi@10.134.6.112:/mnt/hdd/data/VMs
systemd-notify --stopping --status="VM sync done!"
