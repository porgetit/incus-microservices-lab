#!/bin/bash

PASS=0
FAIL=0

echo "Validating Incus Lab Infrastructure..."
echo ""

sudo incus network show incusbr0 >/dev/null 2>&1 && echo "OK: incusbr0 exists" && ((PASS++)) || echo "FAIL: incusbr0" && ((FAIL++))
sudo incus network show lab-net >/dev/null 2>&1 && echo "OK: lab-net OVN" && ((PASS++)) || echo "FAIL: lab-net" && ((FAIL++))

sudo incus profile show ctl >/dev/null 2>&1 && echo "OK: Profile ctl" && ((PASS++)) || echo "FAIL: Profile ctl" && ((FAIL++))
sudo incus profile show api >/dev/null 2>&1 && echo "OK: Profile api" && ((PASS++)) || echo "FAIL: Profile api" && ((FAIL++))
sudo incus profile show core >/dev/null 2>&1 && echo "OK: Profile core" && ((PASS++)) || echo "FAIL: Profile core" && ((FAIL++))
sudo incus profile show db >/dev/null 2>&1 && echo "OK: Profile db" && ((PASS++)) || echo "FAIL: Profile db" && ((FAIL++))
sudo incus profile show mon >/dev/null 2>&1 && echo "OK: Profile mon" && ((PASS++)) || echo "FAIL: Profile mon" && ((FAIL++))
sudo incus profile show ceph >/dev/null 2>&1 && echo "OK: Profile ceph" && ((PASS++)) || echo "FAIL: Profile ceph" && ((FAIL++))

sudo incus storage volume show default postgres-data >/dev/null 2>&1 && echo "OK: Volume postgres-data" && ((PASS++)) || echo "FAIL: Volume postgres-data" && ((FAIL++))
sudo incus storage volume show default prometheus-data >/dev/null 2>&1 && echo "OK: Volume prometheus-data" && ((PASS++)) || echo "FAIL: Volume prometheus-data" && ((FAIL++))
sudo incus storage volume show default grafana-data >/dev/null 2>&1 && echo "OK: Volume grafana-data" && ((PASS++)) || echo "FAIL: Volume grafana-data" && ((FAIL++))
sudo incus storage volume show default ceph-data >/dev/null 2>&1 && echo "OK: Volume ceph-data" && ((PASS++)) || echo "FAIL: Volume ceph-data" && ((FAIL++))
sudo incus storage volume show default app-data >/dev/null 2>&1 && echo "OK: Volume app-data" && ((PASS++)) || echo "FAIL: Volume app-data" && ((FAIL++))

sudo incus info ctl | grep -q RUNNING && echo "OK: Container ctl RUNNING" && ((PASS++)) || echo "FAIL: Container ctl" && ((FAIL++))
sudo incus info api | grep -q RUNNING && echo "OK: Container api RUNNING" && ((PASS++)) || echo "FAIL: Container api" && ((FAIL++))
sudo incus info core | grep -q RUNNING && echo "OK: Container core RUNNING" && ((PASS++)) || echo "FAIL: Container core" && ((FAIL++))
sudo incus info db | grep -q RUNNING && echo "OK: Container db RUNNING" && ((PASS++)) || echo "FAIL: Container db" && ((FAIL++))
sudo incus info mon | grep -q RUNNING && echo "OK: Container mon RUNNING" && ((PASS++)) || echo "FAIL: Container mon" && ((FAIL++))
sudo incus info ceph | grep -q RUNNING && echo "OK: Container ceph RUNNING" && ((PASS++)) || echo "FAIL: Container ceph" && ((FAIL++))

sudo incus exec ctl -- ping -c 1 api >/dev/null 2>&1 && echo "OK: ctl -> api connectivity" && ((PASS++)) || echo "FAIL: ctl -> api" && ((FAIL++))
sudo incus exec api -- ping -c 1 db >/dev/null 2>&1 && echo "OK: api -> db connectivity" && ((PASS++)) || echo "FAIL: api -> db" && ((FAIL++))
sudo incus exec db -- ping -c 1 mon >/dev/null 2>&1 && echo "OK: db -> mon connectivity" && ((PASS++)) || echo "FAIL: db -> mon" && ((FAIL++))

echo ""
echo "Results: $PASS passed, $FAIL failed"

[ $FAIL -eq 0 ] && echo "Infrastructure OK" && exit 0 || echo "Infrastructure has issues" && exit 1