from flask import Flask, jsonify
from flask_cors import CORS
from flask_session import Session
from routes import auth, account_bp, meal_bp, workout_bp, exercise_bp, logged_workout_bp, goal_bp, friend_bp, track_bp
from config import Config
from utils.db import get_connection
import os

def create_app():
    app = Flask(__name__)
    app.config.from_object(Config)

    Session(app)

    CORS(app, supports_credentials=True, origins=[Config.FRONTEND_URL], allow_headers=['Content-Type'])

    @app.route('/health')
    def health():
        try:
            conn = get_connection()
            conn.close()
            return {'status': 'ok', 'db': 'connected'}, 200
        except Exception as e:
            return {'status': 'error', 'db': str(e)}, 503

    @app.route('/api/health')
    def api_health():
        try:
            conn = get_connection()
            conn.close()
            return {'status': 'ok', 'db': 'connected'}, 200
        except Exception as e:
            return {'status': 'error', 'db': str(e)}, 503

    @app.errorhandler(404)
    def not_found(e):
        return jsonify({'error': 'Not found'}), 404

    @app.errorhandler(500)
    def server_error(e):
        return jsonify({'error': 'Server error'}), 500

    app.register_blueprint(auth, url_prefix='/api')
    app.register_blueprint(account_bp, url_prefix='/api')
    app.register_blueprint(meal_bp, url_prefix='/api')
    app.register_blueprint(workout_bp, url_prefix='/api')
    app.register_blueprint(exercise_bp, url_prefix='/api')
    app.register_blueprint(logged_workout_bp, url_prefix='/api')
    app.register_blueprint(goal_bp, url_prefix='/api')
    app.register_blueprint(friend_bp, url_prefix='/api')
    app.register_blueprint(track_bp, url_prefix='/api')

    return app

app = create_app()

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
