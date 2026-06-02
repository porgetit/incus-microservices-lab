# Incus Microservices Lab — Infraestructura y Guía de Instalación

Este README consolida la documentación técnica del proyecto (decisiones, diseño) y un manual de instalación paso a paso para quien prefiera realizar los pasos manualmente, sin usar los scripts automatizados.

**Estado:** Basado en Debian 13 (trixie). Red de laboratorio: `lab-net` (OVN) con subred `10.100.0.0/24`.

---

## Contenido

- **Contexto y decisión**: Por qué Debian 13 y topología general.
- **Requisitos previos**: Qué debe estar en el host.
- **Instalación manual (paso a paso)**: Instalar Incus, OVN/Open vSwitch, configurar puente y red OVN, crear perfiles, volúmenes y contenedores.
- **Uso de scripts existentes**: Resumen de `scripts/` y cómo ejecutarlos si prefieres automatizar.
- **Validación y recuperación**: Comandos para verificar y probar recuperabilidad.
- **Referencias y archivos relevantes**: enlaces a la documentación del repositorio.

---

## 1) Contexto y decisión resumida

- Objetivo: Laboratorio de microservicios con 6 nodos lógicos: `ctl` (control), `api`, `core`, `db`, `mon` (monitoring), `ceph`.
- Decisión: Uniformidad total con Debian 13 para reducir variables operativas y facilitar recuperación y debugging.
- Recursos objetivo (ejemplo): 16 CPUs, 33.4 GB RAM en host. Perfiles suman ~13 CPUs y 10 GiB RAM.

---

## 2) Requisitos del host

- Sistema operativo: Debian 13 (no aplicar en producción sin ajustes de seguridad).
- Acceso con usuario sudo.
- Conectividad Internet para descargar paquetes y repositorios.
- (Opcional) Acceso a GUI para `incus webui`.

---

## 3) Instalación manual (sin scripts)

Siga estos pasos en orden en el host Debian 13.

### 3.1 Actualizar el sistema

```bash
sudo apt update && sudo apt upgrade -y
```

### 3.2 Instalar dependencias de red (Open vSwitch + OVN)

```bash
sudo apt install -y openvswitch-switch ovn-central ovn-host
```

### 3.3 Añadir el repositorio de Zabbly e instalar Incus (si se usa)

```bash
sudo mkdir -p /etc/apt/keyrings/
sudo curl -fsSL https://pkgs.zabbly.com/key.asc -o /etc/apt/keyrings/zabbly.asc
sudo sh -c 'cat <<EOF > /etc/apt/sources.list.d/zabbly-incus-stable.sources
Enabled: yes
Types: deb
URIs: https://pkgs.zabbly.com/incus/stable
Suites: $(. /etc/os-release && echo ${VERSION_CODENAME})
Components: main
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/zabbly.asc

EOF'

sudo apt update
sudo apt install -y incus incus-client incus-ui-canonical
```

Nota: el repositorio y paquetes se usan en los scripts (`scripts/incusinstall.sh`). Si prefieres instalar desde repos oficiales o paquetes locales, ajusta los pasos.

### 3.4 Inicializar Incus

```bash
sudo incus admin init --minimal
sudo systemctl disable incus
```

(Se deshabilita auto-start por defecto en los scripts; ajusta según tu requerimiento.)

### 3.5 Configurar Open vSwitch y conectar OVN a Incus

```bash
sudo ovs-vsctl set open_vswitch . \
  external_ids:ovn-remote=unix:/run/ovn/ovnsb_db.sock \
  external_ids:ovn-encap-type=geneve \
  external_ids:ovn-encap-ip=127.0.0.1

sudo incus config set network.ovn.northbound_connection unix:/run/ovn/ovnnb_db.sock
```

### 3.6 Preparar puente `incusbr0` como uplink

- Si ya existe y no está gestionado por Incus, recrearlo como gestionado.
- Asignar rangos DHCP y OVN (evitar solapamientos).

```bash
# ejemplo de creación gestionada por Incus (si hace falta)
sudo incus network create incusbr0 \
  ipv4.address=10.158.133.1/24 ipv4.nat=true ipv6.address=none

# establecer rangos (ajustar base a la IP de tu bridge)
sudo incus network set incusbr0 \
  ipv4.dhcp.ranges=10.10.0.2-10.10.0.200 \
  ipv4.ovn.ranges=10.10.0.201-10.10.0.250

# agregar route para la subred del laboratorio (si ipv4.nat=false en lab-net)
sudo incus network set incusbr0 ipv4.routes=10.100.0.0/24
```

### 3.7 Crear la red OVN `lab-net`

```bash
sudo incus network create lab-net \
  --type=ovn \
  network=incusbr0 \
  ipv4.address=10.100.0.1/24 \
  ipv4.nat=false
```

(En los scripts actuales `scripts/network.sh` crea `lab-net` con `ipv4.nat=true` por defecto; revisa ese script si quieres NAT activo.)

### 3.8 Crear perfiles de recursos

Ejemplo rápido (basado en `scripts/profiles.sh`):

```bash
sudo incus profile create ctl
sudo incus profile set ctl limits.cpu=1 limits.memory=512MiB
sudo incus profile device add ctl root disk pool=default path=/

sudo incus profile create api
sudo incus profile set api limits.cpu=2 limits.memory=1024MiB
sudo incus profile device add api root disk pool=default path=/

# repetir para core, db, mon, ceph según el archivo profiles.sh
```

