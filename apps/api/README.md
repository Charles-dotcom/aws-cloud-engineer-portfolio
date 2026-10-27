# portfolio-api

The container the ECS service runs. Locally it talks to Postgres over Compose. On AWS it reads `DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_USERNAME` and `DB_PASSWORD`, with `DB_SSLMODE=require`. RDS generates the password. This directory never contains one.

`/health` is liveness and does not touch the database. `/ready` checks it. Neither response includes an exception string.

```bash
cp .env.example .env
docker compose up --build
```

`init.sql` runs only in Compose. RDS does not execute it. Create the table with a migration before calling `/users` on AWS.
