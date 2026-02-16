# ECTP Deployment Guide

**Author:** Gopi Krishna Vajrala
**Version:** 1.0.0

---

## Prerequisites

| Tool | Version | Installation |
|------|---------|-------------|
| Python | >= 3.11 | python.org |
| Terraform | >= 1.6 | terraform.io |
| AWS CLI | >= 2.x | aws.amazon.com/cli |
| Docker | >= 24.x | docker.com |
| kubectl | >= 1.28 | kubernetes.io |

## Environment Setup

### 1. AWS Configuration
```bash
aws configure --profile ectp-dev
# Region: us-east-1
# Output: json
```

### 2. Terraform Initialization
```bash
cd infrastructure/terraform/environments/dev
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

### 3. Docker Build & Push
```bash
docker build -f deployment/docker/Dockerfile -t ectp-api .
aws ecr get-login-password | docker login --username AWS --password-stdin $ECR_URL
docker push $ECR_URL/ectp/api:latest
```

### 4. Deploy to ECS
```bash
./automation/scripts/deployment/deploy.sh dev 1.0.0
```

## Environment Deployment Matrix

| Environment | Deployment | Approval | Terraform Workspace |
|------------|-----------|----------|-------------------|
| Dev | Automatic on push to dev | None | ectp-dev |
| QA | Automatic on merge to dev | Team Lead | ectp-qa |
| UAT | Manual trigger | Product Owner | ectp-uat |
| Production | Manual trigger | Change Board | ectp-prod |

## Rollback Procedure

```bash
# Quick rollback: Revert ECS to previous task definition
./automation/scripts/rollback/rollback.sh <environment>

# Terraform rollback: Apply previous state
cd infrastructure/terraform/environments/<env>
terraform plan -target=<resource> -out=rollback.tfplan
terraform apply rollback.tfplan
```

## Post-Deployment Checklist

- [ ] Health check endpoint returning 200
- [ ] Readiness check passing (all dependencies)
- [ ] CloudWatch alarms not firing
- [ ] ServiceNow integration responding
- [ ] Ellucian Ethos API connected
- [ ] Cost governance dashboard loading
- [ ] No error spikes in logs
- [ ] Performance baseline maintained

## Troubleshooting

| Issue | Check | Resolution |
|-------|-------|-----------|
| Health check failing | ECS task logs | Check container startup errors |
| DB connection refused | Security groups | Verify DB security group rules |
| ServiceNow 401 | OAuth token | Refresh ServiceNow credentials |
| High latency | CloudWatch metrics | Scale ECS tasks or RDS instance |

---

**Author:** Gopi Krishna Vajrala
