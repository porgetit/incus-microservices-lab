# Selección de Distribuciones Linux para la Plataforma de Gestión de Reservas sobre Incus

**Fecha:** Mayo 2026  
**Proyecto:** Plataforma de Gestión de Reservas - Laboratorio Académico sobre Incus  
**Criterio Principal:** Estabilidad máxima y recuperabilidad ante apagados/reinicios

---

## 1. Contexto y Requisitos

### Hardware Disponible
- **Procesador:** 16 CPUs
- **Memoria RAM:** 33.4 GB
- **Almacenamiento:** SSD (escritura activa: 567 KiB/s)
- **Host Físico:** Debian 13 (trixie)

### Nodos Lógicos del Proyecto
1. **node-control:** Orquestación y automatización (OpenTofu, Ansible)
2. **app-api:** Punto de entrada REST de la aplicación
3. **app-core:** Lógica de negocio y validaciones
4. **db-postgres:** Persistencia de datos (usuarios, recursos, reservas)
5. **monitoring:** Observabilidad (Prometheus + Grafana)
6. **ceph-node:** Almacenamiento distribuido

### Criterios de Decisión
- **Estabilidad:** Sistema debe poder apagarse y reiniciarse sin fallos inesperados
- **Reproducibilidad:** Infraestructura como código, sin intervención manual
- **Recuperabilidad:** Datos persistentes incluso si un contenedor se destruye
- **Escala Didáctica:** Bajo consumo de recursos, funcionamiento en hardware modesto
- **Soporte a Largo Plazo:** LTS o versiones estables con garantía de 5+ años

---

## 2. Opciones Evaluadas y Descartadas

### Opción 1: Uniformidad con Ubuntu 22.04 LTS
**Distribución:** Ubuntu 22.04 LTS (jammy) en todos los nodos  
**Ventajas:**
- LTS con soporte hasta 2027
- Comunidad grande, documentación abundante
- Incus disponible en repos oficiales

**Desventajas:**
- ❌ Host físico es Debian 13, no Ubuntu
- ❌ Fricción entre versiones: Ubuntu ≠ Debian en detalles de empaquetado
- ❌ Más superficie de incompatibilidades (librerías, kernels)
- ❌ Overhead innecesario en contenedores ligeros

**Veredicto:** Descartado por fricción entre host y contenedores.

---

### Opción 2: Especialización por Rol (Debian + Alpine + Ubuntu)
**Distribución:** Mezcla selectiva según nodo
- **node-control:** Debian 12 (herramientas CLI)
- **app-api, app-core:** Ubuntu 22.04 LTS (aplicación)
- **db-postgres:** Debian 12 slim (base de datos)
- **monitoring:** Ubuntu 22.04 LTS (Prometheus/Grafana)
- **ceph-node:** Alpine Linux 3.18 (almacenamiento ultraligero)

**Ventajas:**
- Optimización individual por rol
- Bajo consumo en algunos nodos

**Desventajas:**
- ❌ Múltiples sistemas de paquetes (apt, apk)
- ❌ Troubleshooting complejo (depende de qué distro sea)
- ❌ Fragmentación: si algo falla, ¿es por Alpine, Debian o Ubuntu?
- ❌ Violaría el principio "menos variables = más estable"
- ❌ Equipos académicos no tienen tiempo para debuguear 3 distros simultáneamente

**Veredicto:** Descartado por complejidad operacional y riesgo de cascadas de fallos.

---

### Opción 3: Uniformidad Total con Ubuntu 22.04 LTS
**Distribución:** Ubuntu 22.04 LTS en host + todos los contenedores  
**Ventajas:**
- Uniformidad total
- LTS robusto
- Comunidad grande

**Desventajas:**
- ❌ Requires instalar Ubuntu en host (costo de migración)
- ❌ Host ya corre Debian 13 exitosamente
- ❌ Cambio innecesario = riesgo innecesario

