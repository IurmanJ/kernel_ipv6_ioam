#!/bin/bash

sudo sysctl -w net.ipv6.conf.all.forwarding=1

# Create containers
sudo lxc-create -n alpha -t ubuntu
sudo lxc-create -n athos -t ubuntu
sudo lxc-create -n porthos -t ubuntu
sudo lxc-create -n aramis -t ubuntu
sudo lxc-create -n beta -t ubuntu

# Start containers
sudo lxc-start -n alpha -d
sudo lxc-start -n athos -d
sudo lxc-start -n porthos -d
sudo lxc-start -n aramis -d
sudo lxc-start -n beta -d

# PIDs containers
pid_alpha=$(sudo lxc-info -n alpha | grep "PID:" | awk '{print $2}')
pid_athos=$(sudo lxc-info -n athos | grep "PID:" | awk '{print $2}')
pid_porthos=$(sudo lxc-info -n porthos | grep "PID:" | awk '{print $2}')
pid_aramis=$(sudo lxc-info -n aramis | grep "PID:" | awk '{print $2}')
pid_beta=$(sudo lxc-info -n beta | grep "PID:" | awk '{print $2}')

# Bridge Alpha <-> Athos
sudo ip link add name h_alpha1 type veth peer name h_athos1
sudo ip link set netns $pid_alpha dev h_alpha1
sudo ip link set netns $pid_athos dev h_athos1
sudo nsenter -t $pid_alpha -n ifconfig h_alpha1 up
sudo nsenter -t $pid_athos -n ifconfig h_athos1 up

# Bridge Athos <-> Porthos
sudo ip link add name h_athos2 type veth peer name h_porthos1
sudo ip link set netns $pid_athos dev h_athos2
sudo ip link set netns $pid_porthos dev h_porthos1
sudo nsenter -t $pid_athos -n ifconfig h_athos2 up
sudo nsenter -t $pid_porthos -n ifconfig h_porthos1 up

# Bridge Porthos <-> Aramis
sudo ip link add name h_porthos2 type veth peer name h_aramis1
sudo ip link set netns $pid_porthos dev h_porthos2
sudo ip link set netns $pid_aramis dev h_aramis1
sudo nsenter -t $pid_porthos -n ifconfig h_porthos2 up
sudo nsenter -t $pid_aramis -n ifconfig h_aramis1 up

# Bridge Aramis <-> Beta
sudo ip link add name h_aramis2 type veth peer name h_beta1
sudo ip link set netns $pid_aramis dev h_aramis2
sudo ip link set netns $pid_beta dev h_beta1
sudo nsenter -t $pid_aramis -n ifconfig h_aramis2 up
sudo nsenter -t $pid_beta -n ifconfig h_beta1 up

# Configure Alpha
sudo lxc-attach -n alpha -- \
  bash -c "
    ip -6 address add db00::2/64 dev h_alpha1
    ip link set dev h_alpha1 address 2e:fe:7c:b0:c7:70
    ip -6 route add default via db00::1
    ethtool -K h_alpha1 rx off tx off
"

# Configure Athos
sudo lxc-attach -n athos -- \
  bash -c "
    sysctl -w net.ipv6.conf.all.forwarding=1
    mknod /dev/ioam c 10 59
    chmod 666 /dev/ioam
    ip link set dev h_athos1 address 2e:fe:7c:b0:c7:71
    ip link set dev h_athos2 address 2e:fe:7c:b0:c7:72
    ip -6 address add db00::1/64 dev h_athos1
    ip -6 address add db01::1/64 dev h_athos2
    ip -6 route add db02::0/64 via db01::2 dev h_athos2
    ip -6 route add db03::0/64 via db01::2 dev h_athos2
    ethtool -K h_athos1 rx off tx off
    ethtool -K h_athos2 rx off tx off
    ./athos/ioam_register
"

# Configure Porthos
sudo lxc-attach -n porthos -- \
  bash -c "
    sysctl -w net.ipv6.conf.all.forwarding=1
    mknod /dev/ioam c 10 59
    chmod 666 /dev/ioam
    ip link set dev h_porthos1 address 2e:fe:7c:b0:c7:73
    ip link set dev h_porthos2 address 2e:fe:7c:b0:c7:74
    ip -6 address add db01::2/64 dev h_porthos1
    ip -6 address add db02::1/64 dev h_porthos2
    ip -6 route add db00::0/64 via db01::1 dev h_porthos1
    ip -6 route add db03::0/64 via db02::2 dev h_porthos2
    ethtool -K h_porthos1 rx off tx off
    ethtool -K h_porthos2 rx off tx off
    ./porthos/ioam_register
"

# Configure Aramis
sudo lxc-attach -n aramis -- \
  bash -c "
    sysctl -w net.ipv6.conf.all.forwarding=1
    mknod /dev/ioam c 10 59
    chmod 666 /dev/ioam
    ip link set dev h_aramis1 address 2e:fe:7c:b0:c7:75
    ip link set dev h_aramis2 address 2e:fe:7c:b0:c7:76
    ip -6 address add db02::2/64 dev h_aramis1
    ip -6 address add db03::1/64 dev h_aramis2
    ip -6 route add db00::0/64 via db02::1 dev h_aramis1
    ip -6 route add db01::0/64 via db02::1 dev h_aramis1
    ethtool -K h_aramis1 rx off tx off
    ethtool -K h_aramis2 rx off tx off
    ./aramis/ioam_register
"

# Configure Beta
sudo lxc-attach -n beta -- \
  bash -c "
    ip -6 address add db03::2/64 dev h_beta1
    ip link set dev h_beta1 address 2e:fe:7c:b0:c7:77
    ip -6 route add default via db03::1
    ethtool -K h_beta1 rx off tx off
"

