#!/bin/bash
# setup-lab.sh - High-level Incus Lab Setup Script
# This script automates the initial Incus infrastructure setup for the microservices lab.

set -e  # Exit on any error

echo "=========================================="
echo "  INCUS MICROSERVICES LAB SETUP"
echo "=========================================="
echo ""

# Step 1: Ensure profiles.sh has execute permissions and run it
echo "[1/4] Setting up Incus profiles..."
chmod +x scripts/profiles.sh
bash scripts/profiles.sh
echo "✅ Profiles created successfully"
echo ""

# Step 2: Configure Incus network
echo "[2/4] Creating OVN network for the lab..."
sudo incus network create lab-net --type=ovn ipv4.address=10.10.0.1/24 ipv4.nat=false
echo "✅ Network 'lab-net' created"
echo ""

# Step 3: Create persistent volumes
echo "[3/4] Creating persistent storage volumes..."
sudo incus storage volume create default postgres-data
sudo incus storage volume create default prometheus-data
sudo incus storage volume create default grafana-data
sudo incus storage volume create default ceph-data
sudo incus storage volume create default app-data
echo "✅ All volumes created"
echo ""

# Step 4: Launch and configure containers manually
echo "[4/4] Launching and configuring containers..."
# Launch ctl
sudo incus launch debian:13 ctl -p ctl -n lab-net
echo "✅ ctl launched"

# Launch api with app-data volume
sudo incus launch debian:13 api -p api -n lab-net
sudo incus config device add api app-volume disk source=app-data path=/app/data
echo "✅ api launched and volume attached"

# Launch core with app-data volume
sudo incus launch debian:13 core -p core -n lab-net
sudo incus config device add core app-volume disk source=app-data path=/app/data
echo "✅ core launched and volume attached"

# Launch db with postgres-data volume
sudo incus launch debian:13 db -p db -n lab-net
sudo incus config device add db postgres-volume disk source=postgres-data path=/var/lib/postgresql
echo "✅ db launched and volume attached"

# Launch mon with prometheus-data and grafana-data volumes
sudo incus launch debian:13 mon -p mon -n lab-net
sudo incus config device add mon prometheus-volume disk source=prometheus-data path=/prometheus
sudo incus config device add mon grafana-volume disk source=grafana-data path=/var/lib/grafana
echo "✅ mon launched and volumes attached"

# Launch ceph with ceph-data volume
sudo incus launch debian:13 ceph -p ceph -n lab-net
sudo incus config device add ceph ceph-volume disk source=ceph-data path=/var/lib/ceph
echo "✅ ceph launched and volume attached"

echo "✅ All containers launched and configured"
echo ""

echo "=========================================="
echo "✅ INFRASTRUCTURE DEPLOYMENT COMPLETED"
echo "=========================================="
echo ""
echo "Containers are now running. Next steps:"
echo ""

# TODO: Step 5 - Configure services with Ansible
echo "# Configure services inside containers using Ansible"
echo "# Commands:"
echo "#   - Ensure Ansible is installed on host or node-control"
echo "#   - Create inventory file with container IPs"
echo "#   - Run ansible-playbook playbook.yml"
echo ""

# TODO: Step 6 - Validate deployment
echo "# Run validation script to check stability"
echo "# Commands:"
echo "#   - bash scripts/validate-stability.sh (create this script based on infraestructura.md)"
echo "#   - Test connectivity between containers"
echo "#   - Verify services are running"
echo ""

# TODO: Step 7 - Test shutdown and restart procedures
echo "# Test ordered shutdown and startup"
echo "# Commands:"
echo "#   - bash scripts/shutdown-lab.sh"
echo "#   - bash scripts/startup-lab.sh"
echo ""

echo "For detailed commands, refer to infraestructura.md"
echo "=========================================="