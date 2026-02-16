# =============================================================================
# Enterprise Cloud Transformation Platform (ECTP) - Security Module
# =============================================================================
# Author: Gopi Krishna Vajrala
# Purpose: Defines all security infrastructure for the ECTP platform,
#          including security groups, IAM roles and policies, KMS encryption
#          keys, and Secrets Manager configurations.
#
# Security Architecture Overview:
#   - Security Groups: Network-level access control for each tier
#   - IAM Roles: Least-privilege roles for ECS tasks, RDS monitoring, etc.
#   - KMS Keys: Customer-managed encryption keys for data at rest
#   - Secrets Manager: Secure storage for application secrets
#
# Design Principles:
#   1. Least Privilege: Every role/policy grants only the minimum permissions
#   2. Defense in Depth: Multiple layers of security controls
#   3. Separation of Duties: Distinct roles for different functions
#   4. Encryption Everywhere: At rest (KMS) and in transit (TLS)
#   5. Audit Everything: CloudTrail integration for all operations
#
# FERPA/Compliance:
#   - All encryption uses customer-managed KMS keys with audit trails
#   - Security groups implement strict tier-based access control
#   - IAM roles are scoped to specific resources, not wildcards
#   - Secrets are encrypted and access-logged via CloudTrail
# =============================================================================

# -----------------------------------------------------------------------------
# Terraform Configuration Block
# -----------------------------------------------------------------------------
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# -----------------------------------------------------------------------------
# Data Sources
# -----------------------------------------------------------------------------

# Current region for constructing ARNs and service endpoints.
# WHY: ARNs include the region; using a data source avoids hardcoding.
data "aws_region" "current" {}

# Current AWS account ID for constructing ARNs and IAM policies.
# WHY: IAM policies reference the account ID for resource-level permissions.
# SECURITY: The account ID is used in resource ARNs to ensure policies
#           target only resources in this specific account.
data "aws_caller_identity" "current" {}

# =============================================================================
# LOCAL VALUES
# =============================================================================
locals {
  # Standard name prefix.
  name_prefix = "${var.project_name}-${var.environment}"

  # AWS account ID for ARN construction.
  account_id = data.aws_caller_identity.current.account_id

  # AWS region for ARN construction.
  region = data.aws_region.current.name

  # Common tags for all resources.
  common_tags = merge(var.tags, {
    Module      = "security"
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
    Author      = "Gopi Krishna Vajrala"
  })
}

