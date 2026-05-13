#!/bin/bash

echo "Starting creation of Incus profiles..."

echo "Creating node-control profile..."
sudo incus profile create node-control
sudo incus profile set node-control limits.cpu=1 limits.memory=512MiB
echo "node-control profile created with limits.cpu=1 and limits.memory=512MiB"

echo "Creating app-api profile..."
sudo incus profile create app-api
sudo incus profile set app-api limits.cpu=2 limits.memory=1024MiB
echo "app-api profile created with limits.cpu=2 and limits.memory=1024MiB"

echo "Creating app-core profile..."
sudo incus profile create app-core
sudo incus profile set app-core limits.cpu=2 limits.memory=1536MiB
echo "app-core profile created with limits.cpu=2 and limits.memory=1536MiB"

echo "Creating db-postgres profile..."
sudo incus profile create db-postgres
sudo incus profile set db-postgres limits.cpu=4 limits.memory=4096MiB
echo "db-postgres profile created with limits.cpu=4 and limits.memory=4096MiB"

echo "Creating monitoring profile..."
sudo incus profile create monitoring
sudo incus profile set monitoring limits.cpu=2 limits.memory=1024MiB
echo "monitoring profile created with limits.cpu=2 and limits.memory=1024MiB"

echo "Creating ceph-node profile..."
sudo incus profile create ceph-node
sudo incus profile set ceph-node limits.cpu=2 limits.memory=2048MiB
echo "ceph-node profile created with limits.cpu=2 and limits.memory=2048MiB"

echo "All profiles have been created successfully."
echo "Listing all profiles:"
sudo incus profile list