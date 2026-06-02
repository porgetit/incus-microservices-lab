from datetime import datetime
from app import db


class Usuario(db.Model):
    __tablename__ = 'usuario'

    id_usuario = db.Column(db.Integer, primary_key=True)
    nombre = db.Column(db.String(100), nullable=False)
    email = db.Column(db.String(100), unique=True, nullable=False, index=True)
    password_hash = db.Column(db.Text, nullable=False)
    fecha_creacion = db.Column(db.DateTime, default=datetime.utcnow, nullable=False)

    def to_dict(self):
        return {
            'id_usuario': self.id_usuario,
            'nombre': self.nombre,
            'email': self.email,
            'fecha_creacion': self.fecha_creacion.isoformat(),
        }


class Recurso(db.Model):
    __tablename__ = 'recurso'

    id_recurso = db.Column(db.Integer, primary_key=True)
    nombre = db.Column(db.String(100), nullable=False)
    tipo = db.Column(db.String(50), nullable=False)
    estado = db.Column(db.String(20), default='disponible', nullable=False)
    fecha_creacion = db.Column(db.DateTime, default=datetime.utcnow, nullable=False)

    def to_dict(self):
        return {
            'id_recurso': self.id_recurso,
            'nombre': self.nombre,
            'tipo': self.tipo,
            'estado': self.estado,
            'fecha_creacion': self.fecha_creacion.isoformat(),
        }


class Reserva(db.Model):
    __tablename__ = 'reserva'

    id_reserva = db.Column(db.Integer, primary_key=True)
    usuario_id = db.Column(db.Integer, db.ForeignKey('usuario.id_usuario'), nullable=False)
    recurso_id = db.Column(db.Integer, db.ForeignKey('recurso.id_recurso'), nullable=False)
    fecha_inicio = db.Column(db.DateTime, nullable=False)
    fecha_fin = db.Column(db.DateTime, nullable=False)
    estado_reserva = db.Column(db.String(20), default='confirmada', nullable=False)
    fecha_creacion = db.Column(db.DateTime, default=datetime.utcnow, nullable=False)

    usuario = db.relationship('Usuario', backref='reservas')
    recurso = db.relationship('Recurso', backref='reservas')

    def to_dict(self):
        return {
            'id_reserva': self.id_reserva,
            'usuario_id': self.usuario_id,
            'recurso_id': self.recurso_id,
            'fecha_inicio': self.fecha_inicio.isoformat(),
            'fecha_fin': self.fecha_fin.isoformat(),
            'estado_reserva': self.estado_reserva,
            'fecha_creacion': self.fecha_creacion.isoformat(),
        }
