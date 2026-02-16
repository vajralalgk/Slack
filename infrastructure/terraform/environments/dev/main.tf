# =============================================================================
# Enterprise Cloud Transformation Platform (ECTP) - Dev Environment
# =============================================================================
# Author: Gopi Krishna Vajrala
# Purpose: Root Terraform configuration for the ECTP development environment.
#          Orchestrates all infrastructure modules (networking, security,
#          compute, database, monitoring) to create a complete, functional
#          development environment.
#
# Architecture:
#   This file is the "composition root" that wires together all modules.
#   Each module is responsible for a specific infrastructure domain, and
#   this file passes outputs between modules to create the full stack.
#
# Module Dependency Graph:
#   security  --> networking (security needs VPC ID)
#   compute   --> networking (needs subnets), security (needs SG, IAM roles)
#   database  --> networking (needs subnets), security (needs SG, KMS, IAM)
#   monitoring --> compute (needs ECS cluster/service), database (needs RDS ID)
#
# Dev Environment Characteristics:
#   - Smaller instance sizes (cost optimization)
#   - Fewer AZs (2 instead of 3)
#   - Shorter log/backup retention
#   - Deletion protection disabled (for easy tear-down)
#   - Debug-level logging enabled
#
# Usage:
#   cd infrastructure/terraform/environments/dev
#   terraform init
#   terraform plan -var-file="terraform.tfvars"
#   terraform apply -var-file="terraform.tfvars"
#
# SECURITY NOTE:
#   - Never commit terraform.tfvars with real values to git
#   - Use terraform.tfvars.example as a template
#   - Store sensitive values in environment variables or Vault
# =============================================================================

# =============================================================================
# TERRAFORM CONFIGURATION
# =============================================================================
# Defines the Terraform version, required providers, and backend configuration
# for storing Terraform state remotely.
# =============================================================================
terraform {
  # Require Terraform 1.5+ for module features and improved validation.
  # WHY: Older versions may have known vulnerabilities or lack features
  #       (moved blocks, check blocks) used in these modules.
  required_version = ">= 1.5.0"

  # Required providers with version constraints.
  # WHY: Version pinning ensures reproducible builds across team members
  #       and CI/CD pipelines. Prevents supply-chain attacks.
  required_providers {
    # AWS provider for all cloud infrastructure.
    aws = {
      source  = "hashicorp/aws"    # Official HashiCorp AWS provider
      version = "~> 5.0"           # Allow 5.x patches, block 6.0+
    }
    # Random provider for generating secure passwords.
    random = {
      source  = "hashicorp/random" # Official HashiCorp random provider
      version = "~> 3.0"           # Stable version
    }
  }

  # Remote state backend configuration (S3 + DynamoDB).
  # WHAT: Stores Terraform state in S3 with DynamoDB locking to prevent
  #       concurrent modifications by multiple team members.
  # WHY: Local state files are:
  #       1. Not shareable between team members
  #       2. Not encrypted by default (state contains secrets!)
  #       3. Not protected against concurrent modifications
  #       4. Not backed up automatically
  # SECURITY: S3 state is encrypted with the specified KMS key.
  #           DynamoDB locking prevents state corruption from concurrent runs.
  # NOTE: The S3 bucket, DynamoDB table, and KMS key must exist before
  #        running `terraform init`. Create them manually or with a bootstrap script.
  # UNCOMMENT the backend block below after creating the prerequisite resources.
  #
  # backend "s3" {
  #   bucket         = "ectp-terraform-state-dev"           # S3 bucket for state storage
  #   key            = "dev/terraform.tfstate"               # State file path within the bucket
  #   region         = "us-east-1"                           # S3 bucket region
  #   dynamodb_table = "ectp-terraform-lock-dev"             # DynamoDB table for state locking
  #   encrypt        = true                                  # Encrypt state at rest in S3
  #   # kms_key_id   = "arn:aws:kms:us-east-1:ACCOUNT:key/KEY-ID"  # KMS key for encryption
  # }
}

