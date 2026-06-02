# Plan de Ansible para poblar los contenedores

Este documento describe el plan de automatización con Ansible para provisionar el contenido de los contenedores del laboratorio: `ctl`, `api`, `core`, `db`, `mon` y `ceph`.

Se basa en los principios de Ansible:
- Inventario para agrupar hosts y roles.
- Playbooks declarativos.
- Módulos base: `apt`, `copy`, `template`, `service`, `systemd`, `file`, `user`, `command`, `shell`.
- Uso de variables y plantillas para separar datos de configuración.

> Referencias clave de la documentación de Ansible:
> - Inventarios: https://docs.ansible.com/projects/ansible/latest/inventory_guide/index.html
> - Playbooks: https://docs.ansible.com/projects/ansible/latest/playbook_guide/playbooks_intro.html
> - Módulos: https://docs.ansible.com/projects/ansible/latest/module_plugin_guide/modules_intro.html
> - Configuración de servicios: https://docs.ansible.com/projects/ansible/latest/modules/systemd_module.html

---

## 1. Objetivo

Poblar cada contenedor con su contenido y configuración correspondiente, siguiendo el diseño actual del proyecto:
- `ctl`: nodo de control / orquestación.
- `api`: servicio Flask de `app-api`.
- `core`: lógica de negocio interna.
- `db`: PostgreSQL.
- `mon`: Prometheus + Grafana.
- `ceph`: almacenamiento.

El plan debe poder ejecutarse desde la máquina anfitrión o desde `ctl`, usando Ansible como herramienta de despliegue.

---

## 2. Alcance del plan

1. Crear Inventario de contenedores.
2. Preparar roles y playbooks Ansible.
3. Definir variables por grupo y por host.
4. Copiar código y archivos de configuración.
5. Instalar paquetes del sistema.
6. Crear servicios `systemd` y asegurar su arranque.
7. Validar despliegue con comprobaciones básicas.

---

## 3. Inventario propuesto

Usar un inventario estático en `inventory/hosts.yml` con grupos:
- `ctl`
- `app` (incluye `api`, `core`)
- `database`
- `monitoring`
- `storage`

Ejemplo:

```yaml
all:
  children:
    ctl:
      hosts:
        ctl:
          ansible_host: 10.100.0.10
    app:
      hosts:
        api:
          ansible_host: 10.100.0.11
        core:
          ansible_host: 10.100.0.12
    database:
      hosts:
        db:
          ansible_host: 10.100.0.13
    monitoring:
      hosts:
        mon:
          ansible_host: 10.100.0.14
    storage:
      hosts:
        ceph:
          ansible_host: 10.100.0.15
```

> Nota: si las máquinas no tienen SSH configurado, el plan puede incluir una etapa de "bootstrap" que instale y habilite `openssh-server` en cada contenedor antes de usar Ansible por SSH.

---

## 4. Estructura de roles y tareas

El plan propone una estructura de roles Ansible:

- `roles/common`
  - Instala paquetes básicos comunes (`curl`, `git`, `python3`, `python3-venv`, `python3-pip`).
  - Crea usuarios y permisos.
  - Establece configuración de locales y hora.
- `roles/ctl`
  - Instala Ansible / OpenTofu en el nodo de control.
  - Copia playbooks y archivos de inventario si se quiere gestionar desde allí.
- `roles/api`
  - Copia el contenido de `api/` al contenedor `api`.
  - Configura entorno Python virtual.
  - Instala dependencias de `requirements.txt`.
  - Genera `.env` desde plantilla.
  - Crea el servicio `reservas-api.service`.
  - Activa y arranca el servicio.
- `roles/core`
  - Prepara el entorno de la lógica de negocio.
  - Si hay código `core`, copia carpetas y configura servicio o proceso.
  - De lo contrario, deja el contenedor base preparado.
- `roles/db`
  - Instala PostgreSQL.
  - Configura usuarios y bases de datos (`reservas_db`, `reservas_user`).
  - Ajusta `postgresql.conf` y `pg_hba.conf` si es necesario.
  - Asegura el servicio `postgresql`.
- `roles/monitoring`
  - Instala Prometheus y Grafana.
  - Copia configuraciones y dashboards básicos.
  - Configura volúmenes persistentes en `/prometheus` y `/var/lib/grafana`.
  - Inicia y habilita los servicios.
- `roles/ceph`
  - Instala paquetes de Ceph.
  - Verifica el montaje del volumen `ceph-data`.
  - Deja el contenedor listo para servicio de almacenamiento.

---

## 5. Playbook principal

Un playbook `site.yml` propuesto:

```yaml
- name: Provisionar infraestructura de contenedores
  hosts: all
  become: true
  vars_files:
    - vars/common.yml

  roles:
    - common

- name: Configurar nodo de control
  hosts: ctl
  become: true
  roles:
    - ctl

- name: Desplegar API Flask
  hosts: api
  become: true
  roles:
    - api

- name: Desplegar lógica core
  hosts: core
  become: true
  roles:
    - core

- name: Configurar PostgreSQL
  hosts: db
  become: true
  roles:
    - db

- name: Configurar monitoreo
  hosts: mon
  become: true
  roles:
    - monitoring

- name: Preparar Ceph
  hosts: ceph
  become: true
  roles:
    - ceph
```

Este playbook sigue la guía de Ansible para roles y playbooks declarativos.

