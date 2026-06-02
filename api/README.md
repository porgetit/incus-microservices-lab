# API de prueba para Incus Microservices Lab

Esta carpeta contiene una API de prueba muy simple en Python/Flask para el proyecto de infraestructura.
Está diseñada para ser copiada dentro de un contenedor con Ansible y servir como punto de partida para el servicio `app-api`.

## Estructura

- `run.py`: Punto de entrada de la aplicación.
- `api/requirements.txt`: Dependencias necesarias.
- `api/.env.example`: Variables de entorno de ejemplo.
- `api/app/__init__.py`: Inicializa la aplicación Flask y SQLAlchemy.
- `api/app/models.py`: Modelos de datos básicos para usuarios, recursos y reservas.
- `api/app/routes.py`: Endpoints REST de prueba.

## Endpoints

- `GET /api/v1/health`
  - Devuelve estado y timestamp.

- `GET /api/v1/resources`
  - Lista los recursos registrados.

- `POST /api/v1/resources`
  - Crea un recurso nuevo.
  - Payload JSON: `{"nombre": "Sala 1", "tipo": "sala"}`

- `GET /api/v1/reservations`
  - Lista reservas.

- `POST /api/v1/reservations`
  - Crea una reserva.
  - Payload JSON: `{"usuario_id": 1, "recurso_id": 1, "fecha_inicio": "2026-06-03T10:00:00", "fecha_fin": "2026-06-03T11:00:00"}`

## Uso local

1. Copiar el archivo `.env.example` a `.env` y ajustar la URL de la base de datos.

2. Instalar dependencias:

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

3. Ejecutar la aplicación:

```bash
python run.py
```

4. Probar el health check:

```bash
curl http://127.0.0.1:5000/api/v1/health
```

## Notas para Ansible

Este contenido está pensado para ser desplegado en el contenedor `app-api` con un playbook que copie la carpeta `api/` y luego instale las dependencias, configure el archivo `.env` y genere el servicio systemd.

Ejemplo de rutas de destino dentro del contenedor:

- `/app/reservas-api/run.py`
- `/app/reservas-api/app/__init__.py`
- `/app/reservas-api/app/models.py`
- `/app/reservas-api/app/routes.py`
- `/app/reservas-api/requirements.txt`
- `/app/reservas-api/.env`