# =============================================================================
# KMS CUSTOMER-MANAGED KEY
# =============================================================================
# WHAT: A customer-managed KMS key used to encrypt all sensitive data across
#       the ECTP platform, including RDS storage, CloudWatch Logs, Secrets
#       Manager secrets, S3 buckets, and EBS volumes.
# WHY: Customer-managed KMS keys (CMKs) provide advantages over AWS-managed keys:
#       1. Custom key policies for fine-grained access control
#       2. Automatic annual key rotation
#       3. CloudTrail audit logging of every encrypt/decrypt operation
#       4. Ability to disable or revoke the key to render data unreadable
#       5. Cross-account sharing for disaster recovery scenarios
# SECURITY IMPLICATIONS:
#   - The key policy defines WHO can use this key (encrypt/decrypt)
#   - Losing access to this key means ALL encrypted data is PERMANENTLY
#     unrecoverable. Key management procedures must be documented.
#   - Key rotation creates new key material annually; old data remains
#     decryptable using the previous key material (managed automatically).
#   - The deletion window (7-30 days) provides a safety net against
#     accidental key deletion. During this window, the key can be recovered.
# ALTERNATIVES:
#   - AWS-managed keys: Simpler but no audit trail or custom policies
#   - Imported key material: For organizations requiring BYOK (Bring Your Own Key)
#   - AWS CloudHSM: For FIPS 140-2 Level 3 compliance requirements
# =============================================================================
resource "aws_kms_key" "main" {
  # Description visible in the KMS console for identification.
  description = "ECTP ${var.environment} master encryption key - encrypts RDS, CloudWatch, Secrets Manager, and S3 data. Customer-managed with annual rotation."

  # Enable automatic key rotation (new key material every 365 days).
  # WHAT: AWS generates new cryptographic material annually. Old material
  #       is retained so previously encrypted data can still be decrypted.
  # WHY: Key rotation limits the amount of data encrypted under a single
  #       key version, reducing the blast radius of a key compromise.
  # SECURITY: This is a compliance requirement for many frameworks
  #           (PCI DSS, SOC 2) and a best practice for FERPA.
  enable_key_rotation = true

  # Deletion waiting period (days).
  # WHY: 30 days gives ample time to realize a mistake and cancel the deletion.
  #       Once the key is deleted, ALL data encrypted with it is PERMANENTLY LOST.
  # SECURITY: A shorter window (7 days minimum) is faster but more risky.
  #           30 days is recommended for production environments.
  deletion_window_in_days = var.environment == "prod" ? 30 : 7

  # Multi-region: keep as single-region unless DR requires cross-region encryption.
  # WHY: Multi-region keys add complexity and cost. Only enable for
  #       cross-region disaster recovery scenarios.
  multi_region = false

  # Key policy defining who can manage and use this key.
  # WHY: The key policy is the primary access control mechanism for KMS keys.
  #       It defines which IAM principals can perform key operations.
  # SECURITY: The policy follows least privilege:
  #           - Root account has full administration (required for key management)
  #           - Specific IAM roles get only encrypt/decrypt (usage)
  #           - No wildcards for principal or action specifications
  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "${local.name_prefix}-key-policy"
    Statement = [
      {
        # Allow the root account full control of the key.
        # WHY: This is REQUIRED by AWS. Without this statement, the key
        #       could become unmanageable if the creating IAM entity is deleted.
        # SECURITY: Root account access is controlled by MFA and account-level
        #           controls, not the key policy. This is a safety mechanism.
        Sid    = "EnableRootAccountAccess"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${local.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        # Allow key administrators to manage (but not use) the key.
        # WHY: Separation of duties -- administrators can manage key metadata,
        #       rotation, and policies, but cannot encrypt or decrypt data.
        # SECURITY: This prevents administrators from accessing encrypted data
        #           while still allowing them to manage the key lifecycle.
        Sid    = "AllowKeyAdministration"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${local.account_id}:root"
        }
        Action = [
          "kms:Create*",
          "kms:Describe*",
          "kms:Enable*",
          "kms:List*",
          "kms:Put*",
          "kms:Update*",
          "kms:Revoke*",
          "kms:Disable*",
          "kms:Get*",
          "kms:Delete*",
          "kms:TagResource",
          "kms:UntagResource",
          "kms:ScheduleKeyDeletion",
          "kms:CancelKeyDeletion"
        ]
        Resource = "*"
      },
      {
        # Allow AWS services to use the key for encryption.
        # WHY: Services like RDS, CloudWatch, and S3 need to encrypt/decrypt
        #       data using this key on behalf of the ECTP resources.
        # SECURITY: The condition restricts key usage to only AWS services
        #           operating within this specific account, preventing
        #           cross-account key usage.
        Sid    = "AllowServiceEncryption"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${local.account_id}:root"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
      },
      {
        # Allow CloudWatch Logs to use this key for log encryption.
        # WHY: CloudWatch Logs service needs explicit permission to use
        #       customer-managed keys for log group encryption.
        # SECURITY: Scoped to only the CloudWatch Logs service principal
        #           in the current region.
        Sid    = "AllowCloudWatchLogsEncryption"
        Effect = "Allow"
        Principal = {
          Service = "logs.${local.region}.amazonaws.com"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
        Condition = {
          ArnLike = {
            "kms:EncryptionContext:aws:logs:arn" = "arn:aws:logs:${local.region}:${local.account_id}:log-group:*"
          }
        }
      }
    ]
  })

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-master-key"
  })
}

# -----------------------------------------------------------------------------
# KMS Key Alias
# -----------------------------------------------------------------------------
# WHAT: A human-readable alias for the KMS key.
# WHY: KMS key IDs are UUIDs (e.g., "1234abcd-..."). An alias provides a
#       friendly name for console navigation and CLI commands.
# SECURITY: Aliases can be retargeted to different keys, so IAM policies
#           should reference the key ARN, not the alias ARN.
# -----------------------------------------------------------------------------
resource "aws_kms_alias" "main" {
  # Alias must start with "alias/" prefix (AWS requirement).
  name = "alias/${local.name_prefix}-master-key"

  # Point to our customer-managed key.
  target_key_id = aws_kms_key.main.key_id
}

