import os
from flask import Flask
from flask_sqlalchemy import SQLAlchemy

from .routes import api_bp

db = SQLAlchemy()


def create_app():
    app = Flask(__name__)

    database_url = os.getenv('DATABASE_URL', 'sqlite:///reservas.db')
    app.config['SQLALCHEMY_DATABASE_URI'] = database_url
    app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
    app.config['JWT_SECRET_KEY'] = os.getenv('JWT_SECRET_KEY', 'secret-key')

    db.init_app(app)
    app.register_blueprint(api_bp, url_prefix='/api/v1')

    with app.app_context():
        db.create_all()

    return app
