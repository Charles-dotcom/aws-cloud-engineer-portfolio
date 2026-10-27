import os

import pytest

os.environ.pop("DATABASE_URL", None)
for name in ("DB_HOST", "DB_NAME", "DB_USERNAME", "DB_PASSWORD"):
    os.environ.pop(name, None)

from app import app, database_configured  # noqa: E402


@pytest.fixture
def client():
    app.config["TESTING"] = True
    with app.test_client() as test_client:
        yield test_client


def test_health_does_not_need_a_database(client):
    response = client.get("/health")
    assert response.status_code == 200
    assert response.get_json()["status"] == "healthy"


def test_ready_is_generic_when_unconfigured(client):
    response = client.get("/ready")
    body = response.get_json()
    assert response.status_code == 503
    assert body == {"status": "not_ready"}
    assert "error" not in body
    assert "password" not in response.get_data(as_text=True).lower()


def test_users_does_not_leak_errors(client):
    response = client.get("/users")
    assert response.status_code == 503
    assert "psycopg" not in response.get_data(as_text=True).lower()


def test_split_env_counts_as_configured(monkeypatch):
    monkeypatch.setenv("DB_HOST", "db.internal")
    monkeypatch.setenv("DB_NAME", "app")
    monkeypatch.setenv("DB_USERNAME", "app")
    monkeypatch.setenv("DB_PASSWORD", "not-logged")
    assert database_configured() is True


def test_index_names_the_service(client):
    body = client.get("/").get_json()
    assert body["service"] == "portfolio-api"
    assert body["author"] == "Charles Mphahlele"
