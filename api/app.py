from flask import Flask
import os

flask_app = Flask(__name__)
@flask_app.route("/")
def index():
    greeting = os.getenv(
        "APP_GREETING",
        "Hello from Flask running locally!"
    )
    return greeting, 200

@flask_app.route("/livez")
def live_z():
    return "OK", 200

@flask_app.route("/readyz")
def ready_z():
    return "OK", 200

# This is the api space, you can define and change your endpoints right here
# Creating other files, maintaining a clean separation of concerns is not needed but advised



if __name__ == "__main__":
    flask_app.run(debug=True, port=8080)

