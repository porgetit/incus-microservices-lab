#!/bin/bash

echo "Starting creation of Incus profiles..."

echo "Creating ctl profile..."
sudo incus profile create ctl
sudo incus profile set ctl limits.cpu=1 limits.memory=512MiB
sudo incus profile device add ctl root disk pool=default path=/
echo "ctl profile created with limits.cpu=1 and limits.memory=512MiB"

echo "Creating api profile..."
sudo incus profile create api
sudo incus profile set api limits.cpu=2 limits.memory=1024MiB
sudo incus profile device add api root disk pool=default path=/
echo "api profile created with limits.cpu=2 and limits.memory=1024MiB"

echo "Creating core profile..."
sudo incus profile create core
sudo incus profile set core limits.cpu=2 limits.memory=1536MiB
sudo incus profile device add core root disk pool=default path=/
echo "core profile created with limits.cpu=2 and limits.memory=1536MiB"

echo "Creating db profile..."
sudo incus profile create db
sudo incus profile set db limits.cpu=4 limits.memory=4096MiB
sudo incus profile device add db root disk pool=default path=/
echo "db profile created with limits.cpu=4 and limits.memory=4096MiB"

echo "Creating mon profile..."
sudo incus profile create mon
sudo incus profile set mon limits.cpu=2 limits.memory=1024MiB
sudo incus profile device add mon root disk pool=default path=/
echo "mon profile created with limits.cpu=2 and limits.memory=1024MiB"

echo "Creating ceph profile..."
sudo incus profile create ceph
sudo incus profile set ceph limits.cpu=2 limits.memory=2048MiB
sudo incus profile device add ceph root disk pool=default path=/
echo "ceph profile created with limits.cpu=2 and limits.memory=2048MiB"

echo "All profiles have been created successfully."
echo "Listing all profiles:"
sudo incus profile list