**Veredicto:** Descartado por cambio innecesario del host ya funcional.

---

## 3. Decisión Final: Uniformidad Total con Debian 13

### Selección Recomendada

| Nodo | Distribución | Versión | Justificación |
|------|--------------|---------|---------------|
| **Host Físico** | Debian 13 | trixie | Instalado, estable, soporte predecible |
| **node-control** | Debian 13 | trixie | Orquestación: OpenTofu, Ansible, SSH sin fricción |
| **app-api** | Debian 13 | trixie | API REST: misma base = menos sorpresas en librerías |
| **app-core** | Debian 13 | trixie | Lógica de negocio: idem anterior |
| **db-postgres** | Debian 13 slim | trixie | PostgreSQL idéntico, imagen ultraligera (base de datos = cero margen de error) |
| **monitoring** | Debian 13 | trixie | Prometheus + Grafana sin overhead |
| **ceph-node** | Debian 13 | trixie | Almacenamiento: Ceph en Debian = comportamiento predecible |

### Ventajas de esta Decisión

✅ **Un solo kernel, una sola libc, un solo ecosistema de paquetes**
- Troubleshooting directo: "no es un problema de versiones de libc"
- Actualizaciones de seguridad uniformes

✅ **Consistencia host → contenedores**
- El comportamiento de un servicio en el host es idéntico en un contenedor
- Facilita porting de configuración

✅ **Debian 13 es legendariamente estable en apagados/reinicios**
- Mecanismos de shutdown predecibles
- Fsck consistente
- Recuperación de servicios robusta

