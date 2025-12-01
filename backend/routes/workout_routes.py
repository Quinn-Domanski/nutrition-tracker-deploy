from flask import Blueprint, request, jsonify, session
from utils.db import get_connection
import datetime
from psycopg2.extras import RealDictCursor

workout_bp = Blueprint('workout', __name__)

