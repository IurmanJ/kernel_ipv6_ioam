#!/bin/bash
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root"
  exit
fi

# Stop containers
lxc-stop -n athos
lxc-stop -n porthos
lxc-stop -n aramis

# Destroy containers
lxc-destroy -n athos
lxc-destroy -n porthos
lxc-destroy -n aramis

