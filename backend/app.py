from flask import Flask, jsonify

app = Flask(__name__)


@app.route("/notes", methods=["GET"])
def get_notes():
    return jsonify([])


if __name__ == "__main__":
    app.run(debug=True)