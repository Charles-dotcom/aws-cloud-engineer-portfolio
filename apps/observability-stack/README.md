# Observability Stack (Prometheus + Grafana)

This is a **production-ready local observability stack** using industry-standard open-source tools:

- **Prometheus** — Time-series database + scraping
- **Grafana** — Dashboards and visualization
- Pre-configured provisioning (data source + dashboards)

## Why This Matters

Modern Cloud/SRE/Platform Engineers are expected to be fluent in **Prometheus + Grafana**, not just cloud-native monitoring (CloudWatch, Azure Monitor, etc.). This stack shows you understand the **de facto standard** in the industry.

## Quick Start

```bash
cd apps/observability-stack
docker compose up -d
```

Then open:
- **Grafana**: http://localhost:3000 (admin / admin)
- **Prometheus**: http://localhost:9090

## How to Extend

### For your applications
1. Add Prometheus client libraries to your code (Python, Go, Node.js, etc.)
2. Expose `/metrics` endpoint
3. Add the target in `prometheus.yml`

### For production (AWS)
Recommended patterns:
- **AWS Managed Prometheus (AMP)** + **AWS Managed Grafana (AMG)**
- Self-managed Prometheus on EKS with Helm + Thanos/Cortex for long-term storage
- OpenTelemetry Collector for unified telemetry

### Integration with your apps
You can scrape the multi-container app or the sample Flask app once you add metrics endpoints.

## Bonus: SRE Mindset
This stack pairs extremely well with:
- SLOs and error budget tracking (using Prometheus recording rules)
- Alertmanager for PagerDuty/Opsgenie routing
- Runbooks linked from Grafana alerts

This combination (AWS CloudWatch + open-source Prometheus/Grafana) shows you are **not a one-trick pony** and can operate in both cloud-native and cloud-agnostic environments.