# =============================================================================
# AWS PROVIDER CONFIGURATION
# =============================================================================
# WHAT: Configures the AWS provider with the target region and default tags.
# WHY: All resources created in this environment will be in this region
#       and inherit these default tags.
# SECURITY: Using an explicit region prevents accidental deployment to
#           the wrong region (which could violate data residency requirements).
# =============================================================================
provider "aws" {
  # AWS region for all resources in this environment.
  # WHY: us-east-1 is the primary region for most AWS services and has
  #       the widest service availability. For FERPA compliance, data must
  #       remain within US regions.
  # ALTERNATIVE: us-west-2 as a secondary region for disaster recovery.
  region = var.aws_region

  # Default tags applied to ALL resources created by this provider.
  # WHY: Ensures consistent tagging even if individual modules forget
  #       to apply tags. Tags enable cost allocation and governance.
  default_tags {
    tags = {
      Project     = var.project_name              # Project for cost allocation
      Environment = var.environment               # Environment tier
      ManagedBy   = "terraform"                   # IaC-managed
      Author      = "Gopi Krishna Vajrala"        # Original author
      Repository  = "ectp-infrastructure"         # Source code repository
    }
  }
}

# =============================================================================
# INPUT VARIABLES
# =============================================================================

variable "project_name" {
  # WHAT: Project identifier used in resource naming and tagging.
  description = "Project name for resource naming and cost allocation"
  type        = string
  default     = "ectp"
}