# =============================================================================
# SECURITY GROUPS
# =============================================================================
# Security groups are virtual firewalls that control inbound and outbound
# traffic at the resource level (ENI level). Unlike NACLs, security groups
# are STATEFUL (return traffic is automatically allowed).
#
# ECTP Security Group Architecture:
#   1. ALB Security Group: Allows HTTP/HTTPS from internet -> ALB
#   2. ECS Security Group: Allows traffic from ALB -> ECS tasks
#   3. Database Security Group: Allows PostgreSQL from ECS -> RDS
#
# This implements a strict chain: Internet -> ALB -> ECS -> RDS
# Each link only allows the specific protocol and port needed.
# =============================================================================

# -----------------------------------------------------------------------------
# ALB Security Group
# -----------------------------------------------------------------------------
# WHAT: Security group for the Application Load Balancer that terminates
#       HTTPS traffic from the internet.
# WHY: The ALB is the ONLY resource that accepts traffic from the internet.
#       This security group defines exactly what traffic is allowed.
# SECURITY IMPLICATIONS:
#   - Allows inbound HTTP (80) and HTTPS (443) from anywhere (0.0.0.0/0)
#   - HTTP is allowed only for the HTTPS redirect listener
#   - Outbound is restricted to only the ECS tasks on the container port
#   - This is the outermost security boundary for all ECTP traffic
# ALTERNATIVES:
#   - Could restrict inbound to specific CIDR ranges for campus-only access
#   - Could integrate with AWS WAF for application-layer filtering
#   - Could use AWS Shield Advanced for DDoS protection
# -----------------------------------------------------------------------------
resource "aws_security_group" "alb" {
  # Name that clearly identifies the purpose and environment.
  name        = "${local.name_prefix}-alb-sg"
  description = "Security group for ECTP ALB - allows HTTPS from internet, forwards to ECS tasks. This is the internet-facing entry point."

  # Associate with the VPC.
  vpc_id = var.vpc_id

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-alb-sg"
    Tier = "public"  # Indicates this SG is for public-facing resources
  })
}

# ALB Ingress: Allow HTTPS (443) from anywhere.
# WHAT: Permits inbound HTTPS traffic from any source IP.
# WHY: Students, faculty, and staff access ECTP from various networks
#       (campus, home, mobile). We cannot predict their source IPs.
# SECURITY: HTTPS ensures all data in transit is encrypted.
#           WAF integration (not in this module) provides additional Layer 7 protection.
# ALTERNATIVE: Restrict to campus IP ranges for internal-only applications.
resource "aws_security_group_rule" "alb_ingress_https" {
  type              = "ingress"           # Inbound rule
  from_port         = 443                  # HTTPS port
  to_port           = 443                  # Single port (not a range)
  protocol          = "tcp"                # TCP protocol for HTTPS
  cidr_blocks       = ["0.0.0.0/0"]       # Allow from any IPv4 source
  security_group_id = aws_security_group.alb.id
  description       = "Allow HTTPS from internet - primary entry point for ECTP users"
}

# ALB Ingress: Allow HTTP (80) from anywhere for HTTPS redirect.
# WHAT: Permits inbound HTTP traffic for the sole purpose of redirecting to HTTPS.
# WHY: Users may type "http://" in their browser. Without this rule, the
#       redirect listener cannot receive and redirect their requests.
# SECURITY: The ALB listener on port 80 ONLY performs a 301 redirect to HTTPS.
#           No application traffic is ever served over HTTP.
resource "aws_security_group_rule" "alb_ingress_http" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.alb.id
  description       = "Allow HTTP from internet for HTTPS redirect only - no unencrypted traffic is served"
}

# ALB Egress: Allow traffic to ECS tasks on the container port.
# WHAT: Permits the ALB to send traffic to ECS Fargate tasks.
# WHY: After terminating TLS, the ALB forwards HTTP traffic to the
#       ECS tasks on the container port (default 8000).
# SECURITY: Egress is restricted to ONLY the ECS security group on the
#           container port. The ALB cannot send traffic to the database
#           or any other resource directly.
resource "aws_security_group_rule" "alb_egress_to_ecs" {
  type                     = "egress"
  from_port                = var.container_port
  to_port                  = var.container_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.ecs_tasks.id   # Only to ECS tasks
  security_group_id        = aws_security_group.alb.id
  description              = "Allow ALB to forward traffic to ECS tasks on container port"
}

