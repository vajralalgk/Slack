# ECTP Admin Runbook

**Author:** Gopi Krishna Vajrala
**Version:** 1.0.0

---

## Daily Operations Checklist

- [ ] Check CloudWatch dashboard for anomalies
- [ ] Review overnight alerts (SNS/PagerDuty)
- [ ] Verify all health check endpoints (dev/qa/uat/prod)
- [ ] Check cost dashboard for unexpected spikes
- [ ] Review failed CI/CD pipeline runs
- [ ] Check ServiceNow integration queue depth
- [ ] Verify Ellucian data sync completed

## Incident Response

### P1 - Critical (Response: 15 min)
1. Acknowledge alert in PagerDuty
2. Join incident bridge call
3. Identify affected service via CloudWatch
4. Check recent deployments (rollback if suspected)
5. Investigate logs with correlation ID
6. Apply fix or rollback
7. Verify recovery via health checks
8. Create post-incident report

### P2 - High (Response: 30 min)
1. Acknowledge alert
2. Investigate root cause
3. Apply fix or workaround
4. Update ServiceNow incident
5. Schedule post-mortem if needed

## Scaling Operations

### Manual Scale-Up
```bash
aws ecs update-service \
  --cluster ectp-prod \
  --service ectp-api-prod \
  --desired-count 8
```

### Database Scaling
- Vertical: Modify RDS instance class (requires maintenance window)
- Read replicas: Add via Terraform for read-heavy periods

## Backup & Restore

### RDS Automated Backups
- **Retention:** 35 days
- **Frequency:** Daily
- **Cross-Region:** Enabled to us-west-2

### Manual Backup
```bash
aws rds create-db-snapshot \
  --db-instance-identifier ectp-prod \
  --db-snapshot-identifier ectp-manual-$(date +%Y%m%d)
```

### Restore from Backup
```bash
aws rds restore-db-instance-from-db-snapshot \
  --db-instance-identifier ectp-restored \
  --db-snapshot-identifier ectp-manual-20260216
```

## Common Troubleshooting

| Symptom | Possible Cause | Resolution |
|---------|---------------|-----------|
| 502 errors | ECS tasks crashing | Check task logs, increase memory |
| High DB CPU | Slow queries | Analyze Performance Insights |
| ServiceNow timeout | Network or auth issue | Check VPN, refresh OAuth token |
| Cost spike | Runaway auto-scaling | Check scaling policies, set limits |
| Failed deploys | Test failures | Check CI/CD logs, fix tests |

## Maintenance Windows

- **Standard:** Sunday 02:00-06:00 UTC
- **Notification:** 48 hours before
- **Emergency:** IT Director approval, 2 hour notice

## Emergency Contacts

| Role | Contact | Escalation |
|------|---------|-----------|
| Platform Architect | Gopi Krishna Vajrala | Primary |
| Cloud Operations | On-call rotation | 24/7 |
| IT Director | _______________ | Escalation |
| Security Team | _______________ | Security incidents |

---

**Author:** Gopi Krishna Vajrala
