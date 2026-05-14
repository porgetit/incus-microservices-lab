#!/bin/bash
# network.sh - Script to set up OVN and create the network for the Incus lab

set -e  # Exit on any error

echo "Configuring Open vSwitch for OVN..."
sudo ovs-vsctl set open_vswitch . \
  external_ids:ovn-remote=unix:/run/ovn/ovnsb_db.sock \
  external_ids:ovn-encap-type=geneve \
  external_ids:ovn-encap-ip=127.0.0.1
echo "✅ Open vSwitch configured"

echo "Connecting Incus to OVN..."
sudo incus config set network.ovn.northbound_connection unix:/run/ovn/ovnnb_db.sock
echo "✅ Incus connected to OVN"

echo "Preparing incusbr0 as uplink..."
BRIDGE_IP=$(sudo incus network show incusbr0 | grep ipv4.address | awk '{print $2}' | cut -d'/' -f1)
BASE=$(echo $BRIDGE_IP | cut -d'.' -f1-3)
DHCP_RANGES="${BASE}.2-${BASE}.200"
OVN_RANGES="${BASE}.201-${BASE}.250"
sudo incus network set incusbr0 \
  ipv4.dhcp.ranges=$DHCP_RANGES \
  ipv4.ovn.ranges=$OVN_RANGES
sudo incus network set incusbr0 ipv4.routes=10.100.0.0/24
echo "✅ incusbr0 prepared as uplink with dynamic ranges"

echo "Creating OVN network for the lab..."
sudo incus network create lab-net \
  --type=ovn \
  network=incusbr0 \
  ipv4.address=10.100.0.1/24 \
  ipv4.nat=false
echo "✅ Network 'lab-net' created"