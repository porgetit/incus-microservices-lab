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
│   └── setup-lab.sh            # Full infrastructure deployment
└── choices.md                  # This file (changes log)
```

### Infrastructure Components
- **Profiles**: ctl (1 CPU, 512 MiB), api (2 CPU, 1 GiB), core (2 CPU, 1.5 GiB), db (4 CPU, 4 GiB), mon (2 CPU, 1 GiB), ceph (2 CPU, 2 GiB)
- **Network**: OVN network `lab-net` (10.10.0.0/24)
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

### May 13, 2026 | Created instructions.md for workspace rules | instructions.md | Establish guidelines for consistency and traceability.

### May 13, 2026 | Created .github/instructions/instructions.instructions.md | .github/instructions/instructions.instructions.md | Proper VS Code agent instructions file with extracted rules from conversation.

**Log Format**: Date | Change Description | Files Affected | Rationale