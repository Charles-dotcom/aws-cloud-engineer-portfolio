from flask import Flask, jsonify
import os
import socket
from datetime import datetime

app = Flask(__name__)

@app.route('/')
def index():
    return jsonify({
        "message": "Multi-container demo running behind Nginx!",
        "service": "backend-api",
        "author": "Charles Mphahlele",
        "timestamp": datetime.utcnow().isoformat(),
        "hostname": socket.gethostname()
    })

@app.route('/health')
def health():
    return jsonify({"status": "healthy", "service": "multi-container-api"})

if __name__ == "__main__":
    port = int(os.environ.get("PORT", 8080))
    app.run(host="0.0.0.0", port=port)