O ejecuta `bash scripts/profiles.sh` para automatizar.

### 3.9 Crear volúmenes persistentes

```bash
sudo incus storage volume create default postgres-data
sudo incus storage volume create default prometheus-data
sudo incus storage volume create default grafana-data
sudo incus storage volume create default ceph-data
sudo incus storage volume create default app-data
```

(O usa `bash scripts/volumes.sh`.)

### 3.10 Lanzar contenedores y adjuntar volúmenes

Los nombres de contenedores y la lógica están en `scripts/containers.sh`. Ejemplos manuales:

```bash
sudo incus launch images:debian/13 ctl -p ctl -p default -n lab-net
sudo incus launch images:debian/13 api -p api -p default -n lab-net
sudo incus config device add api app-volume disk pool=default source=app-data path=/app/data
# repetir para core, db, mon, ceph usando los nombres y volúmenes correspondientes
```

O usa `bash scripts/containers.sh` para automatizar (el script evita recrear contenedores ya existentes y comprueba existencia de volúmenes).

---

## 4) Uso de los scripts existentes

Resumen rápido de `scripts/`:

- `scripts/incusinstall.sh`: Añade repo Zabbly, instala Incus y dependencias (OVS/OVN), inicializa Incus y llama a `setup-lab.sh`.
- `scripts/network.sh`: Gestiona `incusbr0`, configura OVS/OVN, enlaza Incus a OVN y crea `lab-net`.
- `scripts/profiles.sh`: Crea perfiles `ctl`, `api`, `core`, `db`, `mon`, `ceph` y añade dispositivo `root` a cada perfil.
- `scripts/volumes.sh`: Crea volúmenes persistentes: `postgres-data`, `prometheus-data`, `grafana-data`, `ceph-data`, `app-data`.
- `scripts/containers.sh`: Lanza contenedores `ctl`, `api`, `core`, `db`, `mon`, `ceph`, y adjunta volúmenes si existen.
- `scripts/setup-lab.sh`: Orquesta `network.sh`, `profiles.sh`, `volumes.sh`, `containers.sh` y `validate.sh`.
- `scripts/validate.sh`: Comprueba existencia de red, perfiles, volúmenes, contenedores y conectividad básica.

Para ejecutar todo automatizado (en orden) desde la raíz del repo:

```bash
sudo chmod +x scripts/incusinstall.sh
bash scripts/incusinstall.sh
```

O para ejecutar etapas por separado:

```bash
bash scripts/network.sh
bash scripts/profiles.sh
bash scripts/volumes.sh
bash scripts/containers.sh
bash scripts/validate.sh
```

---

## 5) Validación y pruebas de recuperabilidad

Comandos útiles:

```bash
# Ver redes
incus network list
incus network show lab-net

# Ver perfiles
incus profile list
incus profile show api

# Ver volúmenes
incus storage volume list

# Ver contenedores
incus list
incus info db

# Test de conectividad desde dentro de un contenedor
incus exec ctl -- ping -c 1 api

# Recuperabilidad: destruir y recrear monitoring y verificar datos
incus delete mon --force
incus launch images:debian/13 mon -p mon -p default -n lab-net
incus config device add mon prometheus-volume disk pool=default source=prometheus-data path=/prometheus
incus exec mon -- ls -la /prometheus
```

Si `scripts/validate.sh` reporta fallos, revisa logs del host (`journalctl -u ovn*`, `journalctl -u openvswitch*`, `journalctl -u incus`) y luego ejecuta `bash scripts/shutdown.sh` para un apagado ordenado.

---

## 6) Troubleshooting rápido

- Si `incus network show incusbr0` devuelve `managed: false`: recrea el bridge gestionado por Incus o usa `scripts/network.sh` que hace ese paso automáticamente.
- Si falta volumen al ejecutar `scripts/containers.sh`: crea el volumen manualmente o re-ejecuta `scripts/volumes.sh`.
- Si OVN no conecta: comprueba que los sockets `/run/ovn/ovnsb_db.sock` y `/run/ovn/ovnnb_db.sock` existen y que los servicios OVN están activos.

---

## 7) Archivos relevantes

- [AGENTS.md](AGENTS.md) — historial de decisiones y contexto para agentes (fusionado con `choices.md` y `memory.md`).
- [infraestructura.md](infraestructura.md) — documento de decisión técnica (también incorporado aquí parcialmente).
- `scripts/` — carpeta con scripts de instalación y configuración (ver resumen arriba).

---

## 8) Notas finales y recomendaciones

- Mantén `AGENTS.md` y este `README.md` como fuentes de verdad para agentes y humanos.
- Si prefieres reproducir con IaC, continúa la integración con OpenTofu/Terraform (hay ejemplos en `infraestructura.md`).
- ¿Quieres que archive o elimine las versiones antiguas (`choices.md`, `memory.md`, `incussetup.md`, `setupnetwork.md`)? Puedo: (a) dejarlas, (b) moverlas a `archive/`, o (c) eliminarlas.

---

*Creado automáticamente por el agente el 02 June 2026 — consolidación de `incussetup.md`, `infraestructura.md` y `setupnetwork.md` y revisión de `scripts/`.*
