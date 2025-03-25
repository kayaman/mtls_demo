#!/bin/bash

# If tcpdump is available in your environment:
kubectl exec $API_POD -- tcpdump -i any -w /tmp/capture.pcap port 3000
kubectl cp $API_POD:/tmp/capture.pcap ./capture.pcap

# Then analyze with Wireshark