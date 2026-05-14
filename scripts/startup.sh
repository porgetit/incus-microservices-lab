#!/bin/bash

echo "Starting up lab..."
echo ""

sudo systemctl start incus

sudo incus start ceph && echo "OK: ceph started" || echo "FAIL: ceph"
sleep 3

sudo incus start db && echo "OK: db started" || echo "FAIL: db"
sleep 5

sudo incus start mon && echo "OK: mon started" || echo "FAIL: mon"
sleep 2

sudo incus start core && echo "OK: core started" || echo "FAIL: core"
sleep 2

sudo incus start api && echo "OK: api started" || echo "FAIL: api"
sleep 2

sudo incus start ctl && echo "OK: ctl started" || echo "FAIL: ctl"

echo ""
echo "Lab startup complete"