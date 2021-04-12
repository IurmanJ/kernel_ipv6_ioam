# Kernel patch for IPv6 IOAM

Implementation of IOAM for IPv6 in the Linux Kernel, based on following drafts:
- [In-situ OAM IPv6 Options](https://tools.ietf.org/html/draft-ietf-ippm-ioam-ipv6-options-05) (version 05)
- [Data Fields for In-situ OAM](https://tools.ietf.org/html/draft-ietf-ippm-ioam-data-12) (version 12)

### Patching the kernel

This patchset has been submitted to the [Netdev mailing list](https://lore.kernel.org/netdev/20210401182338.24077-1-justin.iurman@uliege.be/). It was developed based on the [net-next](https://git.kernel.org/pub/scm/linux/kernel/git/netdev/net-next.git) tree (v5.12-rc4) and is currently waiting for a review.

Before it gets officially merged, you'll need to download a recent version of the kernel (the patchset is available with kernel v5.10, for example) and patch it manually with the provided patchset. You might need to apply some minor modifications depending on changes merged since then.

## Demo

### Topology

For the sake of simplicity, Linux Containers (lxc) will be used to simulate a three-node topology.
```
sudo apt-get install -y lxc lxctl lxc-templates util-linux
```

![Topology](./demo/topology.png?raw=true "Topology")

Those three nodes are configured to form an IOAM domain:
- **Athos**: sends traffic and inserts IOAM headers as well as its own IOAM data
- **Porthos**: inserts its own IOAM data
- **Aramis**: inserts its own IOAM data and receives traffic

### Video

You can watch the entire demo by clicking on the video below. Note that the video is based on an old implementation where the IPv6 encapsulation scenario was possible (see [the old branch](https://github.com/IurmanJ/kernel_ipv6_ioam/tree/old)), but the principle remains the same. For some reasons, only the direct insertion has been implemented (for now) in the official patchset.

[![GIF_video](./demo/video.gif?raw=true "IPv6 IOAM demo video")](https://youtu.be/0Gxrtq-f5k8)

### Try it yourself !

Reminder: you need a kernel with IOAM.

Start the topology
```
cd demo/
sudo ./topology_setup.sh
```

Open a shell and enter **Athos**.
```
sudo lxc-attach -n athos
```

From inside **Athos**, generate some traffic (eg. a ping) towards **Aramis**
```
ping6 db02::2
```

Open another shell, enter **Aramis** and use tcpdump to see IOAM in action
```
sudo lxc-attach -n aramis
sudo tcpdump -vv -l -i h_aramis
```

Note that you could also use Wireshark if you want a more detailed view of packets, for example:
```
sudo tcpdump -i h_aramis -w aramis_in.pcap
(...)
wireshark aramis_in.pcap
```

Stop and clean the topology when you're finished
```
cd demo/
./topology_cleanup.sh
```
