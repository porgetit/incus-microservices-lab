#!/bin/bash
# containers.sh - Script to launch and configure containers for the Incus lab

set -e  # Exit on any error

echo "Launching and configuring containers..."

# Launch ctl
if ! incus info ctl >/dev/null 2>&1; then
    sudo incus launch images:debian/13 ctl -p ctl -p default -n lab-net
    echo "✅ ctl launched"
else
    echo "⚠️ ctl already exists, skipping"
fi

# Launch api with app-data volume
if ! incus info api >/dev/null 2>&1; then
    sudo incus launch images:debian/13 api -p api -p default -n lab-net
    if incus storage volume show default app-data >/dev/null 2>&1; then
        sudo incus config device add api app-volume disk source=default/app-data path=/app/data
        echo "✅ api launched and volume attached"
    else
        echo "⚠️ Volume app-data not found, api launched without volume"
    fi
else
    echo "⚠️ api already exists, skipping"
fi

# Launch core with app-data volume
if ! incus info core >/dev/null 2>&1; then
    sudo incus launch images:debian/13 core -p core -p default -n lab-net
    if incus storage volume show default app-data >/dev/null 2>&1; then
        sudo incus config device add core app-volume disk source=default/app-data path=/app/data
        echo "✅ core launched and volume attached"
    else
        echo "⚠️ Volume app-data not found, core launched without volume"
    fi
else
    echo "⚠️ core already exists, skipping"
fi

# Launch db with postgres-data volume
if ! incus info db >/dev/null 2>&1; then
    sudo incus launch images:debian/13 db -p db -p default -n lab-net
    if incus storage volume show default postgres-data >/dev/null 2>&1; then
        sudo incus config device add db postgres-volume disk source=default/postgres-data path=/var/lib/postgresql
        echo "✅ db launched and volume attached"
    else
        echo "⚠️ Volume postgres-data not found, db launched without volume"
    fi
else
    echo "⚠️ db already exists, skipping"
fi

# Launch mon with prometheus-data and grafana-data volumes
if ! incus info mon >/dev/null 2>&1; then
    sudo incus launch images:debian/13 mon -p mon -p default -n lab-net
    if incus storage volume show default prometheus-data >/dev/null 2>&1; then
        sudo incus config device add mon prometheus-volume disk source=default/prometheus-data path=/prometheus
    else
        echo "⚠️ Volume prometheus-data not found"
    fi
    if incus storage volume show default grafana-data >/dev/null 2>&1; then
        sudo incus config device add mon grafana-volume disk source=default/grafana-data path=/var/lib/grafana
    else
        echo "⚠️ Volume grafana-data not found"
    fi
    echo "✅ mon launched and volumes attached"
else
    echo "⚠️ mon already exists, skipping"
fi

# Launch ceph with ceph-data volume
if ! incus info ceph >/dev/null 2>&1; then
    sudo incus launch images:debian/13 ceph -p ceph -p default -n lab-net
    if incus storage volume show default ceph-data >/dev/null 2>&1; then
        sudo incus config device add ceph ceph-volume disk source=default/ceph-data path=/var/lib/ceph
        echo "✅ ceph launched and volume attached"
    else
        echo "⚠️ Volume ceph-data not found, ceph launched without volume"
    fi
else
    echo "⚠️ ceph already exists, skipping"
fi

echo "✅ All containers launched and configured"