from flask import Flask, jsonify

app = Flask(__name__)

@app.route('/v1/test')
def test():
    return jsonify(message="this is Salt security"), 200

@app.route('/v1/health')
def health():
    return '', 200

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=int(os.getenv("PORT", 5000)))

