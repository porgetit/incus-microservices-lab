
# Incus Setup and Profile Management

## Overview

This document consolidates the installation steps for Incus on Debian over WSL 2 and details the `profiles.sh` script for creating resource-limited profiles in the microservices lab infrastructure.

## Incus Installation Guide

### Environment

- **OS**: Debian over WSL 2 on Windows 11

### WSL 2 Setup

```bash
wsl --install Debian --web-download -n
wsl -d Debian
```

### Debian Setup Steps

1. Update package lists:

   ```bash
   sudo apt update
   ```

2. Install Incus following [Zabbly's guide](https://github.com/zabbly/incus?tab=readme-ov-file#installation).

3. Check Incus daemon status:

   ```bash
   sudo systemctl status incus
   ```

   (Should show exists but disabled.)

4. Initialize Incus:

   ```bash
   sudo incus admin init --minimal
   ```

5. Disable auto-start:

   ```bash
   sudo systemctl disable incus
   ```

6. Launch web UI:

   ```bash
   sudo incus webui
   ```

   (Opens browser link for management.)

## Profile Management with profiles.sh

### Purpose

The `profiles.sh` Bash script automates the creation of Incus profiles with predefined CPU and memory limits for each node in the microservices lab, ensuring consistent resource allocation and isolation.

### Usage

- Execute from project root: `bash scripts/profiles.sh`
- Requires sudo for Incus commands (usable by non-root users with privileges)
- Verbose output with echo statements for each step
- Lists all profiles at the end for verification

### Profiles Created

| Profile      | CPUs | Memory   | Purpose                  |
|--------------|------|----------|--------------------------|
| node-control | 1    | 512 MiB | Orchestration (OpenTofu, Ansible) |
| app-api      | 2    | 1024 MiB| REST API entry point     |
| app-core     | 2    | 1536 MiB| Business logic processing|
| db-postgres  | 4    | 4096 MiB| PostgreSQL database      |
| monitoring   | 2    | 1024 MiB| Prometheus + Grafana     |
| ceph-node    | 2    | 2048 MiB| Distributed storage      |

### Benefits

- Automates profile setup from infrastructure documentation
- Ensures resource limits match hardware constraints (16 CPUs, 33.4 GB RAM)
- Provides 3 CPU and 23.4 GB RAM margin for stability
- Facilitates reproducible deployments
