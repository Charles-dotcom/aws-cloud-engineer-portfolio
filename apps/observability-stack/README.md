# Local observability lab

Prometheus, node exporter and Grafana for a laptop. Nothing here is deployed by Terraform. The ECS service logs to CloudWatch, and the stack raises an alarm on load balancer 5xx responses.

```bash
cp .env.example .env
docker compose up -d
```

Grafana is on port 3000. The password comes from `.env`, which is gitignored. Prometheus keeps seven days of samples so the volume does not grow without a bound. The timezone on the dashboard is Africa/Johannesburg.
