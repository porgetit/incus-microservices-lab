#!/bin/bash
# volumes.sh - Script to create persistent storage volumes for the Incus lab

set -e  # Exit on any error

echo "Creating persistent storage volumes..."
sudo incus storage volume create default postgres-data
sudo incus storage volume create default prometheus-data
sudo incus storage volume create default grafana-data
sudo incus storage volume create default ceph-data
sudo incus storage volume create default app-data
echo "✅ All volumes created"