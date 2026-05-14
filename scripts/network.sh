#!/bin/bash
# network.sh - Corrección para manejo de incusbr0

set -e

echo "Verificando estado de incusbr0..."
MANAGED=$(sudo incus network show incusbr0 | grep -E '^\s*managed:' | awk '{print $2}')

if [ "$MANAGED" = "false" ]; then
    echo "⚠️  incusbr0 existe pero NO es gestionado por Incus"
    echo "Eliminando puente no gestionado..."
    sudo ip link set incusbr0 down
    sudo ip link delete incusbr0
    
    echo "Recreando incusbr0 como red gestionada por Incus..."
    sudo incus network create incusbr0 \
        ipv4.address=10.158.133.1/24 \
        ipv4.nat=true \
        ipv6.address=none
    echo "✅ incusbr0 recreado como red gestionada"
else
    echo "✅ incusbr0 ya es una red gestionada"
fi

echo "Configurando Open vSwitch para OVN..."
sudo ovs-vsctl set open_vswitch . \
  external_ids:ovn-remote=unix:/run/ovn/ovnsb_db.sock \
  external_ids:ovn-encap-type=geneve \
  external_ids:ovn-encap-ip=127.0.0.1
echo "✅ Open vSwitch configurado"

echo "Conectando Incus a OVN..."
sudo incus config set network.ovn.northbound_connection unix:/run/ovn/ovnnb_db.sock
echo "✅ Incus conectado a OVN"

echo "Preparando incusbr0 como uplink..."
BRIDGE_IP=$(sudo incus network show incusbr0 | grep "ipv4.address" | awk '{print $2}' | cut -d'/' -f1)
BASE=$(echo $BRIDGE_IP | cut -d'.' -f1-3)
DHCP_RANGES="${BASE}.2-${BASE}.200"
OVN_RANGES="${BASE}.201-${BASE}.250"

sudo incus network set incusbr0 \
  ipv4.dhcp.ranges=$DHCP_RANGES \
  ipv4.ovn.ranges=$OVN_RANGES
sudo incus network set incusbr0 ipv4.routes=10.100.0.0/24
echo "✅ incusbr0 preparado como uplink"

echo "Creando red OVN para el laboratorio..."
sudo incus network create lab-net \
  --type=ovn \
  network=incusbr0 \
  ipv4.address=10.100.0.1/24 \
  ipv4.nat=false
echo "✅ Red 'lab-net' creada"