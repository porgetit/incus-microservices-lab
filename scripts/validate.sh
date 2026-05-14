#!/bin/bash

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

PASS=0
FAIL=0

check() {
    if eval "$1" >/dev/null 2>&1; then
        echo -e "${GREEN}✅${NC} $2"
        ((PASS++))
    else
        echo -e "${RED}❌${NC} $2"
        ((FAIL++))
    fi
}

echo "Validating Incus Lab Infrastructure..."
echo ""

# Networks
check "sudo incus network show incusbr0" "incusbr0 exists"
check "sudo incus network show lab-net" "lab-net OVN network exists"

# Profiles
check "sudo incus profile show ctl" "Profile: ctl"
check "sudo incus profile show api" "Profile: api"
check "sudo incus profile show core" "Profile: core"
check "sudo incus profile show db" "Profile: db"
check "sudo incus profile show mon" "Profile: mon"
check "sudo incus profile show ceph" "Profile: ceph"

# Volumes
check "sudo incus storage volume show default postgres-data" "Volume: postgres-data"
check "sudo incus storage volume show default prometheus-data" "Volume: prometheus-data"
check "sudo incus storage volume show default grafana-data" "Volume: grafana-data"
check "sudo incus storage volume show default ceph-data" "Volume: ceph-data"
check "sudo incus storage volume show default app-data" "Volume: app-data"

# Containers running
check "sudo incus info ctl | grep -q RUNNING" "Container ctl RUNNING"
check "sudo incus info api | grep -q RUNNING" "Container api RUNNING"
check "sudo incus info core | grep -q RUNNING" "Container core RUNNING"
check "sudo incus info db | grep -q RUNNING" "Container db RUNNING"
check "sudo incus info mon | grep -q RUNNING" "Container mon RUNNING"
check "sudo incus info ceph | grep -q RUNNING" "Container ceph RUNNING"

# Container connectivity
check "sudo incus exec ctl -- ping -c 1 api >/dev/null 2>&1" "ctl → api connectivity"
check "sudo incus exec api -- ping -c 1 db >/dev/null 2>&1" "api → db connectivity"
check "sudo incus exec db -- ping -c 1 mon >/dev/null 2>&1" "db → mon connectivity"

echo ""
echo "=========================================="
echo "Results: ${GREEN}$PASS passed${NC}, ${RED}$FAIL failed${NC}"
echo "=========================================="

if [ $FAIL -eq 0 ]; then
    echo -e "${GREEN}✅ Infrastructure OK${NC}"
    exit 0
else
    echo -e "${RED}❌ Infrastructure has issues${NC}"
    exit 1
fi