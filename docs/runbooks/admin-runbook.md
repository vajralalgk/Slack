<div align="center">

# ECTP Admin Runbook

```
╔══════════════════════════════════════════════════════════════════╗
║                    ECTP ADMIN RUNBOOK                           ║
║               Enterprise Cloud Transformation Platform          ║
╚══════════════════════════════════════════════════════════════════╝
```

**Author:** Gopi Krishna Vajrala
**Version:** 1.0.0
**Last Updated:** 2026-02-16
**Classification:** Internal Operations

</div>

---

## Quick Reference Card

> **Bookmarkable summary of critical information for on-call engineers**

| | Item | Detail |
|---|---|---|
| **Health Checks** | All Environments | `https://<env>.ectp.edu/health` |
| **Dashboards** | CloudWatch | AWS Console > CloudWatch > ECTP Dashboards |
| **Alerts** | PagerDuty | [PagerDuty ECTP Service] |
| **Logs** | CloudWatch Logs | Log Group: `/ecs/ectp-<env>` |
| **Deployments** | CI/CD | GitHub Actions > ECTP Workflows |
| **Incidents** | ServiceNow | ServiceNow ECTP Queue |
| **Escalation** | Primary | Gopi Krishna Vajrala (Platform Architect) |
| **Maintenance** | Standard Window | Sunday 02:00-06:00 UTC |

---

## Severity Classification Badges

| Severity | Badge | Response Time | Description |
|----------|-------|---------------|-------------|
| **P1** | :red_circle: `CRITICAL` | **15 minutes** | Complete outage, data loss risk |
| **P2** | :orange_circle: `HIGH` | **30 minutes** | Major feature impacted, degraded service |
| **P3** | :yellow_circle: `MEDIUM` | **4 hours** | Minor feature impacted, workaround exists |
| **P4** | :white_circle: `LOW` | **Next business day** | Cosmetic, minor inconvenience |

---

## Daily Operations Checklist

> Complete these checks every morning between **08:00 - 09:00 local time**

| | # | Task | Tool/Location | Expected State |
|---|---|---|---|---|
| :ballot_box_with_check: | 1 | Check CloudWatch dashboard for anomalies | AWS CloudWatch > ECTP Dashboards | All metrics green |
| :ballot_box_with_check: | 2 | Review overnight alerts (SNS/PagerDuty) | PagerDuty > ECTP Service | No unacknowledged alerts |
| :ballot_box_with_check: | 3 | Verify all health check endpoints (dev/qa/uat/prod) | `curl https://<env>.ectp.edu/health` | HTTP 200 on all |
| :ballot_box_with_check: | 4 | Check cost dashboard for unexpected spikes | AWS Cost Explorer > ECTP | Within budget threshold |
| :ballot_box_with_check: | 5 | Review failed CI/CD pipeline runs | GitHub Actions > ECTP | No failures |
| :ballot_box_with_check: | 6 | Check ServiceNow integration queue depth | ServiceNow > ECTP Queue | Queue depth < 100 |
| :ballot_box_with_check: | 7 | Verify Ellucian data sync completed | CloudWatch > Ellucian Sync | Last sync < 24h ago |

---

## Incident Response

### :red_circle: P1 - Critical (Response: 15 minutes)

> **IMMEDIATE ACTION REQUIRED** - Complete production outage or data integrity risk

<details>
<summary><strong>:red_circle: P1 Response Procedure - Click to expand</strong></summary>

```
P1 INCIDENT RESPONSE TIMELINE
══════════════════════════════════════════════════════════════
 0 min          5 min          15 min         30 min        60 min
  │              │               │              │             │
  ▼              ▼               ▼              ▼             ▼
 ACK           JOIN           IDENTIFY       FIX/          POST-
 ALERT         BRIDGE         SERVICE        ROLLBACK      INCIDENT
               CALL                                        REPORT
══════════════════════════════════════════════════════════════
```

| Step | Action | Details |
|------|--------|---------|
| **Step 1** | **Acknowledge alert in PagerDuty** | Open PagerDuty, acknowledge the alert to stop escalation timer |
| **Step 2** | **Join incident bridge call** | Dial into the incident bridge; link is in the PagerDuty alert |
| **Step 3** | **Identify affected service via CloudWatch** | Check ECTP dashboards: error rates, latency, CPU/memory |
| **Step 4** | **Check recent deployments (rollback if suspected)** | Review last deployment; run rollback if deployed within 2 hours |
| **Step 5** | **Investigate logs with correlation ID** | Use CloudWatch Logs Insights with the `correlation_id` |
| **Step 6** | **Apply fix or rollback** | Deploy hotfix or run `rollback.sh <environment>` |
| **Step 7** | **Verify recovery via health checks** | Confirm all health endpoints return 200 |
| **Step 8** | **Create post-incident report** | Document timeline, root cause, remediation in Confluence |

</details>

---

### :orange_circle: P2 - High (Response: 30 minutes)

> **URGENT** - Major feature degraded, significant user impact

<details>
<summary><strong>:orange_circle: P2 Response Procedure - Click to expand</strong></summary>

| Step | Action | Details |
|------|--------|---------|
| **Step 1** | **Acknowledge alert** | Acknowledge in PagerDuty within 30 minutes |
| **Step 2** | **Investigate root cause** | Review CloudWatch metrics, logs, and recent changes |
| **Step 3** | **Apply fix or workaround** | Implement fix or document workaround for affected users |
| **Step 4** | **Update ServiceNow incident** | Log all actions and timeline in ServiceNow ticket |
| **Step 5** | **Schedule post-mortem if needed** | If systemic issue, schedule team post-mortem within 5 days |

