# MEMORY.md - Decision and Context Log

Este archivo documenta las decisiones tomadas por los agentes y humanos en este repositorio, siguiendo la regla global definida para el proyecto.

## Análisis Inicial del Repositorio (13 de Mayo, 2026)

### Propósito del Proyecto

Laboratorio de microservicios basado en contenedores **Incus** sobre **Debian 13 (Trixie)** para una plataforma de gestión de reservas.

### Estructura de Componentes

- **Orquestación:** Contenedor `ctl` (control) para OpenTofu/Ansible.
- **Aplicación:** `api` (entrada REST) y `core` (lógica de negocio).
- **Persistencia:** `db` con PostgreSQL y volúmenes persistentes.
- **Observabilidad:** `mon` con Prometheus y Grafana.
- **Almacenamiento:** `ceph` para almacenamiento distribuido.

### Infraestructura de Red

- Uso de **OVN (Open Virtual Network)** para aislamiento.
- Red `lab-net` (10.100.0.0/24) sin NAT, ruteada a través de `incusbr0`.

### Automatización Actual

- `scripts/incusinstall.sh`: Instalación de Incus desde repositorios de Zabbly.
- `scripts/profiles.sh`: Configuración de límites de recursos (CPU/RAM).
- `scripts/network.sh`: Configuración de OVN e infraestructura de red.
- `scripts/volumes.sh`: Creación de almacenamiento persistente.
- `scripts/containers.sh`: Despliegue de contenedores Debian 13.
- `scripts/setup-lab.sh`: Orquestador principal de la infraestructura.

### Documentación de Referencia

- `infraestructura.md`: Justificación técnica de la elección de Debian 13 y diseño de recursos.
- `choices.md`: Log de cambios técnicos y estado del despliegue.
- `setupnetwork.md`: Guía de resolución de problemas y configuración de OVN.

---

## Log de Decisiones

### 13 de Mayo, 2026 - Adquisición de Contexto Inicial

- **Decisión:** El agente Antigravity ha realizado una lectura exhaustiva de todos los archivos `.md` y `.sh` para comprender el estado actual del proyecto.
- **Razón:** Necesario para cumplir con la solicitud del usuario de "adquirir contexto" y poder asistir en las siguientes fases (Ansible, validación, etc.).
- **Resultado:** Se ha identificado que la infraestructura base está mayormente automatizada y el siguiente paso lógico es la configuración de servicios internos y la validación de estabilidad.

---
