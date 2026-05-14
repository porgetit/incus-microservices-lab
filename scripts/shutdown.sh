#!/bin/bash

echo "Shutting down lab..."
echo ""

sudo incus stop api 2>/dev/null && echo "OK: api stopped" || echo "FAIL: api"
sudo incus stop core 2>/dev/null && echo "OK: core stopped" || echo "FAIL: core"
#sleep 2

sudo incus stop mon 2>/dev/null && echo "OK: mon stopped" || echo "FAIL: mon"
#sleep 2

sudo incus stop ceph 2>/dev/null && echo "OK: ceph stopped" || echo "FAIL: ceph"
#sleep 2

sudo incus stop db 2>/dev/null && echo "OK: db stopped" || echo "FAIL: db"
#sleep 3

sudo incus stop ctl 2>/dev/null && echo "OK: ctl stopped" || echo "FAIL: ctl"

sudo systemctl stop incus && sudo systemctl stop incus.socket

echo ""
echo "Lab shutdown complete"