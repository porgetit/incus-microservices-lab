---
description: Instructions for the incus-microservices-lab workspace - Incus container management, microservices infrastructure, and IaC with OpenTofu/Ansible
applyTo: '**/*'  # Apply to all files in the workspace
---

# Incus Microservices Lab Instructions

## Project Context
This workspace manages a containerized microservices lab using Incus on Debian 13. The project includes infrastructure deployment scripts, IaC with OpenTofu, and service configuration with Ansible. Key components: 6 containers (ctl, api, core, db, mon, ceph) with resource profiles, OVN networking, and persistent volumes.

## Coding Guidelines
- **KISS Principle**: Keep solutions simple and stupid. Use concise naming (e.g., ctl instead of node-control).
- **File Organization**:
  - All scripts must be placed in the `scripts/` folder.
  - Documentation in root (e.g., choices.md for change logs).
- **Script Handling**: Never attempt to execute scripts. Provide them for manual execution.
- **Naming Conventions**:
  - Profiles/Containers: ctl, api, core, db, mon, ceph.
  - Files: Descriptive but short (e.g., setup-lab.sh).
- **Traceability**: Log every change in `choices.md` with format: `Date | Description | Files | Rationale`.
- **Language**: English for code/comments; Spanish allowed for detailed docs.
- **IaC Preference**: Use OpenTofu for automation, but allow manual scripts for testing/validation.

## Workflow Rules
1. Plan changes and log intent in `choices.md`.
2. Implement following guidelines.
3. Log completion immediately.
4. Ensure consistency with existing codebase.

## Specific Rules
- Infrastructure: Manual Incus commands in scripts, replace with OpenTofu later.
- Validation: Create scripts for testing stability and shutdown/startup.
- Documentation: `infraestructura.md` is source of truth for decisions.