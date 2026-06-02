
# AGENTS.md — Combined Agent Context and Change History

This file consolidates the repository change history, decision log, and context intended for AI agents and collaborators. It merges the contents of `choices.md` and `memory.md` to provide a single source of truth for agent-driven automation, reasoning, and traceability.

---

## Project Context

This workspace manages a containerized microservices lab using Incus on Debian 13. The project includes infrastructure deployment scripts, IaC with OpenTofu (planned), and service configuration with Ansible (planned). Key components: 6 containers (`ctl`, `api`, `core`, `db`, `mon`, `ceph`) with resource profiles, OVN networking, and persistent volumes.

Core automation lives in the `scripts/` folder and includes installation, network setup, volumes, container launches, and a top-level orchestrator script.

Primary files and their purpose:

- `scripts/incusinstall.sh`: Install Incus and prerequisites.
- `scripts/profiles.sh`: Create resource profiles for containers.
- `scripts/network.sh`: Configure OVN and networking.
- `scripts/volumes.sh`: Create persistent volumes.
- `scripts/containers.sh`: Launch containers and attach volumes.
- `scripts/setup-lab.sh`: Orchestrates the full deployment by calling the above scripts.
- `infraestructura.md`: Technical justification and design decisions (Spanish).
- `choices.md`: Change log and decisions history (merged here).
- `memory.md`: Agent decision/context log (merged here).

---

## Deployment Status (snapshot)

- ✅ Incus installation and initialization
- ✅ Profiles created with resource limits
- ✅ OVN network configured
- ✅ Persistent volumes created
- ✅ Containers launched and configured
- 🔄 Service configuration (Ansible pending)
- 🔄 Validation scripts (pending)
- 🔄 OpenTofu IaC (pending)

---

## Choices and Changes Log (merged)

This section reproduces and preserves the change log originally stored in `choices.md`.

### Project Overview
- Purpose: Containerized microservices lab for a reservation management platform using Incus on Debian 13.
- Infrastructure: 6 containers (ctl, api, core, db, mon, ceph) with resource profiles, OVN network, and persistent volumes.
- Tools: Incus for containers, OpenTofu for IaC (planned), Ansible for configuration (planned).

### Files and Structure
```
incus-microservices-lab/
├── infraestructura.md          # Technical decision document (Spanish)
├── memory.md                   # Installation and profile guide (merged)
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
└── choices.md                  # Change log (merged here)
```

### Infrastructure Components
- Profiles: ctl (1 CPU, 512 MiB), api (2 CPU, 1 GiB), core (2 CPU, 1.5 GiB), db (4 CPU, 4 GiB), mon (2 CPU, 1 GiB), ceph (2 CPU, 2 GiB) — each with root disk from default pool
- Network: OVN network `lab-net` (10.100.0.0/24)
- Volumes: postgres-data, prometheus-data, grafana-data, ceph-data, app-data
- Containers: Launched via `setup-lab.sh` with volumes attached

### Changes Log (selected entries)

- May 13, 2026 | Added volume existence checks in `scripts/containers.sh` before adding devices | `scripts/containers.sh` | Prevent device validation errors by checking if storage volumes exist before attaching them.

- May 13, 2026 | Modified `containers.sh` to skip launching containers that already exist | `scripts/containers.sh` | Prevent script failure by checking container existence before launch and continuing with next.

- May 13, 2026 | Fixed volume source paths in `containers.sh` to use pool/volume format | `scripts/containers.sh` | Correct device validation errors by specifying default pool for volume sources.

- May 13, 2026 | Updated `containers.sh` to use correct launch syntax with images:debian/13 and -p default | `scripts/containers.sh` | Ensure containers launch with proper image source and default profile applied.

- May 13, 2026 | Added root disk device to all profiles in `profiles.sh` | `scripts/profiles.sh`, `choices.md` | Ensure profiles have root storage from default pool for proper container mounting.

