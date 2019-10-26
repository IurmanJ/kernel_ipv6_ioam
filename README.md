# kernel_ipv6_ioam

Implementation of IOAM for IPv6 in the Linux Kernel, based on following drafts:
- [Deployment Considerations for In-situ OAM with IPv6 Options](https://tools.ietf.org/html/draft-ioametal-ippm-6man-ioam-ipv6-deployment-02) (version 02)
- [In-situ OAM IPv6 Options](https://tools.ietf.org/html/draft-ietf-ippm-ioam-ipv6-options-00) (version 00)
- [Data Fields for In-situ OAM](https://tools.ietf.org/html/draft-ietf-ippm-ioam-data-06) (version 06)

### Patching the kernel

Patches are generated from [another repository where development takes place](https://github.com/IurmanJ/linux-ioam-ipv6/tree/4.12_ioam).

In order to include IOAM, the kernel needs to be patched. Download the kernel version 4.12.
```
wget https://cdn.kernel.org/pub/linux/kernel/v4.x/linux-4.12.tar.xz
tar -Jxvf linux-4.12.tar.xz
``` 

Right now, there is only a patch for the kernel version 4.12. Patches for more recent kernel versions will come later. Apply the patch to the kernel.
```
git clone https://github.com/IurmanJ/kernel_ipv6_ioam
cd linux-4.12/
patch -p1 < ../kernel_ipv6_ioam/kernel_4_12.patch
``` 

Enable IOAM module.
```
make menuconfig
``` 

Go to "Networking support" > "Networking option" > "The IPv6 protocol". At the bottom, select "IPv6: in-situ OAM (iOAM)". Save and exit.

Build the kernel.
```
make bzImage
make modules
``` 

Install it on your host machine or on a virtual machine (your choice).
```
cd linux-4.12/
sudo make modules_install
sudo make install
sudo make INSTALL_HDR_PATH=/usr headers_install
```

### LXC Topology

For the sake of simplicity, Linux Containers (lxc) will be used to simulate a five-node topology.
```
sudo apt-get install -y lxc lxctl lxc-templates util-linux
```

![Topology](./lxc/topology.png?raw=true "Topology")

Three nodes are involved in the IOAM domain:
- **Athos**: inserts or encapsulates IOAM headers, as well as its own IOAM data (when required)
- **Porthos**: inserts its own IOAM data (when required)
- **Aramis**: inserts its own IOAM data (when required) and removes or decapsulates IOAM headers

### Testing IOAM

For each IOAM node, compile its registration program
```
cd lxc/<node>/
gcc ioam_register.c -o ioam_register
```

Those registration programs are automatically invoked when starting the topology. You can modify them to include other IOAM options. If you do so, don't forget to (1) recompile and (2) unregister (ioam_unregister.c) then register again each IOAM node. Or simply restart the topology (much easier). Please see `/usr/include/linux/ioam.h` to learn how to modify the registration (each field is documented).

Start the topology
```
cd lxc/
./start.sh
```

Open a shell and enter **Alpha**.
```
sudo lxc-attach -n alpha
```

From inside **Alpha**, generate some traffic (eg. a ping) towards **Beta**
```
ping6 db03::2
```

Open another shell, enter either **Athos**, **Porthos** or **Aramis** and use tcpdump to see IOAM
```
sudo lxc-attach -n aramis
sudo tcpdump -vv -l -i h_aramis1
```

Note that you could also use Wireshark if you want a more detailed view of packets, for example:
```
sudo tcpdump -i h_aramis1 -w aramis_in.pcap
(...)
wireshark aramis_in.pcap
```

Stop and clean the topology when you're finished
```
cd lxc/
./stop.sh
```

