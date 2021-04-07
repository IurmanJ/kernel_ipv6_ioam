# kernel_ipv6_ioam

Implementation of IOAM for IPv6 in the Linux Kernel, based on following drafts:
- [In-situ OAM IPv6 Options](https://tools.ietf.org/html/draft-ietf-ippm-ioam-ipv6-options-05) (version 05)
- [Data Fields for In-situ OAM](https://tools.ietf.org/html/draft-ietf-ippm-ioam-data-12) (version 12)

### Patching the kernel

This patchset has been submitted to the [Netdev mailing list](https://lore.kernel.org/netdev/20210401182338.24077-1-justin.iurman@uliege.be/). It was developed based on the [net-next](https://git.kernel.org/pub/scm/linux/kernel/git/netdev/net-next.git) tree (v5.12-rc4) and is currently waiting for a review.

Before it gets officially merged, you'll need to download a recent version of the kernel and patch it manually with the provided patchset. You might need to apply some minor changes to the patchset depending on changes merged since then. If you want some help on how to patch and install a kernel or just want to see IOAM in action, please have a look at the [old branch](https://github.com/IurmanJ/kernel_ipv6_ioam/tree/old) where the principle remains the same.
