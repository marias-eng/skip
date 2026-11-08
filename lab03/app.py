from flask import Flask, jsonify, request
from flask_cors import CORS
import psycopg
import os
from dotenv import load_dotenv

load_dotenv()

app = Flask(__name__)

CORS(app, origins=[
    "http://127.0.0.1:5500",
    "http://localhost:5500"
])


def get_connection():
    return psycopg.connect(
        host=os.getenv("DB_HOST"),
        port=os.getenv("DB_PORT"),
        dbname=os.getenv("DB_NAME"),
        user=os.getenv("DB_USER"),
        password=os.getenv("DB_PASSWORD")
    )


@app.route("/health", methods=["GET"])
def health():
    return jsonify({"status": "ok"}), 200


@app.route("/tasks", methods=["GET"])
def get_tasks():
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute(
                "SELECT id, title, created_at FROM tasks ORDER BY id"
            )
            tasks = cur.fetchall()

    return jsonify([
        {
            "id": task[0],
            "title": task[1],
            "created_at": task[2].isoformat() if task[2] else None
        }
        for task in tasks
    ])


@app.route("/tasks", methods=["POST"])
def create_task():
    data = request.get_json()

    if (
            not data
            or not isinstance(data.get("title"), str)
            or not data["title"].strip()
    ):
        return jsonify({"error": "title is required"}), 400

    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                INSERT INTO tasks (title)
                VALUES (%s)
                RETURNING id, title, created_at
                """,
                (data["title"].strip(),)
            )
            task = cur.fetchone()

        conn.commit()

    return jsonify({
        "id": task[0],
        "title": task[1],
        "created_at": task[2].isoformat() if task[2] else None
    }), 201


if __name__ == "__main__":
    app.run(
        host="0.0.0.0",
        port=int(os.getenv("PORT", "5000")),
        debug=os.getenv("FLASK_DEBUG", "false").lower() == "true"
    )
