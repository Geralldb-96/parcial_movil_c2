from flask import Flask
from flask_cors import CORS
from dotenv import load_dotenv

from .routes import api


def create_app(testing: bool = False) -> Flask:
    load_dotenv()
    app = Flask(__name__)
    app.config["TESTING"] = testing
    CORS(app)
    app.register_blueprint(api, url_prefix="/api")

    @app.get("/health")
    def health():
        return {"status": "ok", "service": "EcoEat API"}, 200

    return app

