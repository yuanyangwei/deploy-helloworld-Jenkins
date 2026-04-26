import pytest
from helloworld import app

@pytest.fixture
def client():
    # Flask provides a test client for simulating requests
    return app.test_client()

def test_health(client):
    resp = client.get("/health")
    assert resp.status_code == 200
    assert resp.json["status"] == "ok"

def test_hello(client):
    resp = client.get("/hello?name=Test")
    assert resp.status_code == 200
    assert resp.json["message"] == "Hello, Test!"
