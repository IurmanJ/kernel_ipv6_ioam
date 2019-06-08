#!/bin/bash

# Stop containers
sudo lxc-stop -n alpha -k
sudo lxc-stop -n athos -k
sudo lxc-stop -n porthos -k
sudo lxc-stop -n aramis -k
sudo lxc-stop -n beta -k

# Destroy containers
sudo lxc-destroy -n alpha
sudo lxc-destroy -n athos
sudo lxc-destroy -n porthos
sudo lxc-destroy -n aramis
sudo lxc-destroy -n beta

