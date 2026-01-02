from flask import Flask, render_template
import os

flask_app = Flask(__name__)
flask_app.template_folder = "./templates"

@flask_app.route("/")
def index():
    return render_template(
        "index.html",
        greeting=os.getenv(
            "APP_GREETING",
            "Hello from Flask running locally!"
        ),
        app_name=os.getenv("APP_NAME"),
        has_secret=os.getenv("API_KEY") is not None
    ), 200

@flask_app.route("/livez")
def live_z():
    return "OK", 200

@flask_app.route("/readyz")
def ready_z():
    return "OK", 200


if __name__ == "__main__":
    flask_app.run(debug=True, port=8080)

