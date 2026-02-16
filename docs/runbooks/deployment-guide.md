<div align="center">

# ECTP Deployment Guide

```
╔══════════════════════════════════════════════════════════════════╗
║                   ECTP DEPLOYMENT GUIDE                         ║
║               Enterprise Cloud Transformation Platform          ║
╚══════════════════════════════════════════════════════════════════╝
```

**Author:** Gopi Krishna Vajrala
**Version:** 1.0.0
**Last Updated:** 2026-02-16

</div>

---

## Prerequisites

> Ensure all tools are installed and meet minimum version requirements before proceeding.

| | Tool | Required Version | Installation | Status |
|---|---|---|---|---|
| :package: | **Python** | `>= 3.11` | [python.org](https://python.org) | `Required` |
| :package: | **Terraform** | `>= 1.6` | [terraform.io](https://terraform.io) | `Required` |
| :package: | **AWS CLI** | `>= 2.x` | [aws.amazon.com/cli](https://aws.amazon.com/cli) | `Required` |
| :package: | **Docker** | `>= 24.x` | [docker.com](https://docker.com) | `Required` |
| :package: | **kubectl** | `>= 1.28` | [kubernetes.io](https://kubernetes.io) | `Required` |

**Version Check Commands:**
```bash
python3 --version      # >= 3.11
terraform --version    # >= 1.6
aws --version          # >= 2.x
docker --version       # >= 24.x
kubectl version        # >= 1.28
```

---

## Deployment Pipeline Flow

```
DEPLOYMENT PIPELINE
══════════════════════════════════════════════════════════════════════════

  ┌─────────┐    ┌─────────┐    ┌─────────┐    ┌─────────┐
  │  STEP 1 │    │  STEP 2 │    │  STEP 3 │    │  STEP 4 │
  │   AWS   │───►│TERRAFORM│───►│ DOCKER  │───►│ DEPLOY  │
  │  CONFIG │    │  INIT   │    │ BUILD & │    │ TO ECS  │
  │         │    │         │    │  PUSH   │    │         │
  └─────────┘    └─────────┘    └─────────┘    └─────────┘
       │              │              │              │
       ▼              ▼              ▼              ▼
   Credentials   Infrastructure   Container     Service
   & Region      Provisioned      Registry      Running

══════════════════════════════════════════════════════════════════════════
```

---

## Environment Setup

### Step 1 - AWS Configuration

> :key: **Configure AWS credentials for the target environment**

```bash
# Configure AWS profile for target environment
aws configure --profile ectp-dev
# Region: us-east-1
# Output: json
```

| Parameter | Value |
|-----------|-------|
| Region | `us-east-1` |
| Output Format | `json` |
| Profile Name | `ectp-<environment>` |

---

### Step 2 - Terraform Initialization

> :building_construction: **Provision infrastructure resources**

```bash
# Navigate to environment-specific Terraform directory
cd infrastructure/terraform/environments/dev

# Initialize Terraform (downloads providers, configures backend)
terraform init

# Generate and review execution plan
terraform plan -out=tfplan

# Apply the plan
terraform apply tfplan
```

<details>
<summary><strong>Terraform Workflow Details</strong></summary>

```
TERRAFORM WORKFLOW
══════════════════════════════════════════════════════
  terraform init     Initialize providers & backend
       │
       ▼
  terraform plan     Preview changes (saved to tfplan)
       │
       ▼
  [REVIEW PLAN]      Manual review of proposed changes
       │
       ▼
  terraform apply    Apply approved changes
       │
       ▼
  [VERIFY]           Confirm resources created
══════════════════════════════════════════════════════
```

</details>

---

### Step 3 - Docker Build & Push

> :whale: **Build container image and push to ECR**

```bash
# Build the Docker image
docker build -f deployment/docker/Dockerfile -t ectp-api .

# Authenticate with ECR
aws ecr get-login-password | docker login --username AWS --password-stdin $ECR_URL

# Push image to ECR
docker push $ECR_URL/ectp/api:latest
```

<details>
<summary><strong>Docker Build Details</strong></summary>

| Stage | Command | Purpose |
|-------|---------|---------|
| **Build** | `docker build` | Create container image from Dockerfile |
| **Auth** | `ecr get-login-password` | Authenticate Docker with AWS ECR |
| **Push** | `docker push` | Upload image to container registry |

</details>

---

### Step 4 - Deploy to ECS

> :rocket: **Deploy the application to ECS**

```bash
# Deploy using the deployment script
./automation/scripts/deployment/deploy.sh dev 1.0.0
```

| Parameter | Description | Example |
|-----------|-------------|---------|
| `environment` | Target environment | `dev`, `qa`, `uat`, `prod` |
| `version` | Release version tag | `1.0.0` |

---

## Environment Deployment Matrix

```
DEPLOYMENT FLOW ACROSS ENVIRONMENTS
══════════════════════════════════════════════════════════════════════

  ┌─────────┐     ┌─────────┐     ┌─────────┐     ┌──────────┐
  │   DEV   │────►│   QA    │────►│   UAT   │────►│   PROD   │
  │  Auto   │     │  Auto   │     │ Manual  │     │  Manual  │
  │ on push │     │on merge │     │ trigger │     │ trigger  │
  └─────────┘     └─────────┘     └─────────┘     └──────────┘
  No Approval    Team Lead      Product Owner    Change Board
                 Approval        Approval         Approval

══════════════════════════════════════════════════════════════════════
```

| | Environment | Deployment Trigger | Approval Required | Terraform Workspace | Status |
|---|---|---|---|---|---|
| :green_circle: | **Dev** | Automatic on push to dev | None | `ectp-dev` | `Auto` |
| :blue_circle: | **QA** | Automatic on merge to dev | Team Lead | `ectp-qa` | `Auto` |
| :orange_circle: | **UAT** | Manual trigger | Product Owner | `ectp-uat` | `Manual` |
| :red_circle: | **Production** | Manual trigger | Change Board | `ectp-prod` | `Manual` |

---

## Rollback Procedure

> :warning: **WARNING:** Always verify the rollback target version before executing. Ensure database migrations are backward-compatible.

### Quick Rollback (ECS Task Definition)

```bash
# Revert ECS to the previous task definition revision
./automation/scripts/rollback/rollback.sh <environment>
```

### Terraform Rollback

```bash
# Navigate to the environment directory
cd infrastructure/terraform/environments/<env>

# Plan the rollback targeting specific resources
terraform plan -target=<resource> -out=rollback.tfplan

# Apply the rollback plan
terraform apply rollback.tfplan
```

<details>
<summary><strong>:warning: Rollback Decision Matrix</strong></summary>

| Scenario | Rollback Method | Estimated Time | Risk Level |
|----------|----------------|----------------|------------|
| Bad application code | ECS quick rollback | 2-5 minutes | :green_circle: Low |
| Infrastructure change | Terraform rollback | 5-15 minutes | :orange_circle: Medium |
| Database migration issue | Manual DB restore | 15-60 minutes | :red_circle: High |
| Full environment rebuild | Terraform destroy + apply | 30-90 minutes | :red_circle: Critical |

</details>

---

## Post-Deployment Checklist

> Complete **all** items before marking deployment as successful.

| | # | Verification Item | How to Verify | Expected Result |
|---|---|---|---|---|
| :white_check_mark: | 1 | Health check endpoint returning 200 | `curl https://<env>.ectp.edu/health` | HTTP 200 |
| :white_check_mark: | 2 | Readiness check passing (all dependencies) | `curl https://<env>.ectp.edu/ready` | HTTP 200 |
| :white_check_mark: | 3 | CloudWatch alarms not firing | AWS Console > CloudWatch > Alarms | All OK |
| :white_check_mark: | 4 | ServiceNow integration responding | Test API call to ServiceNow endpoint | HTTP 200 |
| :white_check_mark: | 5 | Ellucian Ethos API connected | Check Ellucian health endpoint | Connected |
| :white_check_mark: | 6 | Cost governance dashboard loading | Open cost dashboard URL | Dashboard renders |
| :white_check_mark: | 7 | No error spikes in logs | CloudWatch Logs Insights query | Error count baseline |
| :white_check_mark: | 8 | Performance baseline maintained | CloudWatch metrics comparison | Latency within SLA |

---

## Troubleshooting

<details>
<summary><strong>:red_circle: Health check failing</strong></summary>

**Symptom:** Health check endpoint not returning HTTP 200

**Check:** ECS task logs

**Resolution:**
```bash
# View ECS task logs for startup errors
aws logs tail /ecs/ectp-<env> --since 10m --filter-pattern "ERROR"

# Check if container is running
aws ecs describe-tasks --cluster ectp-<env> \
  --tasks $(aws ecs list-tasks --cluster ectp-<env> --query 'taskArns[0]' --output text)
```

Check container startup errors, environment variable configuration, and port binding.

</details>

<details>
<summary><strong>:red_circle: DB connection refused</strong></summary>

**Symptom:** Application cannot connect to RDS database

**Check:** Security groups

**Resolution:**
```bash
# Verify security group rules allow ECS to RDS
aws ec2 describe-security-groups --group-ids <db-sg-id> \
  --query 'SecurityGroups[0].IpPermissions'
```

Verify DB security group rules allow inbound from ECS security group on port 5432.

</details>

<details>
<summary><strong>:orange_circle: ServiceNow 401 Unauthorized</strong></summary>

**Symptom:** ServiceNow API returning 401

**Check:** OAuth token validity

**Resolution:**
```bash
# Refresh ServiceNow credentials in Secrets Manager
aws secretsmanager rotate-secret --secret-id ectp/servicenow/oauth
```

Refresh ServiceNow credentials and verify the OAuth configuration.

</details>

<details>
<summary><strong>:orange_circle: High latency after deployment</strong></summary>

**Symptom:** Response times exceeding SLA thresholds

**Check:** CloudWatch metrics

**Resolution:**
```bash
# Scale ECS tasks to handle load
aws ecs update-service --cluster ectp-<env> \
  --service ectp-api-<env> --desired-count 6

# Check RDS Performance Insights for slow queries
aws pi get-resource-metrics --service-type RDS \
  --identifier db-<instance-id> --metric-queries '[...]'
```

Scale ECS tasks or RDS instance, and check for slow database queries.

</details>

---

<div align="center">

```
══════════════════════════════════════════════════════════════
                  END OF DEPLOYMENT GUIDE
            Enterprise Cloud Transformation Platform
══════════════════════════════════════════════════════════════
```

**Author:** Gopi Krishna Vajrala

</div>
