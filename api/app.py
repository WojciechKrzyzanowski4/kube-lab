from flask import Flask, jsonify
import os

flask_app = Flask(__name__)
@flask_app.route("/")
def index():
    return "Hello from Flask running in Kubernetes!", 200

@flask_app.route("/livez")
def live_z():
    return "OK", 200

@flask_app.route("/readyz")
def ready_z():
    return "OK", 200

@flask_app.route("/healthz")
def health_z():
    return "OK", 200

@flask_app.route("/config")
def config():
    app_name = os.getenv("APP_NAME", "DefaultApp")
    return jsonify({"app_name": app_name})


if __name__ == "__main__":
    flask_app.run(debug=True, port=8080)

