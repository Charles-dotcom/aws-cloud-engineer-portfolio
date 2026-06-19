# Application + Database Docker Stack

This is a **production-style example** of Dockerizing both an **application and a database** together.

## Stack
- **PostgreSQL 16** (with init script + healthcheck)
- **Flask API** that connects to the database
- Proper dependency management (`depends_on` with health condition)
- Persistent volume for database data

## Run Locally

```bash
cd apps/app-with-db
docker compose up --build
```

Then test:
- http://localhost:8080/
- http://localhost:8080/users
- http://localhost:8080/health

## Why This Example is Valuable

Most real applications need a database. Showing you can:
- Properly Dockerize stateful services
- Handle database initialization
- Manage service dependencies and healthchecks
- Use environment variables for connection strings

...is much stronger than just a single stateless web app.

## Production Notes

In real environments you would:
- Use managed databases (RDS, Azure Database for PostgreSQL, etc.)
- Add secrets management (AWS Secrets Manager / Azure Key Vault)
- Add database migrations (Alembic, Flyway, etc.)
- Use Kubernetes StatefulSets or managed database operators
