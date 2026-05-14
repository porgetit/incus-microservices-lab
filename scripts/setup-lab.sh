#!/bin/bash
# setup-lab.sh - High-level Incus Lab Setup Script
# This script automates the initial Incus infrastructure setup for the microservices lab.

set -e  # Exit on any error

echo "=========================================="
echo "  INCUS MICROSERVICES LAB SETUP"
echo "=========================================="
echo ""

# Step 1: Ensure profiles.sh has execute permissions and run it
echo "[1/5] Setting up Incus profiles..."
chmod +x scripts/profiles.sh
bash scripts/profiles.sh
echo "✅ Profiles created successfully"
echo ""

# Step 2: Ensure network.sh has execute permissions and run it
echo "[2/5] Creating OVN network for the lab..."
chmod +x scripts/network.sh
bash scripts/network.sh
echo ""

# Step 3: Ensure volumes.sh has execute permissions and run it
echo "[3/5] Creating persistent storage volumes..."
chmod +x scripts/volumes.sh
bash scripts/volumes.sh
echo ""

# Step 4: Ensure containers.sh has execute permissions and run it
echo "[4/5] Launching and configuring containers..."
chmod +x scripts/containers.sh
bash scripts/containers.sh
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