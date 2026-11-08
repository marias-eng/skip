import pytest
from lab03.app import app


@pytest.fixture
def client():
    app.config["TESTING"] = True

    with app.test_client() as client:
        yield client


def test_health(client):
    response = client.get("/health")

    assert response.status_code == 200
    assert response.json == {"status": "ok"}


def test_get_tasks(client, monkeypatch):
    class FakeCursor:
        def __enter__(self):
            return self

        def __exit__(self, *args):
            pass

        def execute(self, query):
            pass

        def fetchall(self):
            return []

    class FakeConnection:
        def __enter__(self):
            return self

        def __exit__(self, *args):
            pass

        def cursor(self):
            return FakeCursor()

    monkeypatch.setattr(
        "lab03.app.get_connection",
        lambda: FakeConnection()
    )

    response = client.get("/tasks")

    assert response.status_code == 200
    assert response.json == []


def test_create_task_without_title(client):
    response = client.post("/tasks", json={})

    assert response.status_code == 400
    assert response.json == {"error": "title is required"}


def test_create_task_with_empty_title(client):
    response = client.post("/tasks", json={"title": "   "})

    assert response.status_code == 400
    assert response.json == {"error": "title is required"}
