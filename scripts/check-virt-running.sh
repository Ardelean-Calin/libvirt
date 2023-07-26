#!/usr/bin/env bash

if virsh list --all | grep -q running 
then
  echo "Virt manager is running." 
  exit 1
else
  echo "Virt manager is not running."
  exit 0
fi