</details>

---

## Scaling Operations

### Manual Scale-Up

<details>
<summary><strong>ECS Service Scaling Procedure</strong></summary>

> Use this when auto-scaling cannot keep pace or during anticipated traffic spikes

```bash
# Scale ECS service to 8 tasks
aws ecs update-service \
  --cluster ectp-prod \
  --service ectp-api-prod \
  --desired-count 8
```

**Verification:**
```bash
# Confirm task count
aws ecs describe-services \
  --cluster ectp-prod \
  --services ectp-api-prod \
  --query 'services[0].runningCount'
```

</details>

### Database Scaling

<details>
<summary><strong>RDS Scaling Options</strong></summary>

| Method | Description | Downtime | Requires |
|--------|-------------|----------|----------|
| **Vertical** | Modify RDS instance class | Yes (maintenance window) | Change Board approval |
| **Read Replicas** | Add via Terraform for read-heavy periods | No | Team Lead approval |

</details>

---

## Backup & Restore

### RDS Automated Backups

| Parameter | Value |
|-----------|-------|
| **Retention** | 35 days |
| **Frequency** | Daily |
| **Cross-Region** | Enabled to us-west-2 |

### Manual Backup

<details>
<summary><strong>Create Manual RDS Snapshot</strong></summary>

```bash
# Create a manual snapshot with date stamp
aws rds create-db-snapshot \
  --db-instance-identifier ectp-prod \
  --db-snapshot-identifier ectp-manual-$(date +%Y%m%d)
```

</details>

### Restore from Backup

<details>
<summary><strong>Restore RDS from Snapshot</strong></summary>

> :warning: **WARNING:** Restoring creates a NEW instance. You must update DNS/connection strings afterward.

```bash
# Restore from a specific snapshot
aws rds restore-db-instance-from-db-snapshot \
  --db-instance-identifier ectp-restored \
  --db-snapshot-identifier ectp-manual-20260216
```

</details>

---

## Common Troubleshooting

| | Symptom | Possible Cause | Resolution | Severity |
|---|---|---|---|---|
| :red_circle: | **502 errors** | ECS tasks crashing | Check task logs, increase memory allocation | P1 |
| :orange_circle: | **High DB CPU** | Slow queries | Analyze Performance Insights, optimize queries | P2 |
| :orange_circle: | **ServiceNow timeout** | Network or auth issue | Check VPN connectivity, refresh OAuth token | P2 |
| :yellow_circle: | **Cost spike** | Runaway auto-scaling | Check scaling policies, set max limits | P3 |
| :yellow_circle: | **Failed deploys** | Test failures | Check CI/CD logs, fix failing tests | P3 |

<details>
<summary><strong>Detailed Troubleshooting Steps</strong></summary>

#### 502 Errors
```bash
# Check ECS task status
aws ecs list-tasks --cluster ectp-prod --service-name ectp-api-prod

# View stopped task reasons
aws ecs describe-tasks --cluster ectp-prod --tasks <task-arn> \
  --query 'tasks[0].stoppedReason'

# Check CloudWatch logs
aws logs tail /ecs/ectp-prod --since 30m --filter-pattern "ERROR"
```

#### High DB CPU
```bash
# Check active connections
aws rds describe-db-instances \
  --db-instance-identifier ectp-prod \
  --query 'DBInstances[0].DBInstanceStatus'
```

</details>

---

## Maintenance Windows

| Type | Window | Notice Required | Approval |
|------|--------|-----------------|----------|
| **Standard** | Sunday 02:00-06:00 UTC | 48 hours before | Team Lead |
| **Emergency** | Any time | 2 hour notice | IT Director |

---

## Emergency Contacts

```
ESCALATION PATH
════════════════════════════════════════════════════════════
                    ┌──────────────────┐
                    │  Security Team   │ ◄── Security Incidents
                    │  _______________  │
                    └────────┬─────────┘
                             │
                    ┌────────▼─────────┐
                    │   IT Director    │ ◄── Escalation (P1/P2)
                    │  _______________  │
                    └────────┬─────────┘
                             │
                    ┌────────▼─────────┐
                    │ Cloud Operations │ ◄── 24/7 On-Call Rotation
                    │  On-call rotation │
                    └────────┬─────────┘
                             │
                    ┌────────▼─────────┐
                    │    Platform      │ ◄── PRIMARY CONTACT
                    │    Architect     │
                    │ Gopi Krishna     │
                    │ Vajrala          │
                    └──────────────────┘
════════════════════════════════════════════════════════════
```

| Priority | Role | Contact | Availability |
|----------|------|---------|-------------|
| :red_circle: **Primary** | Platform Architect | Gopi Krishna Vajrala | Business hours + on-call |
| :orange_circle: **24/7** | Cloud Operations | On-call rotation | 24/7 |
| :yellow_circle: **Escalation** | IT Director | _______________ | Business hours |
| :white_circle: **Security** | Security Team | _______________ | Security incidents only |

---

<div align="center">

```
══════════════════════════════════════════════════════════════
                    END OF ADMIN RUNBOOK
              Enterprise Cloud Transformation Platform
══════════════════════════════════════════════════════════════
```

**Author:** Gopi Krishna Vajrala

</div>
