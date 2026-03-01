import os
from flask import Flask, jsonify

app = Flask(__name__)

GREETING = os.getenv("GREETING", "Hello, world!")
VERSION = os.getenv("APP_VERSION", "1.0.0")

@app.get("/")
def index():
    return jsonify(message=GREETING, version=VERSION), 200

@app.get("/healthz")
def healthz():
    # Place dependency checks here if needed (DB, cache, etc.)
    return jsonify(status="ok"), 200

if __name__ == "__main__":
    port = int(os.getenv("PORT", "8000"))
    app.run(host="0.0.0.0", port=port)