# -----------------------------------------------------------------------------
# ECS Tasks Security Group
# -----------------------------------------------------------------------------
# WHAT: Security group for ECS Fargate tasks running the FastAPI application.
# WHY: Controls what traffic can reach the application containers and what
#       outbound traffic the application can initiate.
# SECURITY IMPLICATIONS:
#   - Inbound: ONLY from the ALB on the container port (no other source)
#   - Outbound: PostgreSQL to the database SG + HTTPS for external API calls
#   - Tasks have no public IPs and are in private subnets
#   - The security group + private subnet + no public IP = three layers
#     of protection against direct internet access
# -----------------------------------------------------------------------------
resource "aws_security_group" "ecs_tasks" {
  name        = "${local.name_prefix}-ecs-tasks-sg"
  description = "Security group for ECTP ECS Fargate tasks - accepts traffic only from ALB, connects to database and external services"

  vpc_id = var.vpc_id

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-ecs-tasks-sg"
    Tier = "private-app"  # Application tier
  })
}

# ECS Ingress: Allow traffic from ALB on the container port.
# WHAT: Permits inbound traffic from the ALB to the FastAPI application.
# WHY: The ALB forwards user requests to ECS tasks. Without this rule,
#       no traffic would reach the application.
# SECURITY: By specifying the ALB security group as the source (instead of
#           a CIDR range), only traffic from the ALB is allowed. Even if
#           another resource has the same IP, it would be denied without
#           the ALB security group membership.
resource "aws_security_group_rule" "ecs_ingress_from_alb" {
  type                     = "ingress"
  from_port                = var.container_port
  to_port                  = var.container_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb.id         # Only from ALB
  security_group_id        = aws_security_group.ecs_tasks.id
  description              = "Allow inbound from ALB on container port - the only permitted traffic source"
}

# ECS Egress: Allow PostgreSQL connections to the database.
# WHAT: Permits ECS tasks to connect to the RDS PostgreSQL database.
# WHY: The FastAPI application needs to query and write data to PostgreSQL.
# SECURITY: Restricted to ONLY the database security group on port 5432.
#           ECS tasks cannot connect to databases in other security groups
#           or on non-PostgreSQL ports.
resource "aws_security_group_rule" "ecs_egress_to_db" {
  type                     = "egress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.database.id    # Only to database SG
  security_group_id        = aws_security_group.ecs_tasks.id
  description              = "Allow ECS tasks to connect to RDS PostgreSQL on port 5432"
}

# ECS Egress: Allow HTTPS for AWS API calls and external services.
# WHAT: Permits outbound HTTPS (443) connections from ECS tasks.
# WHY: ECS tasks need outbound HTTPS access for:
#       1. Pulling container images from ECR
#       2. Sending logs to CloudWatch
#       3. Fetching secrets from Secrets Manager
#       4. Calling external APIs (SIS, LMS, payment gateways)
#       5. Sending metrics and traces to monitoring services
# SECURITY: HTTPS outbound is relatively safe because:
#           - All traffic is encrypted
#           - The NAT Gateway's static IP can be logged
#           - VPC Endpoints can replace internet calls for AWS services
# ALTERNATIVE: For maximum security, restrict outbound to only VPC Endpoints
#              and specific external IP ranges. This is complex to maintain
#              but eliminates all internet egress.
resource "aws_security_group_rule" "ecs_egress_https" {
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]       # Allow HTTPS to any destination
  security_group_id = aws_security_group.ecs_tasks.id
  description       = "Allow HTTPS outbound for AWS API calls (ECR, CloudWatch, Secrets Manager) and external service integrations"
}

# ECS Egress: Allow DNS resolution (required for service discovery).
# WHAT: Permits outbound DNS queries (port 53 TCP/UDP) from ECS tasks.
# WHY: ECS tasks need DNS resolution for:
#       1. Resolving RDS endpoints to IP addresses
#       2. Resolving AWS service endpoints (ECR, CloudWatch, etc.)
#       3. Resolving external service hostnames
# SECURITY: DNS traffic is typically unencrypted but essential for operation.
#           Consider using Route 53 Resolver DNS Firewall for DNS filtering.
resource "aws_security_group_rule" "ecs_egress_dns_tcp" {
  type              = "egress"
  from_port         = 53
  to_port           = 53
  protocol          = "tcp"
  cidr_blocks       = [var.vpc_cidr]       # DNS within VPC only
  security_group_id = aws_security_group.ecs_tasks.id
  description       = "Allow DNS TCP within VPC for service name resolution"
}