---

## 6. Variables y plantillas

Variables clave para cada rol:

- `api`:
  - `app_path: /app/reservas-api`
  - `venv_path: /app/reservas-api/venv`
  - `requirements_file: /app/reservas-api/requirements.txt`
  - `env_file: /app/reservas-api/.env`
  - `database_url: postgresql://reservas_user:SecurePassword123!@db:5432/reservas_db`
- `db`:
  - `postgres_user: reservas_user`
  - `postgres_db: reservas_db`
  - `postgres_password: SecurePassword123!`
- `monitoring`:
  - `prometheus_path: /prometheus`
  - `grafana_path: /var/lib/grafana`
- `ceph`:
  - `ceph_data_path: /var/lib/ceph`

Plantar plantillas usando `ansible.builtin.template` para:
- `.env` del API
- unidad `systemd` de `reservas-api`
- `prometheus.yml`
- configuración de PostgreSQL si es necesario

---

## 7. Secuencia de tareas de despliegue

1. `ansible-playbook -i inventory/hosts.yml site.yml --tags bootstrap`
   - asegura SSH en los contenedores si aún no existe.
2. `ansible-playbook -i inventory/hosts.yml site.yml --tags common,db`
   - instala PostgreSQL y dependencias.
3. `ansible-playbook -i inventory/hosts.yml site.yml --tags api`
   - copia la API y levanta el servicio.
4. `ansible-playbook -i inventory/hosts.yml site.yml --tags monitoring`
   - prepara Prometheus/Grafana.
5. `ansible-playbook -i inventory/hosts.yml site.yml --tags ceph`
   - prepara Ceph.
6. `ansible-playbook -i inventory/hosts.yml site.yml`
   - despliegue completo.

---

## 8. Tareas específicas por contenedor

### `api`
- Crear `/app/reservas-api`.
- Copiar los archivos de `api/` desde el repositorio al contenedor.
- Instalar dependencias de sistema y Python.
- Crear y activar virtualenv.
- Instalar `requirements.txt`.
- Crear `.env` desde plantilla con `DATABASE_URL` y JWT.
- Crear `reservas-api.service` y habilitarlo.
- Verificar `curl http://127.0.0.1:5000/api/v1/health`.

### `core`
- Crear ruta de aplicación base, si hay código futuro.
- Preparar Python y dependencias comunes.
- Configurar estructura de carpetas y permisos.

### `db`
- Instalar `postgresql`.
- Crear base de datos y usuario con contraseña segura.
- Asegurar que el servicio `postgresql` esté activo.
- Verificar conexión desde el contenedor `api`.

### `mon`
- Instalar `prometheus` y `grafana`.
- Configurar volúmenes persistentes.
- Copiar configuraciones básicas.
- Crear servicios y habilitarlos.
- Verificar endpoints de `Prometheus` y `Grafana`.

### `ceph`
- Instalar paquetes de Ceph o preparar el contenedor como nodo de datos.
- Verificar el montaje del volumen `ceph-data`.
- Crear directorios y permisos.

### `ctl`
- Instalar `ansible`, `python3-venv` y herramientas de gestión.
- Copiar inventario y playbooks si el nodo de control ejecutará Ansible desde allí.

---

## 9. Consideraciones técnicas

- Usar `become: true` en todos los roles porque se requieren operaciones de sistema.
- Evitar `shell`/`command` cuando exista un módulo específico.
- Utilizar `ansible.builtin.copy` para archivos estáticos y `ansible.builtin.template` para archivos con variables.
- Guardar secretos sensibles con `ansible-vault` (por ejemplo, `postgres_password`, `JWT_SECRET_KEY`).
- Documentar variables en `group_vars/` y `host_vars/`.

---

## 10. Validación final

Después del despliegue, realizar comprobaciones con Ansible:

- `ansible -i inventory/hosts.yml all -m ping`
- `ansible -i inventory/hosts.yml api -m uri -a 'url=http://127.0.0.1:5000/api/v1/health status_code=200'`
- `ansible -i inventory/hosts.yml db -m shell -a 'psql -U reservas_user -d reservas_db -c "SELECT 1"'`
- `ansible -i inventory/hosts.yml mon -m shell -a 'curl -sSf http://localhost:9090/-/ready'`

---

## 11. Próximos pasos

1. Crear el inventario real con IPs de los contenedores.
2. Implementar roles mínimos: `common`, `api`, `db`, `monitoring`, `ceph`, `ctl`.
3. Probar primero en un contenedor `api` y en el contenedor `db`.
4. Integrar el plan con `scripts/` existentes para tener una opción automatizada y otra declarativa.

---

## 12. Archivos sugeridos en el repositorio

- `inventory/hosts.yml`
- `group_vars/all.yml`
- `group_vars/api.yml`
- `group_vars/db.yml`
- `roles/common/tasks/main.yml`
- `roles/api/tasks/main.yml`
- `roles/db/tasks/main.yml`
- `roles/monitoring/tasks/main.yml`
- `roles/ceph/tasks/main.yml`
- `roles/ctl/tasks/main.yml`
- `site.yml`
- `roles/api/templates/.env.j2`
- `roles/api/templates/reservas-api.service.j2`
- `roles/db/templates/pg_hba.conf.j2`
- `roles/monitoring/templates/prometheus.yml.j2`
