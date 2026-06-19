# Multi-Container Application Demo

This example shows a **production-style multi-container deployment** using:

- **Nginx** as reverse proxy / load balancer
- **Flask API** as backend service
- Docker Compose for local development
- Ready to extend to Amazon ECS (Fargate) with multi-container task definitions

## Local Development

```bash
cd apps/multi-container-app

docker compose up --build
```

Then open http://localhost — Nginx proxies to the Flask API.

## Why Multi-Container Matters

Real-world applications almost always consist of multiple services (web, API, worker, cache, etc.). Showing you can design, build, and orchestrate them cleanly is a strong signal for Cloud/DevOps/SRE roles.

## Next Steps (Production)

- Add a proper healthcheck endpoint + readiness probe
- Use Amazon ECS with a single Task Definition containing both containers (sidecar pattern)
- Add logging aggregation (Fluent Bit or CloudWatch)
- Add service discovery / ALB target groups per service
- Implement blue/green or canary deployments for the API

This pattern scales well to more complex stacks (e.g. adding a worker + Redis/SQS).
