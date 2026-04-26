from flask import Flask, jsonify, request
import os

app = Flask(__name__)


@app.route("/health", methods=["GET"])
def health():
    return jsonify({"status": "ok"}), 200

@app.route("/hello", methods=["GET"])
def hello():
    name = request.args.get("name", "World")
    return jsonify({"message": f"Hello, {name}!"})


if __name__ == "__main__":
    # Use environment variables for port (Standard practice)
    port = int(os.environ.get("PORT", 5000))
    app.run(host="0.0.0.0", port=port)