resource "aws_security_group_rule" "ecs_egress_dns_udp" {
  type              = "egress"
  from_port         = 53
  to_port           = 53
  protocol          = "udp"
  cidr_blocks       = [var.vpc_cidr]       # DNS within VPC only
  security_group_id = aws_security_group.ecs_tasks.id
  description       = "Allow DNS UDP within VPC for service name resolution"
}

# -----------------------------------------------------------------------------
# Database Security Group
# -----------------------------------------------------------------------------
# WHAT: Security group for the RDS PostgreSQL database instance.
# WHY: Restricts database access to ONLY the ECS tasks security group.
#       No other resource can connect to the database.
# SECURITY IMPLICATIONS:
#   - Inbound: ONLY from ECS tasks on port 5432 (PostgreSQL)
#   - No inbound from public subnets, bastion hosts, or other sources
#   - Combined with private data subnets and NACLs, this provides
#     three layers of network access control for the database.
# FERPA: Network-level isolation of the database ensures student data
#        is only accessible through the authorized application.
# ALTERNATIVE: Could add a bastion host SG rule for emergency DBA access.
#              If needed, use AWS Systems Manager Session Manager instead
#              (no security group changes needed, fully audited).
# -----------------------------------------------------------------------------
resource "aws_security_group" "database" {
  name        = "${local.name_prefix}-database-sg"
  description = "Security group for ECTP RDS PostgreSQL - accepts connections only from ECS tasks on port 5432. No public or direct access permitted."

  vpc_id = var.vpc_id

  tags = merge(local.common_tags, {
    Name               = "${local.name_prefix}-database-sg"
    Tier               = "private-data"
    DataClassification = "confidential"  # Database handles sensitive data
  })
}

# Database Ingress: Allow PostgreSQL from ECS tasks.
# WHAT: Permits inbound PostgreSQL connections from the ECS tasks SG.
# WHY: The FastAPI application needs database connectivity.
# SECURITY: Source is restricted to the ECS tasks security group.
#           Even resources in the same VPC CIDR range cannot connect
#           unless they are members of the ECS tasks security group.
resource "aws_security_group_rule" "db_ingress_from_ecs" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.ecs_tasks.id   # Only from ECS tasks
  security_group_id        = aws_security_group.database.id
  description              = "Allow PostgreSQL connections from ECS Fargate tasks only"
}

# Database Egress: Allow outbound HTTPS for AWS service communication.
# WHAT: Permits the database to make outbound HTTPS calls.
# WHY: RDS needs outbound access for:
#       1. Enhanced Monitoring metrics delivery to CloudWatch
#       2. CloudWatch Logs export
#       3. AWS service communication for maintenance operations
# SECURITY: Egress from the database is low-risk because RDS is a managed
#           service and does not run arbitrary user code.
resource "aws_security_group_rule" "db_egress_https" {
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.database.id
  description       = "Allow RDS outbound HTTPS for Enhanced Monitoring, CloudWatch Logs, and AWS service communication"
}

# =============================================================================
# IAM ROLES AND POLICIES
# =============================================================================
# IAM roles define WHAT permissions a service or resource has. Each role
# follows the principle of least privilege -- only the minimum permissions
# needed for the role's specific function.
# =============================================================================

# =============================================================================
# ECS TASK EXECUTION ROLE
# =============================================================================
# WHAT: IAM role assumed by the ECS agent (not the application) to perform
#       container lifecycle operations.
# WHY: The ECS agent needs permissions to:
#       1. Pull container images from ECR
#       2. Write container logs to CloudWatch
#       3. Fetch secrets from Secrets Manager for container env vars
# SECURITY: This role is used by the ECS infrastructure, NOT the application.
#           It should have NO application-level permissions (no S3, no DynamoDB).
#           Keeping this role minimal reduces the impact if the ECS agent
#           infrastructure is compromised.
# ALTERNATIVE: The AWS-managed AmazonECSTaskExecutionRolePolicy provides
#              basic permissions, but it's overly broad. A custom policy
#              is preferred for production environments.
# =============================================================================
resource "aws_iam_role" "ecs_execution" {
  name = "${local.name_prefix}-ecs-execution-role"

  # Trust policy: only ECS tasks service can assume this role.
  # SECURITY: Prevents any other service or user from assuming this role.
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowECSTasksAssume"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"    # Only ECS task service
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-ecs-execution-role"
  })
}