variable "environment" {
  # WHAT: Deployment environment tier.
  description = "Deployment environment (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "aws_region" {
  # WHAT: AWS region for all resources.
  description = "AWS region for infrastructure deployment"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  # WHAT: VPC IP address range.
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "container_image" {
  # WHAT: Docker image URI for the ECTP FastAPI application.
  # WHY: This must be set to the actual ECR repository URI.
  description = "Docker image URI for the ECTP FastAPI application (e.g., ACCOUNT.dkr.ecr.REGION.amazonaws.com/ectp-app:latest)"
  type        = string
}

variable "container_port" {
  # WHAT: Port the FastAPI application listens on inside the container.
  description = "Container port for the FastAPI application"
  type        = number
  default     = 8000
}

variable "acm_certificate_arn" {
  # WHAT: ARN of the ACM certificate for HTTPS on the ALB.
  # WHY: Required for HTTPS listener. Must be created/imported before applying.
  description = "ARN of the ACM certificate for ALB HTTPS listener"
  type        = string
}

variable "db_name" {
  # WHAT: PostgreSQL database name.
  description = "Name of the PostgreSQL database"
  type        = string
  default     = "ectp_db"
}

variable "db_master_username" {
  # WHAT: Master username for the RDS instance.
  # SECURITY: Avoid common names like 'admin' or 'postgres'.
  description = "Master username for the RDS PostgreSQL instance"
  type        = string
  default     = "ectp_admin"
}

variable "alert_email" {
  # WHAT: Email address for receiving monitoring alerts.
  description = "Email address for CloudWatch alarm notifications"
  type        = string
  default     = ""
}

# =============================================================================
# MODULE: SECURITY
# =============================================================================
# WHAT: Provisions KMS keys, IAM roles, security groups, and Secrets Manager
#       secrets. This module runs FIRST because other modules depend on its
#       outputs (KMS key ARN, security group IDs, IAM role ARNs).
# WHY: Security infrastructure must exist before compute or data resources
#       can be created with proper encryption and access controls.
# DEPENDENCIES: VPC ID from networking module. However, since security groups
#               need VPC ID and the VPC is in the networking module, we use
#               a two-phase approach where security depends on networking.
# =============================================================================
module "networking" {
  # Source path relative to this file.
  # WHY: Using relative paths for local modules ensures portability.
  source = "../../modules/networking"

  # Pass project identification variables.
  project_name = var.project_name
  environment  = var.environment

  # VPC CIDR block for the dev environment.
  # WHY: 10.0.0.0/16 provides 65,536 addresses, more than enough for dev.
  vpc_cidr = var.vpc_cidr

  # Subnet CIDR allocations for the 4-tier architecture.
  # WHY: Each tier gets its own /24 subnet per AZ for clear segmentation.
  # DEV: Using only 2 AZs to save NAT Gateway costs (~$64/month savings).
  public_subnet_cidrs       = ["10.0.1.0/24", "10.0.2.0/24"]
  private_app_subnet_cidrs  = ["10.0.11.0/24", "10.0.12.0/24"]
  private_data_subnet_cidrs = ["10.0.21.0/24", "10.0.22.0/24"]
  isolated_subnet_cidrs     = ["10.0.31.0/24", "10.0.32.0/24"]

  # Use 2 AZs for dev (saves one NAT Gateway cost).
  # WHY: Dev doesn't need the same level of fault tolerance as production.
  #       2 AZs still provide basic HA for RDS Multi-AZ.
  # PROD: Override to 3 for production-grade resilience.
  az_count = 2

  # Shorter log retention for dev (cost savings).
  # WHY: Dev flow logs are primarily for debugging, not compliance.
  #       90 days is sufficient for troubleshooting network issues.
  # PROD: Override to 365 or more for compliance requirements.
  flow_log_retention_days = 90

  # KMS key for encrypting flow logs.
  # WHY: Uses the KMS key from the security module for consistent encryption.
  kms_key_arn = module.security.kms_key_arn

  # Additional tags for the networking module.
  tags = {
    CostCenter = "engineering-dev"    # Cost allocation to dev team budget
  }
}

# =============================================================================
# MODULE: SECURITY
# =============================================================================
# WHAT: Creates KMS keys, IAM roles, and security groups.
# WHY: Must be created before compute and database modules need them.
# NOTE: Security groups reference the VPC ID from the networking module.
# =============================================================================
module "security" {
  source = "../../modules/security"

  # Project identification.
  project_name = var.project_name
  environment  = var.environment

  # VPC reference for security group creation.
  # WHY: Security groups are VPC-scoped; they must be created in the
  #       same VPC as the resources they protect.
  vpc_id   = module.networking.vpc_id
  vpc_cidr = module.networking.vpc_cidr

  # Container port for security group rules.
  # WHY: Security group rules between ALB and ECS tasks use this port.
  container_port = var.container_port

  # Additional tags.
  tags = {
    CostCenter = "engineering-dev"
  }
}

# =============================================================================
# MODULE: COMPUTE
# =============================================================================
# WHAT: Provisions the ECS Fargate cluster, task definitions, ALB, and
#       auto scaling for the ECTP FastAPI application.
# WHY: The compute layer runs the application code and handles user traffic.
# DEPENDENCIES:
#   - networking: Subnet IDs for ALB and ECS task placement
#   - security: Security group IDs, IAM role ARNs, KMS key ARN
# =============================================================================
module "compute" {
  source = "../../modules/compute"

  # Project identification.
  project_name = var.project_name
  environment  = var.environment

  # Container configuration.
  # WHY: Specifies what Docker image to run and on which port.
  container_image = var.container_image
  container_port  = var.container_port

  # Dev-appropriate resource allocation.
  # WHY: Smaller resources for dev to reduce costs.
  #       0.5 vCPU and 1 GB memory is sufficient for development workloads.
  # PROD: Override to 1024 (1 vCPU) / 2048 (2 GB) or larger.
  task_cpu    = 512     # 0.5 vCPU (dev-sized)
  task_memory = 1024    # 1 GB memory (dev-sized)

  # Task count and scaling configuration.
  # WHY: Dev needs fewer tasks than production.
  #       1 task minimum keeps costs low while maintaining a running service.
  # PROD: Override min_capacity=3, max_capacity=20, desired_count=3.
  desired_count = 1     # Start with 1 task for dev
  min_capacity  = 1     # Minimum 1 task (never scale to zero)
  max_capacity  = 4     # Maximum 4 tasks for dev load testing

  # Network configuration from networking module.
  # WHY: ALB goes in public subnets; ECS tasks go in private app subnets.
  vpc_id                 = module.networking.vpc_id
  public_subnet_ids      = module.networking.public_subnet_ids
  private_app_subnet_ids = module.networking.private_app_subnet_ids

  # Security configuration from security module.
  # WHY: Each resource gets its appropriate security group and IAM role.
  alb_security_group_id  = module.security.alb_security_group_id
  ecs_security_group_id  = module.security.app_security_group_id
  ecs_execution_role_arn = module.security.ecs_task_execution_role_arn
  ecs_task_role_arn      = module.security.ecs_task_role_arn

  # KMS key for encrypting CloudWatch logs.
  kms_key_arn = module.security.kms_key_arn

  # ACM certificate for HTTPS.
  acm_certificate_arn = var.acm_certificate_arn

  # Health check configuration.
  # WHY: The FastAPI application exposes /health for ALB health checks.
  health_check_path = "/health"

  # Log retention for dev.
  # WHY: 30 days is sufficient for dev debugging.
  # PROD: Override to 90 or 365 days.
  log_retention_days = 30

  # Secrets to inject into containers.
  # WHY: Database credentials are fetched from Secrets Manager at startup.
  # FORMAT: List of {name, valueFrom} objects for ECS task definition.
  container_secrets = [
    {
      name      = "DATABASE_URL"
      valueFrom = "${module.security.db_secret_arn}:url::"
    },
    {
      name      = "DB_PASSWORD"
      valueFrom = "${module.security.db_secret_arn}:password::"
    }
  ]

  # Additional tags.
  tags = {
    CostCenter = "engineering-dev"
  }
}

# =============================================================================
# MODULE: DATABASE
# =============================================================================
# WHAT: Provisions the RDS PostgreSQL database with Multi-AZ, encryption,
#       and automated backups.
# WHY: The database stores all ECTP application data including student
#       records and institutional information.
# DEPENDENCIES:
#   - networking: Private data subnet IDs for RDS placement
#   - security: Database security group ID, KMS key ARN, IAM role ARN
# =============================================================================
module "database" {
  source = "../../modules/database"

  # Project identification.
  project_name = var.project_name
  environment  = var.environment

  # Database configuration.
  # WHY: PostgreSQL 15 provides the latest features and security patches.
  db_name              = var.db_name
  db_master_username   = var.db_master_username
  engine_version       = "15.4"      # PostgreSQL 15.4 (latest minor version)
  engine_major_version = "15"         # Major version for parameter group family

  # Dev-appropriate instance sizing.
  # WHY: db.t3.medium is a burstable instance type suitable for dev workloads.
  #       It provides 2 vCPUs and 4 GB memory with burst capability.
  # COST: Approximately $50/month (compared to ~$200/month for db.r6g.large).
  # PROD: Override to db.r6g.large or db.r6g.xlarge for consistent performance.
  instance_class = "db.t3.medium"

  # Storage configuration.
  # WHY: 20 GB is sufficient for dev data. Autoscaling to 100 GB handles growth.
  # PROD: Override to allocated_storage=100, max_allocated_storage=500.
  allocated_storage     = 20    # 20 GB initial storage
  max_allocated_storage = 100   # Allow autoscaling to 100 GB

  # Multi-AZ for dev.
  # WHY: true for testing failover scenarios; set to false to save ~$50/month.
  # SECURITY: Multi-AZ provides AZ-level fault isolation for data protection.
  multi_az = true

  # Backup configuration.
  # WHY: 7-day retention for dev is sufficient for accidental data loss recovery.
  # PROD: Override to 35 days (maximum) for compliance.
  backup_retention_period = 7
  backup_window           = "04:00-05:00"      # 4-5 AM UTC (11 PM-midnight EST)
  maintenance_window      = "sun:05:00-sun:06:00"  # Sunday 5-6 AM UTC

  # Monitoring configuration.
  # WHY: 60-second Enhanced Monitoring for dev. Provides OS-level metrics.
  monitoring_interval      = 60
  rds_monitoring_role_arn  = module.security.rds_monitoring_role_arn

  # Log retention.
  log_retention_days = 30

  # Network configuration from networking module.
  # WHY: Database is placed in private data subnets for network isolation.
  private_data_subnet_ids = module.networking.private_data_subnet_ids

  # Security configuration from security module.
  # WHY: Database security group restricts access to only the app tier.
  db_security_group_id = module.security.db_security_group_id
  kms_key_arn          = module.security.kms_key_arn

  # Additional tags.
  tags = {
    CostCenter         = "engineering-dev"
    DataClassification = "confidential"  # Student data classification
  }
}

# =============================================================================
# MODULE: MONITORING
# =============================================================================
# WHAT: Creates CloudWatch dashboards, alarms, and SNS topics for alerting.
# WHY: Monitoring is essential for detecting issues before they impact users
#       and for maintaining SLA compliance.
# DEPENDENCIES:
#   - compute: ECS cluster name, service name, ALB ARN suffix
#   - database: RDS instance ID
#   - security: KMS key ARN for encrypting SNS messages
# =============================================================================
module "monitoring" {
  source = "../../modules/monitoring"

  # Project identification.
  project_name = var.project_name
  environment  = var.environment
  aws_region   = var.aws_region

  # ECS monitoring targets from compute module.
  # WHY: Alarms and dashboard widgets reference these identifiers to
  #       monitor the correct ECS cluster and service.
  ecs_cluster_name = module.compute.ecs_cluster_name
  ecs_service_name = module.compute.ecs_service_name

  # ALB monitoring targets from compute module.
  # WHY: ALB metrics use the ARN suffix format for CloudWatch dimensions.
  alb_arn_suffix         = module.compute.alb_arn_suffix
  target_group_arn_suffix = module.compute.target_group_arn_suffix

  # Database monitoring targets from database module.
  # WHY: RDS alarms reference the DB instance identifier.
  db_instance_id = module.database.db_instance_id

  # Database connection threshold for alarming.
  # WHY: db.t3.medium supports ~120 max connections.
  #       Alert at 80% (96 connections) to prevent exhaustion.
  # PROD: Adjust based on the production instance type's max_connections.
  db_max_connections_threshold = 96

  # KMS key for encrypting SNS messages.
  kms_key_arn = module.security.kms_key_arn

  # Alert email for notifications.
  # WHY: Email subscription requires manual confirmation after creation.
  alert_email = var.alert_email

  # Additional tags.
  tags = {
    CostCenter = "engineering-dev"
  }
}

# =============================================================================
# OUTPUTS
# =============================================================================
# Outputs provide essential information for the development team:
# - Application URL for testing
# - Database connection details for debugging
# - Resource identifiers for AWS console navigation
# =============================================================================

output "vpc_id" {
  # WHAT: The VPC ID for reference in other configurations.
  description = "VPC ID for the dev environment"
  value       = module.networking.vpc_id
}

output "alb_dns_name" {
  # WHAT: The DNS name of the Application Load Balancer.
  # WHY: Use this to access the ECTP application in the dev environment.
  #       Create a CNAME DNS record pointing to this ALB DNS name.
  description = "ALB DNS name for accessing the ECTP application (create a CNAME record pointing to this)"
  value       = module.compute.alb_dns_name
}

output "ecs_cluster_name" {
  # WHAT: ECS cluster name for console navigation and CLI commands.
  description = "ECS cluster name for AWS console navigation and CLI commands"
  value       = module.compute.ecs_cluster_name
}

output "ecs_service_name" {
  # WHAT: ECS service name for deployment and scaling commands.
  description = "ECS service name for deployments and scaling"
  value       = module.compute.ecs_service_name
}

output "db_endpoint" {
  # WHAT: RDS endpoint for database connections.
  # SECURITY: This endpoint is only resolvable within the VPC.
  description = "RDS PostgreSQL endpoint (only accessible from within the VPC)"
  value       = module.database.db_endpoint
}

output "db_credentials_secret_arn" {
  # WHAT: Secrets Manager ARN for retrieving database credentials.
  # WHY: Use this ARN with `aws secretsmanager get-secret-value` to
  #       retrieve the database credentials for debugging.
  description = "Secrets Manager secret ARN containing database credentials"
  value       = module.security.db_secret_arn
}

output "dashboard_url" {
  # WHAT: URL to the CloudWatch monitoring dashboard.
  # WHY: Quick link for the team to monitor the dev environment.
  description = "CloudWatch dashboard URL for monitoring the dev environment"
  value       = "https://${var.aws_region}.console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=${module.monitoring.dashboard_name}"
}

output "nat_gateway_ips" {
  # WHAT: Public IPs of NAT Gateways.
  # WHY: Needed for third-party API firewall allowlisting.
  description = "NAT Gateway public IPs for third-party firewall allowlisting"
  value       = module.networking.nat_gateway_public_ips
}

output "kms_key_arn" {
  # WHAT: KMS key ARN for encrypting additional resources.
  description = "KMS key ARN used for encryption across all ECTP services"
  value       = module.security.kms_key_arn
}
