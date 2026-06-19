from flask import Flask, jsonify
import os
import socket
from datetime import datetime

app = Flask(__name__)

@app.route('/')
def index():
    return jsonify({
        "message": "Hello from Cloud Engineer Portfolio!",
        "author": "Charles Mphahlele",
        "role": "Senior Cloud / DevOps Engineer",
        "timestamp": datetime.utcnow().isoformat() + "Z",
        "hostname": socket.gethostname(),
        "environment": os.getenv("ENVIRONMENT", "demo"),
        "version": os.getenv("APP_VERSION", "1.0.0")
    })

@app.route('/health')
def health():
    return jsonify({"status": "healthy", "service": "cloud-engineer-portfolio-demo"})

if __name__ == '__main__':
    port = int(os.environ.get("PORT", 8080))
    app.run(host='0.0.0.0', port=port)