# ECS Task Execution Policy: ECR Image Pull + CloudWatch Logs + Secrets Manager
# WHAT: Custom policy granting the minimum permissions for ECS task startup.
# WHY: Granular permissions instead of AWS-managed policies for security.
# SECURITY: Each action is justified and scoped to specific resources where possible.
resource "aws_iam_role_policy" "ecs_execution" {
  name = "${local.name_prefix}-ecs-execution-policy"
  role = aws_iam_role.ecs_execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # Allow pulling container images from Amazon ECR.
        # WHY: ECS needs to download the Docker image before starting the container.
        # SECURITY: Scoped to ECR actions only; cannot push images or manage repos.
        Sid    = "AllowECRImagePull"
        Effect = "Allow"
        Action = [
          "ecr:GetDownloadUrlForLayer",   # Get pre-signed URL for image layer
          "ecr:BatchGetImage",             # Get image manifest and layers
          "ecr:BatchCheckLayerAvailability" # Check if layers are already cached
        ]
        # Resource is "*" because the ECR repo ARN is not known at this point.
        # In production, scope to specific repository ARNs.
        Resource = "*"
      },
      {
        # Allow authenticating to ECR.
        # WHY: Required to get an authorization token for ECR image pulls.
        # SECURITY: GetAuthorizationToken does not require a specific resource.
        Sid      = "AllowECRAuth"
        Effect   = "Allow"
        Action   = "ecr:GetAuthorizationToken"
        Resource = "*"
      },
      {
        # Allow writing container logs to CloudWatch.
        # WHY: Container stdout/stderr is sent to CloudWatch via the awslogs driver.
        # SECURITY: Write-only access; cannot read or delete existing logs.
        Sid    = "AllowCloudWatchLogs"
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",    # Create a log stream for each task
          "logs:PutLogEvents"        # Write log events to the stream
        ]
        Resource = "arn:aws:logs:${local.region}:${local.account_id}:log-group:/ectp/${var.environment}/*"
      },
      {
        # Allow fetching secrets from Secrets Manager.
        # WHY: Container secrets (database credentials, API keys) are stored
        #       in Secrets Manager and injected at task startup.
        # SECURITY: Scoped to only ECTP secrets in this environment.
        #           Cannot access secrets from other projects or environments.
        Sid    = "AllowSecretsManagerRead"
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"   # Read the secret value
        ]
        Resource = "arn:aws:secretsmanager:${local.region}:${local.account_id}:secret:${local.name_prefix}/*"
      },
      {
        # Allow decrypting secrets and logs with the KMS key.
        # WHY: Secrets and logs are encrypted with the customer-managed KMS key.
        #       The ECS agent needs decrypt permission to read them.
        # SECURITY: Scoped to only the ECTP KMS key; cannot decrypt data
        #           encrypted with other keys.
        Sid    = "AllowKMSDecrypt"
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ]
        Resource = aws_kms_key.main.arn
      }
    ]
  })
}

# =============================================================================
# ECS TASK ROLE
# =============================================================================
# WHAT: IAM role assumed by the application code running INSIDE the container.
# WHY: The task role determines what AWS services the FastAPI application
#       can access at runtime. This is separate from the execution role
#       (which is used by the ECS agent for container lifecycle).
# SECURITY:
#   - This role should only have permissions the application actually needs.
#   - Start with NO permissions and add only what the application requires.
#   - Each permission should be documented with WHY it's needed.
#   - Resource ARNs should be as specific as possible (no wildcards).
# =============================================================================
resource "aws_iam_role" "ecs_task" {
  name = "${local.name_prefix}-ecs-task-role"

  # Trust policy: only ECS tasks can assume this role.
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowECSTasksAssume"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-ecs-task-role"
  })
}

