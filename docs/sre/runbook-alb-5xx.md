# Runbook: load balancer target 5xx

Alarm: `{project}-{environment}-alb-5xx`. It fires when the target group returns more than 10 HTTP 5xx responses in each of two minutes. There is no notification topic. Wire one before this alarm is useful in a live account.

The service also tracks CPU at 70 percent and scales between `min_capacity` and `max_capacity`. That scaling has no separate alarm.

## Look

Names follow `{project}-{environment}`. Dev is `portfolio-dev`. The cluster suffix is `-cluster`.

```bash
aws ecs describe-services \
  --cluster portfolio-dev-cluster \
  --services portfolio-dev \
  --region af-south-1 \
  --query 'services[0].{desired:desiredCount,running:runningCount,events:events[0:5]}'

aws logs tail /ecs/portfolio-dev --since 1h --region af-south-1
```

`/health` does not touch the database. `/ready` does. A failing `/ready` with a healthy `/health` points at Postgres or at the secret.

## While it is failing

Scale inside the existing minimum and maximum. Autoscaling will move the count back toward the CPU target.

```bash
aws ecs update-service \
  --cluster portfolio-dev-cluster \
  --service portfolio-dev \
  --desired-count 2 \
  --region af-south-1
```

Do not raise the count above `max_capacity` and leave it. Change the Terraform variable if the new size should stick. The service ignores a Terraform change to `desired_count` after the first apply, so a manual scale is not overwritten by the next plan. A change to the task definition is.

## After

If the database was the cause, confirm a connection with `sslmode=require` and that the execution role can read the RDS secret. Backups run 03:00–04:00 UTC (05:00–06:00 SAST). A restore has not been rehearsed against a live account. Do not treat the backup window as a tested recovery.