✅ **Menos variables operacionales**
- Mismo package manager (apt) en todos lados
- Mismas rutas de configuración (/etc/*)
- Mismos mecanismos de systemd

✅ **Bajo overhead: margen de seguridad amplío**
- 16 CPUs totales, 13 comprometidas = 3 libres
- 33.4 GB RAM, ~10 GB asignado = 23 GB libres
- No hay presión de recursos

✅ **Soporte a largo plazo predecible**
- Debian 13 mantiene LTS tácito en su ecosystem
- Críticas de seguridad publicadas rápidamente

---

## 4. Configuración de Perfiles Incus

### Perfiles de Límites de Recursos

```bash
# Perfil para node-control (orquestación, sin carga computacional)
incus profile create node-control
incus profile set node-control limits.cpu=1 limits.memory=512MiB

# Perfil para app-api (entrada REST, I/O bound)
incus profile create app-api
incus profile set app-api limits.cpu=2 limits.memory=1GiB

# Perfil para app-core (procesamiento de lógica, CPU bound)
incus profile create app-core
incus profile set app-core limits.cpu=2 limits.memory=1.5GiB

# Perfil para db-postgres (crítico, sin límites bruscos)
incus profile create db-postgres
incus profile set db-postgres limits.cpu=4 limits.memory=4GiB

# Perfil para monitoring (recolección de métricas, I/O bound)
incus profile create monitoring
incus profile set monitoring limits.cpu=2 limits.memory=1GiB

# Perfil para ceph-node (almacenamiento, I/O intensivo)
incus profile create ceph-node
incus profile set ceph-node limits.cpu=2 limits.memory=2GiB
```

### Cálculo de Recursos

| Nodo | CPUs | RAM | Total CPUs | Total RAM |
|------|------|-----|-----------|-----------|
| node-control | 1 | 512 MiB | 1 | 0.5 GiB |
| app-api | 2 | 1 GiB | 2 | 1 GiB |
| app-core | 2 | 1.5 GiB | 2 | 1.5 GiB |
| db-postgres | 4 | 4 GiB | 4 | 4 GiB |
| monitoring | 2 | 1 GiB | 2 | 1 GiB |
| ceph-node | 2 | 2 GiB | 2 | 2 GiB |
| **TOTAL** | **13** | **10 GiB** | **13** | **10 GiB** |
| **Disponible** | **16** | **33.4 GiB** | — | — |
| **Margen** | **3** | **23.4 GiB** | **Suficiente** | **Suficiente** |

---

## 5. Configuración de Volúmenes Persistentes

### Principio de Diseño

**Regla de Oro:** Si elimino un contenedor, sus datos persisten en el volumen.  
Si reinicio el host, todos los volúmenes reaparecen y los contenedores los reclaman.

### Creación de Volúmenes

```bash
# Volumen para datos de PostgreSQL (crítico)
incus storage volume create default postgres-data

# Volumen para datos de Prometheus (histórico de métricas)
incus storage volume create default prometheus-data

# Volumen para datos de Grafana (dashboards y configuraciones)
incus storage volume create default grafana-data

# Volumen para datos de Ceph (almacenamiento distribuido)
incus storage volume create default ceph-data

# Volumen compartido para la aplicación (usuarios, recursos, reservas)
incus storage volume create default app-data
```

### Montaje de Volúmenes en Contenedores

```bash
# PostgreSQL
incus config device add db-postgres postgres-volume disk \
  source=postgres-data path=/var/lib/postgresql

# Prometheus
incus config device add monitoring prometheus-volume disk \
  source=prometheus-data path=/prometheus

# Grafana
incus config device add monitoring grafana-volume disk \
  source=grafana-data path=/var/lib/grafana

# Ceph
incus config device add ceph-node ceph-volume disk \
  source=ceph-data path=/var/lib/ceph

# Aplicación (compartido entre app-api y app-core)
incus config device add app-api app-volume disk \
  source=app-data path=/app/data
incus config device add app-core app-volume disk \
  source=app-data path=/app/data
```

---

## 6. Procedimiento de Reproducción

### Paso 1: Preparación del Host (Debian 13)

```bash
# Actualizar sistema
sudo apt update && sudo apt upgrade -y

# Instalar Incus
sudo apt install incus incus-client -y

# Inicializar almacenamiento de Incus
sudo incus admin init

# Crear red OVN para el laboratorio
incus network create lab-net \
  --type=ovn \
  ipv4.address=10.10.0.1/24 \
  ipv4.nat=false

# Verificar red
incus network list
incus network show lab-net
```

### Paso 2: Crear Perfiles de Recursos

```bash
# Script: create-profiles.sh
#!/bin/bash

echo "Creando perfiles de Incus..."

incus profile create node-control
incus profile set node-control limits.cpu=1 limits.memory=512MiB

incus profile create app-api
incus profile set app-api limits.cpu=2 limits.memory=1GiB

incus profile create app-core
incus profile set app-core limits.cpu=2 limits.memory=1.5GiB

incus profile create db-postgres
incus profile set db-postgres limits.cpu=4 limits.memory=4GiB

incus profile create monitoring
incus profile set monitoring limits.cpu=2 limits.memory=1GiB

incus profile create ceph-node
incus profile set ceph-node limits.cpu=2 limits.memory=2GiB

echo "✅ Perfiles creados"
incus profile list
```

### Paso 3: Crear Volúmenes Persistentes

```bash
# Script: create-volumes.sh
#!/bin/bash

echo "Creando volúmenes persistentes..."

incus storage volume create default postgres-data
incus storage volume create default prometheus-data
incus storage volume create default grafana-data
incus storage volume create default ceph-data
incus storage volume create default app-data

echo "✅ Volúmenes creados"
incus storage volume list
```

### Paso 4: Provisionar Contenedores (OpenTofu)

```bash
# main.tf - Configuración OpenTofu para crear contenedores

terraform {
  required_providers {
    incus = {
      source = "lxc/incus"
    }
  }
}

provider "incus" {}

# Crear contenedor node-control
resource "incus_instance" "node_control" {
  name      = "node-control"
  image     = "debian/13"
  profiles  = ["node-control", "default"]
  
  device {
    name = "eth0"
    properties = {
      nictype = "bridged"
      parent  = "lab-net"
      type    = "nic"
    }
  }

  config = {
    "user.user-data" = file("${path.module}/cloud-init/node-control.yaml")
  }
}

# Crear contenedor app-api
resource "incus_instance" "app_api" {
  name      = "app-api"
  image     = "debian/13"
  profiles  = ["app-api", "default"]
  
  device {
    name = "eth0"
    properties = {
      nictype = "bridged"
      parent  = "lab-net"
      type    = "nic"
    }
  }

  device {
    name = "app-data"
    properties = {
      path   = "/app/data"
      source = "app-data"
      type   = "disk"
    }
  }
}

# Crear contenedor app-core
resource "incus_instance" "app_core" {
  name      = "app-core"
  image     = "debian/13"
  profiles  = ["app-core", "default"]
  
  device {
    name = "eth0"
    properties = {
      nictype = "bridged"
      parent  = "lab-net"
      type    = "nic"
    }
  }

  device {
    name = "app-data"
    properties = {
      path   = "/app/data"
      source = "app-data"
      type   = "disk"
    }
  }
}

# Crear contenedor db-postgres
resource "incus_instance" "db_postgres" {
  name      = "db-postgres"
  image     = "debian/13"
  profiles  = ["db-postgres", "default"]
  
  device {
    name = "eth0"
    properties = {
      nictype = "bridged"
      parent  = "lab-net"
      type    = "nic"
    }
  }

  device {
    name = "postgres-data"
    properties = {
      path   = "/var/lib/postgresql"
      source = "postgres-data"
      type   = "disk"
    }
  }
}

# Crear contenedor monitoring
resource "incus_instance" "monitoring" {
  name      = "monitoring"
  image     = "debian/13"
  profiles  = ["monitoring", "default"]
  
  device {
    name = "eth0"
    properties = {
      nictype = "bridged"
      parent  = "lab-net"
      type    = "nic"
    }
  }

  device {
    name = "prometheus-data"
    properties = {
      path   = "/prometheus"
      source = "prometheus-data"
      type   = "disk"
    }
  }

  device {
    name = "grafana-data"
    properties = {
      path   = "/var/lib/grafana"
      source = "grafana-data"
      type   = "disk"
    }
  }
}

# Crear contenedor ceph-node
resource "incus_instance" "ceph_node" {
  name      = "ceph-node"
  image     = "debian/13"
  profiles  = ["ceph-node", "default"]
  
  device {
    name = "eth0"
    properties = {
      nictype = "bridged"
      parent  = "lab-net"
      type    = "nic"
    }
  }

  device {
    name = "ceph-data"
    properties = {
      path   = "/var/lib/ceph"
      source = "ceph-data"
      type   = "disk"
    }
  }
}

output "node_control_ip" {
  value = incus_instance.node_control.ipv4_address
}

output "app_api_ip" {
  value = incus_instance.app_api.ipv4_address
}

output "app_core_ip" {
  value = incus_instance.app_core.ipv4_address
}

output "db_postgres_ip" {
  value = incus_instance.db_postgres.ipv4_address
}

output "monitoring_ip" {
  value = incus_instance.monitoring.ipv4_address
}

output "ceph_node_ip" {
  value = incus_instance.ceph_node.ipv4_address
}
```

### Paso 5: Configurar con Ansible

```yaml
# playbook.yml - Configuración de todos los nodos

---
- hosts: all
  become: true
  vars:
    apt_packages:
      - curl
      - wget
      - git
      - vim
      - net-tools
      - systemd-container

  tasks:
    - name: Actualizar repositorios
      apt:
        update_cache: yes
        cache_valid_time: 3600

    - name: Instalar paquetes base
      apt:
        name: "{{ apt_packages }}"
        state: present

    - name: Habilitar servicios críticos
      systemd:
        name: "{{ item }}"
        enabled: yes
        state: started
      loop:
        - systemd-networkd
        - systemd-resolved

- hosts: db-postgres
  become: true
  tasks:
    - name: Instalar PostgreSQL
      apt:
        name: postgresql-15
        state: present

    - name: Habilitar PostgreSQL
      systemd:
        name: postgresql
        enabled: yes
        state: started

- hosts: monitoring
  become: true
  tasks:
    - name: Crear usuario para Prometheus
      user:
        name: prometheus
        shell: /bin/false
        state: present

    - name: Descargar Prometheus
      get_url:
        url: https://github.com/prometheus/prometheus/releases/download/v2.45.0/prometheus-2.45.0.linux-amd64.tar.gz
        dest: /tmp/prometheus.tar.gz

    - name: Extraer Prometheus
      unarchive:
        src: /tmp/prometheus.tar.gz
        dest: /opt/
        remote_src: yes

    - name: Crear servicio Prometheus
      template:
        src: prometheus.service.j2
        dest: /etc/systemd/system/prometheus.service
      notify: restart prometheus

    - name: Habilitar Prometheus
      systemd:
        name: prometheus
        enabled: yes
        daemon_reload: yes
        state: started

    - name: Instalar Grafana
      apt:
        name: grafana
        state: present

    - name: Habilitar Grafana
      systemd:
        name: grafana-server
        enabled: yes
        state: started

  handlers:
    - name: restart prometheus
      systemd:
        name: prometheus
        state: restarted
```

### Paso 6: Validación de Estabilidad

```bash
# Script: validate-stability.sh
#!/bin/bash

echo "=== VALIDACIÓN DE ESTABILIDAD ==="

# 1. Listar todos los contenedores
echo "1. Estado de contenedores:"
incus list
echo ""

# 2. Verificar red
echo "2. Verificar conectividad de red:"
incus exec node-control -- ping -c 1 app-api
incus exec app-api -- ping -c 1 db-postgres
incus exec monitoring -- ping -c 1 app-core
echo ""

# 3. Verificar volúmenes
echo "3. Verificar volúmenes persistentes:"
incus storage volume list
echo ""

# 4. Verificar que PostgreSQL está corriendo
echo "4. Verificar PostgreSQL:"
incus exec db-postgres -- systemctl status postgresql
echo ""

# 5. Prueba de recuperabilidad
echo "5. Test de recuperabilidad (destruir y recrear monitoring):"
echo "  - Destruyendo monitoring..."
incus delete monitoring --force

echo "  - Recreando monitoring..."
incus launch debian:13 monitoring -p monitoring
incus config device add monitoring prometheus-data disk source=prometheus-data path=/prometheus

echo "  - Esperando boot..."
sleep 10

echo "  - Verificando que los datos persisten..."
incus exec monitoring -- ls -la /prometheus

echo ""
echo "✅ VALIDACIÓN COMPLETADA"
```

---

## 7. Procedimiento de Apagado Seguro

### Script: Apagado Ordenado

```bash
#!/bin/bash
# shutdown-lab.sh

set -e

echo "=========================================="
echo "  APAGADO ORDENADO DEL LABORATORIO"
echo "=========================================="
echo ""

# Fase 1: Detener servicios de aplicación
echo "[1/4] Deteniendo servicios de aplicación..."
incus stop app-api 2>/dev/null || echo "  ⚠️  app-api ya está detenido"
incus stop app-core 2>/dev/null || echo "  ⚠️  app-core ya está detenido"
sleep 3

# Fase 2: Detener monitoreo
echo "[2/4] Deteniendo monitoreo..."
incus stop monitoring 2>/dev/null || echo "  ⚠️  monitoring ya está detenido"
sleep 2

# Fase 3: Detener almacenamiento
echo "[3/4] Deteniendo almacenamiento..."
incus stop ceph-node 2>/dev/null || echo "  ⚠️  ceph-node ya está detenido"
sleep 2

# Fase 4: Detener base de datos (graceful shutdown)
echo "[4/4] Deteniendo base de datos..."
incus stop db-postgres 2>/dev/null || echo "  ⚠️  db-postgres ya está detenido"
sleep 5

# Control
echo "[5/5] Deteniendo control..."
incus stop node-control 2>/dev/null || echo "  ⚠️  node-control ya está detenido"

echo ""
echo "=========================================="
echo "✅ Apagado completado"
echo "=========================================="
echo ""
echo "Estado final:"
incus list
echo ""
echo "Es seguro apagar el host Debian 13."
```

### Script: Reinicio Ordenado

```bash
#!/bin/bash
# startup-lab.sh

set -e

echo "=========================================="
echo "  REINICIO DEL LABORATORIO"
echo "=========================================="
echo ""

# Fase 1: Arrancar almacenamiento
echo "[1/5] Arrancando almacenamiento..."
incus start ceph-node
sleep 5

# Fase 2: Arrancar base de datos
echo "[2/5] Arrancando base de datos..."
incus start db-postgres
sleep 10  # PostgreSQL necesita más tiempo

# Fase 3: Arrancar monitoreo
echo "[3/5] Arrancando monitoreo..."
incus start monitoring
sleep 5

# Fase 4: Arrancar servicios de aplicación
echo "[4/5] Arrancando servicios de aplicación..."
incus start app-core
sleep 3
incus start app-api
sleep 3

# Fase 5: Arrancar control
echo "[5/5] Arrancando control..."
incus start node-control

echo ""
echo "=========================================="
echo "✅ Reinicio completado"
echo "=========================================="
echo ""
echo "Validar conectividad:"
incus exec node-control -- curl -s http://app-api:5000/health || echo "⚠️  API aún no lista"
echo ""
```

---

## 8. Checklist de Implementación

- [ ] Host Debian 13 instalado y actualizado
- [ ] Incus instalado y inicializado
- [ ] Red OVN creada (`lab-net` con `10.10.0.0/24`)
- [ ] Todos los perfiles de límites de recursos creados
- [ ] Todos los volúmenes persistentes creados
- [ ] OpenTofu configurado y validado (`terraform plan`)
- [ ] Contenedores aprovisionados (`terraform apply`)
- [ ] Ansible playbooks ejecutados sin errores
- [ ] Prometheus recolectando métricas
- [ ] Grafana accesible y mostrando dashboards
- [ ] PostgreSQL respondiendo a conexiones
- [ ] Test de recuperabilidad completado (destruir/recrear contenedor)
- [ ] Script de apagado probado sin errores
- [ ] Script de reinicio probado sin errores
- [ ] Documentación de operación completada

---

## 9. Matriz de Decisión (Resumen)

| Criterio | Debian 13 Total | Ubuntu+Debian | Alpine+Debian | Descartado |
|----------|-----------------|---------------|---------------|-----------|
| Estabilidad | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐ | — |
| Consistencia Host-Contenedores | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐ | — |
| Overhead Operacional | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐ | — |
| Facilidad de Debugging | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐ | — |
| Soporte a Largo Plazo | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐ | — |
| Recuperabilidad | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐ | — |
| Margen de Recursos | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | — |
| **Puntuación Total** | **35/35** | **25/35** | **15/35** | — |

**Decisión Final:** Debian 13 en todos los nodos.

---

## 10. Referencias

- [Incus Documentation](https://linuxcontainers.org/incus/)
- [Debian 13 Release Notes](https://www.debian.org/releases/trixie/)
- [OpenTofu Provider for Incus](https://registry.terraform.io/providers/lxc/incus/latest/docs)
- [Ansible Documentation](https://docs.ansible.com/)
- [Prometheus Getting Started](https://prometheus.io/docs/prometheus/latest/getting_started/)
- [PostgreSQL Administration](https://www.postgresql.org/docs/15/admin.html)

---

**Documento de Decisión Técnica - Proyecto Incus 2026**  
*Estabilidad por Simplicidad y Uniformidad*
