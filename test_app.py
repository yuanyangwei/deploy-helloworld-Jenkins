import requests

def test_health():
    resp = requests.get("http://localhost:5000/health")
    assert resp.status_code == 200
    assert resp.json()["status"] == "ok"

def test_hello():
    resp = requests.get("http://localhost:5000/hello?name=Test")
    assert resp.status_code == 200
    assert resp.json()["message"] == "Hello, Test!"
