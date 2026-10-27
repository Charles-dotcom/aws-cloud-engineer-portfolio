# Multi-container lab

Nginx in front of a small Flask API. This is a local pattern, not the image ECS runs. The ECS service runs `apps/api`.

```bash
docker compose up --build
```

Nginx is published on port 8088 so it does not collide with anything already bound to port 80. The API image runs as a non-root user. The official Nginx image still starts as root so it can bind port 80 inside the container.
