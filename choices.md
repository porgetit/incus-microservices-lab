# Choices and Changes Log

This file documents the current state of the Incus microservices lab repository and logs all changes for traceability. Updates follow the KISS principle (Keep It Simple, Stupid) for simplicity and maintainability.

## Current Repository State (May 13, 2026)

### Project Overview
- **Purpose**: Containerized microservices lab for a reservation management platform using Incus on Debian 13.
- **Infrastructure**: 6 containers (ctl, api, core, db, mon, ceph) with resource profiles, OVN network, and persistent volumes.
- **Tools**: Incus for containers, OpenTofu for IaC (planned), Ansible for configuration (planned).

### Files and Structure
```
incus-microservices-lab/
├── infraestructura.md          # Technical decision document (Spanish)
├── memory.md                   # Installation and profile guide
├── install_log.txt             # Quick setup reference
├── Zabbly's readme.md          # Incus repository documentation
├── incusinstallation command.txt  # Single-line setup command
├── scripts/
│   ├── incusinstall.sh         # Automated Incus installation
│   ├── profiles.sh             # Profile creation (simplified names)
│   ├── network.sh              # OVN network creation
│   ├── volumes.sh              # Persistent volumes creation
│   ├── containers.sh           # Container launching and configuration
│   └── setup-lab.sh            # Full infrastructure deployment (calls other scripts)
└── choices.md                  # This file (changes log)
```

### Infrastructure Components
- **Profiles**: ctl (1 CPU, 512 MiB), api (2 CPU, 1 GiB), core (2 CPU, 1.5 GiB), db (4 CPU, 4 GiB), mon (2 CPU, 1 GiB), ceph (2 CPU, 2 GiB) - each with root disk from default pool
- **Network**: OVN network `lab-net` (10.100.0.0/24)
- **Volumes**: postgres-data, prometheus-data, grafana-data, ceph-data, app-data
- **Containers**: Launched manually in `setup-lab.sh` with volumes attached

### Deployment Status
- ✅ Incus installation and initialization
- ✅ Profiles created with resource limits
- ✅ OVN network configured
- ✅ Persistent volumes created
- ✅ Containers launched and configured
- 🔄 Service configuration (Ansible pending)
- 🔄 Validation scripts (pending)
- 🔄 OpenTofu IaC (pending)

## Changes Log

### May 13, 2026 | Added volume existence checks in containers.sh before adding devices | scripts/containers.sh | Prevent device validation errors by checking if storage volumes exist before attaching them.

### May 13, 2026 | Modified containers.sh to skip launching containers that already exist | scripts/containers.sh | Prevent script failure by checking container existence before launch and continuing with next.

### May 13, 2026 | Fixed volume source paths in containers.sh to use pool/volume format | scripts/containers.sh | Correct device validation errors by specifying default pool for volume sources.

### May 13, 2026 | Updated containers.sh to use correct launch syntax with images:debian/13 and -p default | scripts/containers.sh | Ensure containers launch with proper image source and default profile applied.

### May 13, 2026 | Added root disk device to all profiles in profiles.sh | scripts/profiles.sh, choices.md | Ensure profiles have root storage from default pool for proper container mounting.

### May 13, 2026 | Made network.sh dynamic to detect incusbr0 subnet and set OVN/DHCP ranges | scripts/network.sh | Handle varying bridge subnets in Incus to prevent IP range parsing errors.

### May 13, 2026 | Updated network.sh with full OVN setup and changed lab-net to 10.100.0.0/24 | scripts/network.sh, choices.md | Properly configure OVN for Incus on Debian to prevent network creation failures, based on setupnetwork.md.

### May 13, 2026 | Restructured setup-lab.sh to call separate scripts for each stage | scripts/setup-lab.sh, scripts/network.sh, scripts/volumes.sh, scripts/containers.sh | Modularize setup process for easier debugging and maintenance.

### May 13, 2026 | Created instructions.md for workspace rules | instructions.md | Establish guidelines for consistency and traceability.

### May 13, 2026 | Created .github/instructions/instructions.instructions.md | .github/instructions/instructions.instructions.md | Proper VS Code agent instructions file with extracted rules from conversation.

**Log Format**: Date | Change Description | Files Affected | Rationale