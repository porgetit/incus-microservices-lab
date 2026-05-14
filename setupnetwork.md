¡Claro que sí! Fue toda una aventura de diagnóstico cruzado, pero logramos domar a OVN. Para que te quede como "chuleta" o por si necesitas replicar este laboratorio en otro servidor, aquí tienes el resumen limpio y directo de los pasos.

Partiendo del hecho de que tu puente `incusbr0` ya existe (y es dueño de la subred `10.10.0.1/24`), el proceso definitivo es el siguiente:

### 1. Instalar los demonios de red

Incus no trae OVN preinstalado; requiere que Open vSwitch y OVN estén corriendo en el sistema anfitrión.

```bash
sudo apt update
sudo apt install openvswitch-switch ovn-central ovn-host

```

### 2. Conectar Incus con OVN

Hay que configurar el switch virtual para que sepa cómo encapsular el tráfico interno, y luego indicarle a Incus la ruta exacta de los *sockets* de comunicación de OVN.

```bash
# Configurar Open vSwitch
sudo ovs-vsctl set open_vswitch . \
  external_ids:ovn-remote=unix:/run/ovn/ovnsb_db.sock \
  external_ids:ovn-encap-type=geneve \
  external_ids:ovn-encap-ip=127.0.0.1

# Indicarle a Incus dónde está la base de datos de OVN
incus config set network.ovn.northbound_connection unix:/run/ovn/ovnnb_db.sock

```

### 3. Preparar el puente (Uplink)

Para que el puente sea elegible como "Uplink", necesita tener IPs disponibles para los enrutadores de OVN. Debemos asignar esos rangos asegurándonos de que no se solapen con el servidor DHCP actual.

```bash
incus network set incusbr0 \
  ipv4.dhcp.ranges=10.10.0.2-10.10.0.200 \
  ipv4.ovn.ranges=10.10.0.201-10.10.0.250

```

### 4. Autorizar el enrutamiento sin NAT

Como decidiste apagar el NAT en tu laboratorio (`ipv4.nat=false`), debes agregar una ruta estática en el Uplink. Esto le da permiso a `incusbr0` de enrutar los paquetes puros de la subred de tu laboratorio (`10.100.0.0/24`).

```bash
incus network set incusbr0 ipv4.routes=10.100.0.0/24

```

### 5. Crear la red OVN

Con todo el terreno listo, el comando final engancha la nueva red al Uplink y le asigna su propia subred de forma aislada.

```bash
incus network create lab-net \
  --type=ovn \
  network=incusbr0 \
  ipv4.address=10.100.0.1/24 \
  ipv4.nat=false

```