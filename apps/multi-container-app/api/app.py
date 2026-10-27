import os
import socket
from datetime import datetime, timezone

from flask import Flask, jsonify

app = Flask(__name__)


@app.get("/")
def index():
    return jsonify(
        message="Multi-container demo running behind Nginx.",
        service="backend-api",
        author="Charles Mphahlele",
        time=datetime.now(timezone.utc).isoformat(),
        hostname=socket.gethostname(),
        environment=os.getenv("ENVIRONMENT", "local"),
    )


@app.get("/health")
def health():
    return jsonify(status="healthy")