- May 13, 2026 | Made `network.sh` dynamic to detect `incusbr0` subnet and set OVN/DHCP ranges | `scripts/network.sh` | Handle varying bridge subnets in Incus to prevent IP range parsing errors.

- May 13, 2026 | Updated `network.sh` with full OVN setup and changed lab-net to 10.100.0.0/24 | `scripts/network.sh`, `choices.md` | Properly configure OVN for Incus on Debian to prevent network creation failures, based on `setupnetwork.md`.

- May 13, 2026 | Restructured `setup-lab.sh` to call separate scripts for each stage | `scripts/setup-lab.sh`, `scripts/network.sh`, `scripts/volumes.sh`, `scripts/containers.sh` | Modularize setup process for easier debugging and maintenance.

- May 13, 2026 | Created `instructions.md` for workspace rules | `instructions.md` | Establish guidelines for consistency and traceability.

- May 13, 2026 | Created `.github/instructions/instructions.instructions.md` | `.github/instructions/instructions.instructions.md` | Proper VS Code agent instructions file with extracted rules from conversation.

---

## Agent Memory and Decision Log (merged)

This section reproduces the `memory.md` content capturing agent reasoning and earlier context.

### MEMO: Initial Repository Analysis (13 May, 2026)

Purpose: Laboratorio de microservicios basado en contenedores Incus sobre Debian 13 (Trixie) para una plataforma de gestión de reservas.

Structure summary:
- Orquestación: Contenedor `ctl` (control) para OpenTofu/Ansible.
- Aplicación: `api` (entrada REST) y `core` (lógica de negocio).
- Persistencia: `db` con PostgreSQL y volúmenes persistentes.
- Observabilidad: `mon` con Prometheus y Grafana.
- Almacenamiento: `ceph` para almacenamiento distribuido.

Network and automation notes:
- Uso de OVN (Open Virtual Network) para aislamiento.
- Red `lab-net` (10.100.0.0/24) sin NAT, ruteada a través de `incusbr0`.
- `scripts/incusinstall.sh`: Instalación de Incus desde repositorios de Zabbly.
- `scripts/profiles.sh`: Configuración de límites de recursos (CPU/RAM).
- `scripts/network.sh`: Configuración de OVN e infraestructura de red.
- `scripts/volumes.sh`: Creación de almacenamiento persistente.
- `scripts/containers.sh`: Despliegue de contenedores Debian 13.
- `scripts/setup-lab.sh`: Orquestador principal de la infraestructura.

Decision log snippet:

- 13 de Mayo, 2026 - Adquisición de Contexto Inicial
	- Decisión: El agente Antigravity realizó una lectura exhaustiva de todos los archivos `.md` y `.sh` para comprender el estado actual del proyecto.
	- Razón: Necesario para cumplir con la solicitud del usuario de "adquirir contexto" y poder asistir en las siguientes fases (Ansible, validación, etc.).
	- Resultado: Identificado que la infraestructura base está mayormente automatizada y el siguiente paso lógico es la configuración de servicios internos y la validación de estabilidad.

---

## Usage for AI Agents

Agents and automated workflows should consult this file first for project state, change history, and decision rationale. Suggested responsibilities for agents:

- Read the Deployment Status and Changes Log before modifying scripts.
- Append new change log entries here with Date | Description | Files | Rationale format.
- When proposing IaC changes, reference `infraestructura.md` for network and resource assumptions.
- Log all high-level decisions in `choices.md` only if a separate human-readable log is required; prefer updating this unified `AGENTS.md` for agent workflows.

---

## Sources and provenance

This file was generated by merging the previous `choices.md` and `memory.md` files on 02 June 2026. Original files remain in the repository for audit unless removed by the maintainers.

---

## Change record for this merge

- 02 June 2026 | Merged `choices.md` and `memory.md` into `AGENTS.md` to centralize agent context and history | `AGENTS.md` | Simplify agent access and maintain a single source of truth.