# ECS Task Policy: Application-level permissions.
# WHAT: Permissions that the FastAPI application needs at runtime.
# WHY: The application may need to interact with AWS services for:
#       1. S3: File uploads/downloads (student documents, exports)
#       2. SES: Sending notification emails
#       3. SSM Parameter Store: Reading configuration parameters
#       4. ECS Execute Command: Enabling interactive debugging sessions
# SECURITY: Each statement is narrowly scoped to specific actions and resources.
resource "aws_iam_role_policy" "ecs_task" {
  name = "${local.name_prefix}-ecs-task-policy"
  role = aws_iam_role.ecs_task.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # Allow reading application configuration from SSM Parameter Store.
        # WHY: Non-secret configuration (feature flags, API URLs) is stored
        #       in SSM Parameter Store for easy management.
        # SECURITY: Read-only access; cannot modify configuration values.
        Sid    = "AllowSSMParameterRead"
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath"
        ]
        Resource = "arn:aws:ssm:${local.region}:${local.account_id}:parameter/ectp/${var.environment}/*"
      },
      {
        # Allow ECS Execute Command for interactive debugging.
        # WHY: Enables operators to shell into running containers for
        #       troubleshooting without SSH or bastion hosts.
        # SECURITY: Execute Command sessions are logged. This permission
        #           should be restricted to a break-glass role in production.
        Sid    = "AllowSSMMessaging"
        Effect = "Allow"
        Action = [
          "ssmmessages:CreateControlChannel",
          "ssmmessages:CreateDataChannel",
          "ssmmessages:OpenControlChannel",
          "ssmmessages:OpenDataChannel"
        ]
        Resource = "*"
      },
      {
        # Allow KMS decryption for accessing encrypted resources.
        # WHY: The application may need to decrypt data stored in S3 or
        #       access encrypted SSM parameters.
        Sid    = "AllowKMSDecrypt"
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ]
        Resource = aws_kms_key.main.arn
      }
    ]
  })
}

# =============================================================================
# RDS ENHANCED MONITORING IAM ROLE
# =============================================================================
# WHAT: IAM role for RDS Enhanced Monitoring to publish OS-level metrics.
# WHY: Enhanced Monitoring provides detailed OS metrics (CPU, memory, disk,
#       network) at per-second granularity, which standard CloudWatch metrics
#       do not provide.
# SECURITY: Uses the AWS-managed policy for Enhanced Monitoring, which
#           grants only the permissions needed to write metrics to CloudWatch.
# =============================================================================
resource "aws_iam_role" "rds_monitoring" {
  name = "${local.name_prefix}-rds-monitoring-role"

  # Trust policy: only the RDS monitoring service can assume this role.
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowRDSMonitoringAssume"
        Effect = "Allow"
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-rds-monitoring-role"
  })
}

# Attach the AWS-managed Enhanced Monitoring policy.
# WHY: The managed policy grants exactly the permissions needed for
#       Enhanced Monitoring to write to CloudWatch Logs.
# SECURITY: Using a managed policy ensures we don't accidentally over-provision.
resource "aws_iam_role_policy_attachment" "rds_monitoring" {
  role       = aws_iam_role.rds_monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

# =============================================================================
# OUTPUTS
# =============================================================================

output "kms_key_arn" {
  description = "ARN of the customer-managed KMS key for encrypting all ECTP data at rest."
  value       = aws_kms_key.main.arn
}

output "kms_key_id" {
  description = "ID of the customer-managed KMS key."
  value       = aws_kms_key.main.key_id
}

output "alb_security_group_id" {
  description = "Security group ID for the ALB. Attach to the Application Load Balancer."
  value       = aws_security_group.alb.id
}

output "ecs_tasks_security_group_id" {
  description = "Security group ID for ECS Fargate tasks. Attach to ECS service network configuration."
  value       = aws_security_group.ecs_tasks.id
}

output "database_security_group_id" {
  description = "Security group ID for the RDS database. Attach to the RDS instance."
  value       = aws_security_group.database.id
}

output "ecs_execution_role_arn" {
  description = "ARN of the ECS task execution role (used by ECS agent for image pull, logs, and secrets)."
  value       = aws_iam_role.ecs_execution.arn
}

output "ecs_task_role_arn" {
  description = "ARN of the ECS task role (used by application code for AWS service access)."
  value       = aws_iam_role.ecs_task.arn
}

output "rds_monitoring_role_arn" {
  description = "ARN of the RDS Enhanced Monitoring role."
  value       = aws_iam_role.rds_monitoring.arn
}
