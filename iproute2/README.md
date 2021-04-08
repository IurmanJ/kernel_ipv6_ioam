# IOAM patch for iproute2

This patchset provides support for IOAM inside iproute2, both for the configuration of IOAM namespaces/schemas as well as for the IOAM insertion attached to a route prefix.

```bash
$ ip ioam
Usage:	ip ioam { COMMAND | help }
	ip ioam namespace show
	ip ioam namespace add ID [ DATA ]
	ip ioam namespace del ID
	ip ioam schema show
	ip ioam schema add ID DATA
	ip ioam schema del ID
	ip ioam namespace set ID schema { ID | none }
```

```bash
$ ip -6 ro ad db02::/64 encap ioam6 trace type 0x800000 ns 1 size 12 dev eth0
```

