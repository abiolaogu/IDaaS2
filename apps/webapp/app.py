from flask import Flask, request

app = Flask(__name__)

@app.route("/")
def hello():
    # OAuth2-Proxy forwards the user's email in this header
    email = request.headers.get("X-Forwarded-Email")
    if email:
        return f"Hello, {email}! You are authenticated."
    else:
        return "Hello, stranger! You are not authenticated."

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)
