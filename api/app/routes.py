from datetime import datetime
from flask import Blueprint, jsonify, request
from app import db
from app.models import Usuario, Recurso, Reserva

api_bp = Blueprint('api', __name__)


@api_bp.route('/health', methods=['GET'])
def health():
    return jsonify({'status': 'healthy', 'service': 'reservas-api', 'timestamp': datetime.utcnow().isoformat()}), 200


@api_bp.route('/resources', methods=['GET'])
def list_resources():
    recursos = Recurso.query.all()
    return jsonify([recurso.to_dict() for recurso in recursos]), 200


@api_bp.route('/resources', methods=['POST'])
def create_resource():
    payload = request.get_json(force=True, silent=True) or {}
    nombre = payload.get('nombre')
    tipo = payload.get('tipo')

    if not nombre or not tipo:
        return jsonify({'error': 'nombre and tipo are required'}), 400

    recurso = Recurso(nombre=nombre, tipo=tipo)
    db.session.add(recurso)
    db.session.commit()

    return jsonify(recurso.to_dict()), 201


@api_bp.route('/reservations', methods=['GET'])
def list_reservations():
    reservas = Reserva.query.all()
    return jsonify([reserva.to_dict() for reserva in reservas]), 200


@api_bp.route('/reservations', methods=['POST'])
def create_reservation():
    payload = request.get_json(force=True, silent=True) or {}
    usuario_id = payload.get('usuario_id')
    recurso_id = payload.get('recurso_id')
    fecha_inicio = payload.get('fecha_inicio')
    fecha_fin = payload.get('fecha_fin')

    if not usuario_id or not recurso_id or not fecha_inicio or not fecha_fin:
        return jsonify({'error': 'usuario_id, recurso_id, fecha_inicio and fecha_fin are required'}), 400

    usuario = Usuario.query.get(usuario_id)
    recurso = Recurso.query.get(recurso_id)

    if usuario is None or recurso is None:
        return jsonify({'error': 'usuario or recurso not found'}), 404

    reserva = Reserva(
        usuario_id=usuario_id,
        recurso_id=recurso_id,
        fecha_inicio=datetime.fromisoformat(fecha_inicio),
        fecha_fin=datetime.fromisoformat(fecha_fin),
    )
    db.session.add(reserva)
    db.session.commit()

    return jsonify(reserva.to_dict()), 201
