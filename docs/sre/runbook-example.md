# Runbook: High CPU Utilization on ECS Service

**Service:** cloud-engineer-portfolio  
**Severity:** P2  
**Owner:** Platform Team

## Symptoms
- CloudWatch alarm `cloud-engineer-portfolio-high-cpu` is firing
- Increased latency or 5xx errors may appear
- Grafana/CloudWatch shows CPU > 80% for > 4 minutes

## Diagnosis Steps (5-10 mins)

1. Check current metrics
   ```bash
   aws cloudwatch get-metric-statistics \
     --namespace AWS/ECS \
     --metric-name CPUUtilization \
     --dimensions Name=ServiceName,Value=cloud-engineer-portfolio \
     --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
     --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
     --period 60 --statistics Average
   ```

2. Check recent deployments
   ```bash
   aws ecs describe-services --cluster ... --services cloud-engineer-portfolio
   ```

3. Look at recent logs for errors / memory leaks
   ```bash
   aws logs tail /ecs/cloud-engineer-portfolio --since 1h
   ```

## Mitigation

**Immediate (if impacting users):**
- Scale out the service temporarily:
  ```bash
  aws ecs update-service --cluster ... --service cloud-engineer-portfolio --desired-count 4
  ```

**Longer term:**
- Investigate recent code change that increased CPU
- Optimize hot code paths or add caching
- Right-size task CPU/memory in Terraform
- Consider adding auto-scaling policies (target tracking)

## Escalation

If not resolved in 30 mins → page on-call engineer + create incident in tracking tool.

## Post-Incident

- Update this runbook with new findings
- Add better alerting or automation if pattern repeats
- Review error budget consumption
