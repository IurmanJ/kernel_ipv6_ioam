# Cross Layer Telemetry

This project, based on IPv6 IOAM in the kernel, aims to make the entire stack (L2/L3 -> L7) visible for distributed tracing tools, thanks to a correlation in [Jaeger](https://www.jaegertracing.io) between span IDs carried by IOAM in the dataplane and [OpenTelemetry](https://opentelemetry.io) data.

Currently, only the span ID (*64 bits*) is carried by IOAM, right after the IOAM Trace Option Header. In the future, we plan to also carry the trace ID (*128 bits*) to avoid any collision.

![IOAM_Trace_Header_Span](./images/ioam_span_trace_option_header.png?raw=true "Location of an L7 span ID in the IOAM Trace option header")

### Patching the already-IOAM-patched-kernel

If you did **not** patch your kernel with IOAM yet, please follow [this section](https://github.com/IurmanJ/kernel_ipv6_ioam#patching-the-kernel).

For Cross Layer Telemetry, you also need to patch the IOAM kernel with this add-on patch (*ioam_span.patch*) and recompile.

### LXC Topology

This is the same topology as the main one. See [this section](https://github.com/IurmanJ/kernel_ipv6_ioam#lxc-topology) for more details.

![Topology](../lxc/topology.png?raw=true "Topology")

### Demo

Install OpenTelemetry API and SDK
```
pip3 install opentelemetry-api
pip3 install opentelemetry-sdk
```

Start the topology
```
cd ../lxc/
./start.sh
```

Open a shell and enter **Aramis**.
```
sudo lxc-attach -n aramis
```

From inside **Aramis**, start collecting traffic on ingress with *tcpdump* and launch the server.
```
sudo tcpdump -i h_aramis1 -w aramis.pcap &
./containers/aramis/server.py
```

Open another shell and enter **Athos**.
```
sudo lxc-attach -n athos
```

From inside **Athos**, start collecting traffic on egress with *tcpdump* and launch the client. The purpose of the client is to simulate three different HTTP requests on the same socket, each tagged with its specific L7 span ID obtained from OpenTelemetry. The client is written in *Python* and uses the *Python* API of OpenTelemetry.
```
sudo tcpdump -i h_athos2 -w athos.pcap &
./containers/athos/client.py
```

Compare the output of the client (Span IDs) with IOAM headers in both the client (*athos.pcap*) and the server (*aramis.pcap*). Here is an example:

![Client_Spans](./images/client_spans.png?raw=true "Span IDs on the client")
![Wireshark_Client_Server](./images/wireshark.png?raw=true "Comparison between IOAM headers on the client and on the server")

