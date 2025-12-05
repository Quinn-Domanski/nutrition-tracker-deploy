import os

class Config:
    SECRET_KEY = os.getenv("SECRET_KEY", "dev")

    SESSION_TYPE = "filesystem"
    SESSION_PERMANENT = False
    SESSION_USE_SIGNER = True
    SESSION_COOKIE_SAMESITE = "Lax"
    SESSION_COOKIE_SECURE = os.getenv("SECURE_COOKIES", "False").lower() == "true"

    # Database
    DB_USER = os.getenv("DB_USER")
    DB_PASSWORD = os.getenv("DB_PASSWORD")
    DB_NAME = os.getenv("DB_NAME")
    DB_HOST = os.getenv("DB_HOST")
    DB_PORT = int(os.getenv("DB_PORT", 5432))

    # Frontend URL for CORS
    FRONTEND_URL = os.getenv("FRONTEND_URL")