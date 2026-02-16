# =============================================================================
# Enterprise Cloud Transformation Platform (ECTP) - Monitoring Module
# =============================================================================
# Author: Gopi Krishna Vajrala
# Purpose: Provisions comprehensive monitoring and alerting infrastructure
#          for the ECTP platform using CloudWatch dashboards, metric alarms,
#          and SNS notifications.
#
# Monitoring Strategy:
#   - CloudWatch Dashboards: Visual overview of system health
#   - CloudWatch Alarms: Automated alerting on metric thresholds
#   - SNS Topics: Alert delivery to email, Slack, PagerDuty, etc.
#   - Log Metric Filters: Custom metrics from application logs
#
# Alert Priority Levels:
#   1. Critical (P1): Service down, data loss risk -> immediate page
#   2. High (P2): Performance degradation, capacity issues -> within 15 min
#   3. Medium (P3): Warning thresholds, non-urgent issues -> within 1 hour
#   4. Low (P4): Informational, optimization opportunities -> next business day
#
# Higher Ed Considerations:
#   - Enrollment period monitoring: Extra alerting during peak registration
#   - Academic calendar awareness: Different thresholds for exam periods
#   - FERPA compliance: Monitor for unauthorized data access patterns
#   - 24/7 availability: Critical systems must be monitored around the clock
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

# =============================================================================
# LOCAL VALUES
# =============================================================================
locals {
  # Standard name prefix.
  name_prefix = "${var.project_name}-${var.environment}"

  # Common tags.
  common_tags = merge(var.tags, {
    Module      = "monitoring"
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
    Author      = "Gopi Krishna Vajrala"
  })
}

# =============================================================================
# SNS TOPICS FOR ALERT DELIVERY
# =============================================================================
# SNS topics are the notification channel for CloudWatch alarms. Each priority
# level has its own topic to enable different routing (e.g., P1 -> PagerDuty,
# P3 -> email only).
# =============================================================================

# -----------------------------------------------------------------------------
# Critical Alerts SNS Topic (P1 - Immediate Response Required)
# -----------------------------------------------------------------------------
# WHAT: SNS topic for critical, service-affecting alerts that require
#       immediate response (paging on-call engineers).
# WHY: Critical alerts indicate:
#       - Service is down or unresponsive
#       - Database is unreachable or failing
#       - Data loss or corruption risk
#       - Security breach indicators
# SECURITY: Encrypted with KMS to protect alert content (may contain
#           resource names, metrics values). Access controlled by IAM.
# DELIVERY: Should be routed to:
#           - PagerDuty for immediate engineer paging
#           - Slack #ectp-critical channel
#           - On-call phone number via SMS
# -----------------------------------------------------------------------------
resource "aws_sns_topic" "critical_alerts" {
  # Topic name includes environment and priority for clear identification.
  name = "${local.name_prefix}-critical-alerts"

  # Display name for SMS messages (limited to 10 characters for SMS).
  display_name = "ECTP-P1"

  # Encrypt SNS messages at rest with KMS.
  # WHY: Alert messages may contain sensitive operational information
  #       (resource names, IP addresses, error messages).
  # SECURITY: Without encryption, anyone with SNS read access can view
  #           alert content, which could reveal infrastructure details.
  kms_master_key_id = var.kms_key_arn

  tags = merge(local.common_tags, {
    Name     = "${local.name_prefix}-critical-alerts"
    Priority = "P1-Critical"
  })
}

# -----------------------------------------------------------------------------
# Warning Alerts SNS Topic (P2/P3 - Timely Response Required)
# -----------------------------------------------------------------------------
# WHAT: SNS topic for warning-level alerts that need attention but are
#       not immediately service-affecting.
# WHY: Warning alerts indicate:
#       - Performance approaching thresholds (high CPU, memory, latency)
#       - Capacity approaching limits (disk space, connection pool)
#       - Non-critical component failures (log delivery, monitoring gaps)
#       - Cost anomalies or scaling events
# DELIVERY: Should be routed to:
#           - Email distribution list for the operations team
#           - Slack #ectp-warnings channel
# -----------------------------------------------------------------------------
resource "aws_sns_topic" "warning_alerts" {
  name         = "${local.name_prefix}-warning-alerts"
  display_name = "ECTP-P3"

  kms_master_key_id = var.kms_key_arn

  tags = merge(local.common_tags, {
    Name     = "${local.name_prefix}-warning-alerts"
    Priority = "P3-Warning"
  })
}

# -----------------------------------------------------------------------------
# SNS Topic Policy - Allow CloudWatch to Publish
# -----------------------------------------------------------------------------
# WHAT: IAM policy on the SNS topic allowing CloudWatch Alarms to publish messages.
# WHY: CloudWatch needs explicit permission to send alarm notifications
#       to SNS topics. Without this policy, alarms would trigger but
#       notifications would silently fail.
# SECURITY: Restricted to only the CloudWatch Alarms service in this account.
#           Prevents external accounts or services from publishing to our topics.
# -----------------------------------------------------------------------------
resource "aws_sns_topic_policy" "critical_alerts" {
  arn = aws_sns_topic.critical_alerts.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudWatchAlarms"
        Effect = "Allow"
        Principal = {
          Service = "cloudwatch.amazonaws.com"   # Only CloudWatch service
        }
        Action   = "sns:Publish"                  # Only publish (send messages)
        Resource = aws_sns_topic.critical_alerts.arn
      }
    ]
  })
}

resource "aws_sns_topic_policy" "warning_alerts" {
  arn = aws_sns_topic.warning_alerts.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudWatchAlarms"
        Effect = "Allow"
        Principal = {
          Service = "cloudwatch.amazonaws.com"
        }
        Action   = "sns:Publish"
        Resource = aws_sns_topic.warning_alerts.arn
      }
    ]
  })
}

# -----------------------------------------------------------------------------
# SNS Email Subscription for Alerts
# -----------------------------------------------------------------------------
# WHAT: Subscribes an email address to both SNS topics for alert delivery.
# WHY: Email is the baseline alerting channel that works for all team members.
#       Additional channels (Slack, PagerDuty) can be added separately.
# SECURITY: The email subscription requires manual confirmation (click a link
#           in the confirmation email) to prevent unauthorized subscriptions.
# NOTE: Only created if an alert email is provided.
# -----------------------------------------------------------------------------
resource "aws_sns_topic_subscription" "critical_email" {
  # Only create if an alert email is configured.
  count = var.alert_email != "" ? 1 : 0

  topic_arn = aws_sns_topic.critical_alerts.arn
  protocol  = "email"                     # Deliver via email
  endpoint  = var.alert_email             # Target email address

  # NOTE: Email subscriptions require manual confirmation after creation.
  # The specified email address will receive a confirmation email that must
  # be clicked before any alerts will be delivered.
}

resource "aws_sns_topic_subscription" "warning_email" {
  count = var.alert_email != "" ? 1 : 0

  topic_arn = aws_sns_topic.warning_alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# =============================================================================
# CLOUDWATCH ALARMS - ECS/COMPUTE TIER
# =============================================================================
# These alarms monitor the ECS Fargate tasks running the ECTP FastAPI application.
# =============================================================================

# -----------------------------------------------------------------------------
# ECS Service CPU Utilization Alarm
# -----------------------------------------------------------------------------
# WHAT: Triggers when average CPU utilization across all ECS tasks exceeds 80%.
# WHY: High CPU indicates:
#       1. Application is under heavy load (may need scaling)
#       2. Code inefficiency (tight loops, excessive computation)
#       3. Potential DoS attack consuming CPU resources
#       4. Auto Scaling may not be responding fast enough
# THRESHOLD: 80% for 2 consecutive 5-minute periods (10 minutes sustained).
# ACTION: Sends alert to critical topic because sustained high CPU affects
#          user experience (slower API responses).
# ALTERNATIVE: Could use anomaly detection instead of static thresholds
#              for more adaptive alerting.
# -----------------------------------------------------------------------------
resource "aws_cloudwatch_metric_alarm" "ecs_cpu_high" {
  alarm_name = "${local.name_prefix}-ecs-cpu-high"

  # Human-readable description appears in alert notifications.
  alarm_description = "ECTP ECS CPU utilization exceeds 80% for 10 minutes. Investigate: possible under-provisioning, code performance issue, or DoS attack. Check Auto Scaling status and recent deployments."

  # Compare the average CPU against the threshold.
  comparison_operator = "GreaterThanOrEqualToThreshold"

  # Require 2 consecutive breach periods before alarming.
  # WHY: Prevents alerting on brief CPU spikes (GC pauses, burst processing).
  #       2 periods of 5 minutes = 10 minutes sustained high CPU.
  evaluation_periods = 2

  # Use the ECS service CPU utilization metric.
  namespace   = "AWS/ECS"
  metric_name = "CPUUtilization"

  # 5-minute evaluation period.
  # WHY: Balances between quick detection and noise reduction.
  period = 300

  # Use average across all tasks.
  # WHY: Average represents the overall service load. A single hot task
  #       won't trigger the alarm unless most tasks are overloaded.
  statistic = "Average"

  # 80% threshold.
  # WHY: Leaves 20% headroom for traffic spikes. Auto Scaling targets 70%,
  #       so 80% means scaling is not keeping up.
  threshold = 80

  # Dimensions narrow the alarm to our specific ECS cluster and service.
  dimensions = {
    ClusterName = var.ecs_cluster_name
    ServiceName = var.ecs_service_name
  }

  # Send alerts to the critical topic.
  # WHY: Sustained high CPU directly impacts user experience.
  alarm_actions = [aws_sns_topic.critical_alerts.arn]

  # Send OK notification when the alarm clears.
  # WHY: Teams need to know when an incident is resolved.
  ok_actions = [aws_sns_topic.warning_alerts.arn]

  # Treat missing data as "notBreaching".
  # WHY: If no data points are available (e.g., service is scaling to 0),
  #       we don't want a false alarm. Missing data is not a CPU issue.
  treat_missing_data = "notBreaching"

  tags = merge(local.common_tags, {
    Name     = "${local.name_prefix}-ecs-cpu-high"
    Priority = "P1-Critical"
  })
}

# -----------------------------------------------------------------------------
# ECS Service Memory Utilization Alarm
# -----------------------------------------------------------------------------
# WHAT: Triggers when average memory utilization exceeds 80%.
# WHY: High memory indicates:
#       1. Memory leak in the application (gradual increase over time)
#       2. Insufficient task memory allocation
#       3. Large data sets being held in memory
#       4. Approaching OOM kill threshold (Fargate kills tasks at ~100%)
# THRESHOLD: 80% for 2 consecutive 5-minute periods.
# ACTION: Critical alert because OOM kills cause request failures.
# -----------------------------------------------------------------------------
resource "aws_cloudwatch_metric_alarm" "ecs_memory_high" {
  alarm_name          = "${local.name_prefix}-ecs-memory-high"
  alarm_description   = "ECTP ECS memory utilization exceeds 80% for 10 minutes. Risk of OOM kills. Investigate: possible memory leak, insufficient task memory allocation, or large data processing."
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  namespace           = "AWS/ECS"
  metric_name         = "MemoryUtilization"
  period              = 300
  statistic           = "Average"
  threshold           = 80

  dimensions = {
    ClusterName = var.ecs_cluster_name
    ServiceName = var.ecs_service_name
  }

  alarm_actions      = [aws_sns_topic.critical_alerts.arn]
  ok_actions         = [aws_sns_topic.warning_alerts.arn]
  treat_missing_data = "notBreaching"

  tags = merge(local.common_tags, {
    Name     = "${local.name_prefix}-ecs-memory-high"
    Priority = "P1-Critical"
  })
}

# -----------------------------------------------------------------------------
# ECS Running Task Count Alarm
# -----------------------------------------------------------------------------
# WHAT: Triggers when the number of running ECS tasks drops to zero.
# WHY: Zero running tasks means the ECTP application is completely DOWN.
#       This is the most critical alarm -- no tasks = no service.
# THRESHOLD: Less than 1 running task for 1 evaluation period of 1 minute.
# ACTION: Immediate critical alert and investigation.
# ROOT CAUSES:
#   - Failed deployment (bad container image, misconfigured secrets)
#   - All tasks failing health checks simultaneously
#   - Subnet/security group misconfiguration blocking task startup
#   - Insufficient Fargate capacity (rare but possible during outages)
# -----------------------------------------------------------------------------
resource "aws_cloudwatch_metric_alarm" "ecs_running_count" {
  alarm_name          = "${local.name_prefix}-ecs-no-running-tasks"
  alarm_description   = "CRITICAL: ECTP has zero running ECS tasks - the application is DOWN. Immediate investigation required. Check: recent deployments, task failures, container health, security groups, and subnet configuration."
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1           # Alert immediately on first breach
  namespace           = "AWS/ECS"
  metric_name         = "RunningTaskCount"
  period              = 60          # Check every minute for fastest detection
  statistic           = "Minimum"   # Minimum to detect any period with 0 tasks
  threshold           = 1           # Alert if fewer than 1 task is running

  dimensions = {
    ClusterName = var.ecs_cluster_name
    ServiceName = var.ecs_service_name
  }

  alarm_actions      = [aws_sns_topic.critical_alerts.arn]
  ok_actions         = [aws_sns_topic.critical_alerts.arn]  # Also notify on recovery
  treat_missing_data = "breaching"  # Missing data = assume service is down

  tags = merge(local.common_tags, {
    Name     = "${local.name_prefix}-ecs-no-running-tasks"
    Priority = "P1-Critical"
  })
}

# =============================================================================
# CLOUDWATCH ALARMS - ALB TIER
# =============================================================================
# These alarms monitor the Application Load Balancer for error rates,
# latency, and availability.
# =============================================================================

# -----------------------------------------------------------------------------
# ALB 5xx Error Rate Alarm
# -----------------------------------------------------------------------------
# WHAT: Triggers when the ALB returns more than 10 HTTP 5xx errors in 5 minutes.
# WHY: 5xx errors indicate server-side failures:
#       - 500: Application crashed or unhandled exception
#       - 502: ECS task crashed; ALB got no response
#       - 503: No healthy targets (all tasks unhealthy)
#       - 504: Application took too long to respond (timeout)
# THRESHOLD: More than 10 errors in a 5-minute period.
# ACTION: Critical alert because 5xx errors mean users are seeing errors.
# NOTE: Uses Sum statistic to count total errors, not average.
# -----------------------------------------------------------------------------
resource "aws_cloudwatch_metric_alarm" "alb_5xx_errors" {
  alarm_name          = "${local.name_prefix}-alb-5xx-errors"
  alarm_description   = "ECTP ALB is returning more than 10 HTTP 5xx errors in 5 minutes. Users are experiencing server errors. Investigate: application logs, task health, recent deployments, and database connectivity."
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  namespace           = "AWS/ApplicationELB"
  metric_name         = "HTTPCode_ELB_5XX_Count"
  period              = 300
  statistic           = "Sum"
  threshold           = 10

  dimensions = {
    LoadBalancer = var.alb_arn_suffix
  }

  alarm_actions      = [aws_sns_topic.critical_alerts.arn]
  ok_actions         = [aws_sns_topic.warning_alerts.arn]
  treat_missing_data = "notBreaching"   # No data = no errors (good)

  tags = merge(local.common_tags, {
    Name     = "${local.name_prefix}-alb-5xx-errors"
    Priority = "P1-Critical"
  })
}

# -----------------------------------------------------------------------------
# ALB Target Response Time Alarm
# -----------------------------------------------------------------------------
# WHAT: Triggers when average response time exceeds 2 seconds.
# WHY: High response time indicates:
#       - Application performance degradation
#       - Database query slowness
#       - Resource contention (CPU/memory saturation)
#       - Network issues between ALB and ECS tasks
# THRESHOLD: Average response time > 2 seconds for 3 periods of 5 minutes.
# ACTION: Warning alert; not immediately service-affecting but degrades UX.
# HIGHER ED CONTEXT: Slow responses during enrollment periods cause
#                     significant student frustration and support tickets.
# -----------------------------------------------------------------------------
resource "aws_cloudwatch_metric_alarm" "alb_response_time" {
  alarm_name          = "${local.name_prefix}-alb-high-latency"
  alarm_description   = "ECTP ALB average response time exceeds 2 seconds for 15 minutes. User experience is degraded. Investigate: slow database queries, CPU/memory utilization, recent code changes, and network connectivity."
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3                  # 3 periods = 15 minutes sustained
  namespace           = "AWS/ApplicationELB"
  metric_name         = "TargetResponseTime"
  period              = 300
  statistic           = "Average"
  threshold           = 2.0                # 2 seconds average

  dimensions = {
    LoadBalancer = var.alb_arn_suffix
  }

  alarm_actions      = [aws_sns_topic.warning_alerts.arn]
  ok_actions         = [aws_sns_topic.warning_alerts.arn]
  treat_missing_data = "notBreaching"

  tags = merge(local.common_tags, {
    Name     = "${local.name_prefix}-alb-high-latency"
    Priority = "P2-High"
  })
}

# -----------------------------------------------------------------------------
# ALB Unhealthy Targets Alarm
# -----------------------------------------------------------------------------
# WHAT: Triggers when any target in the target group is unhealthy.
# WHY: Unhealthy targets indicate:
#       - Failed health checks (application not responding on /health)
#       - Container crash loop (continuous restart cycle)
#       - Deployment issue (new version failing to start)
#       - Resource exhaustion (OOM kill, CPU starvation)
# THRESHOLD: More than 0 unhealthy targets for 2 consecutive 1-minute periods.
# ACTION: Warning alert; service may still be partially available but at risk.
# -----------------------------------------------------------------------------
resource "aws_cloudwatch_metric_alarm" "alb_unhealthy_targets" {
  alarm_name          = "${local.name_prefix}-alb-unhealthy-targets"
  alarm_description   = "ECTP ALB has unhealthy targets. Some ECS tasks are failing health checks. Service is degraded. Investigate: application logs, container health, resource utilization, and deployment status."
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  namespace           = "AWS/ApplicationELB"
  metric_name         = "UnHealthyHostCount"
  period              = 60
  statistic           = "Maximum"
  threshold           = 0

  dimensions = {
    LoadBalancer  = var.alb_arn_suffix
    TargetGroup   = var.target_group_arn_suffix
  }

  alarm_actions      = [aws_sns_topic.warning_alerts.arn]
  ok_actions         = [aws_sns_topic.warning_alerts.arn]
  treat_missing_data = "notBreaching"

  tags = merge(local.common_tags, {
    Name     = "${local.name_prefix}-alb-unhealthy-targets"
    Priority = "P2-High"
  })
}

# =============================================================================
# CLOUDWATCH ALARMS - DATABASE TIER
# =============================================================================
# These alarms monitor the RDS PostgreSQL database for performance,
# capacity, and connectivity issues.
# =============================================================================

# -----------------------------------------------------------------------------
# RDS CPU Utilization Alarm
# -----------------------------------------------------------------------------
# WHAT: Triggers when database CPU exceeds 80%.
# WHY: High database CPU indicates:
#       - Expensive queries consuming CPU (missing indexes, full table scans)
#       - Increased application load generating more queries
#       - Background processes (autovacuum, replication) consuming resources
#       - Instance class too small for the workload
# THRESHOLD: 80% for 3 consecutive 5-minute periods (15 minutes sustained).
# ACTION: Critical alert because database performance affects all users.
# REMEDIATION: Optimize queries, add indexes, or scale up instance class.
# -----------------------------------------------------------------------------
resource "aws_cloudwatch_metric_alarm" "rds_cpu_high" {
  alarm_name          = "${local.name_prefix}-rds-cpu-high"
  alarm_description   = "ECTP RDS CPU utilization exceeds 80% for 15 minutes. Database performance is degrading. Investigate: slow queries (check Performance Insights), missing indexes, autovacuum activity, or need to scale up instance class."
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 3
  namespace           = "AWS/RDS"
  metric_name         = "CPUUtilization"
  period              = 300
  statistic           = "Average"
  threshold           = 80

  dimensions = {
    DBInstanceIdentifier = var.db_instance_id
  }

  alarm_actions      = [aws_sns_topic.critical_alerts.arn]
  ok_actions         = [aws_sns_topic.warning_alerts.arn]
  treat_missing_data = "breaching"   # Missing data from DB = assume problem

  tags = merge(local.common_tags, {
    Name     = "${local.name_prefix}-rds-cpu-high"
    Priority = "P1-Critical"
  })
}

# -----------------------------------------------------------------------------
# RDS Free Storage Space Alarm
# -----------------------------------------------------------------------------
# WHAT: Triggers when free storage drops below 10 GB.
# WHY: Running out of storage causes the database to become read-only,
#       which would make the ECTP application unable to write any data
#       (new records, updates, audit logs).
# THRESHOLD: Less than 10 GB free for 1 evaluation period.
# ACTION: Critical alert because running out of storage = data loss risk.
# REMEDIATION: Enable storage autoscaling, increase allocated storage,
#              or clean up old data (archive, purge).
# NOTE: RDS storage autoscaling (max_allocated_storage) provides automatic
#        expansion, but this alarm catches cases where autoscaling is too slow
#        or has reached its maximum.
# -----------------------------------------------------------------------------
resource "aws_cloudwatch_metric_alarm" "rds_storage_low" {
  alarm_name          = "${local.name_prefix}-rds-storage-low"
  alarm_description   = "CRITICAL: ECTP RDS free storage is below 10 GB. Risk of database becoming read-only. Immediate action required: verify storage autoscaling is working, increase max_allocated_storage, or archive old data."
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1                  # Alert immediately
  namespace           = "AWS/RDS"
  metric_name         = "FreeStorageSpace"
  period              = 300
  statistic           = "Minimum"
  threshold           = 10737418240        # 10 GB in bytes (10 * 1024^3)

  dimensions = {
    DBInstanceIdentifier = var.db_instance_id
  }

  alarm_actions      = [aws_sns_topic.critical_alerts.arn]
  ok_actions         = [aws_sns_topic.warning_alerts.arn]
  treat_missing_data = "breaching"

  tags = merge(local.common_tags, {
    Name     = "${local.name_prefix}-rds-storage-low"
    Priority = "P1-Critical"
  })
}

# -----------------------------------------------------------------------------
# RDS Database Connections Alarm
# -----------------------------------------------------------------------------
# WHAT: Triggers when active database connections exceed 80% of the maximum.
# WHY: Connection exhaustion causes new application requests to fail with
#       "too many connections" errors. This typically indicates:
#       - Connection pool misconfiguration (too many or too few connections)
#       - Connection leak (connections opened but never closed)
#       - Sudden traffic spike overwhelming the connection pool
#       - Long-running transactions holding connections
# THRESHOLD: Configurable; based on the RDS instance's max_connections setting.
# ACTION: Critical alert because connection exhaustion = service disruption.
# HIGHER ED: Enrollment periods can cause massive connection spikes.
# -----------------------------------------------------------------------------
resource "aws_cloudwatch_metric_alarm" "rds_connections_high" {
  alarm_name          = "${local.name_prefix}-rds-connections-high"
  alarm_description   = "ECTP RDS active connections are high. Risk of connection exhaustion. Investigate: connection pool configuration, possible connection leaks, long-running transactions, or need to scale up instance class for more max_connections."
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  namespace           = "AWS/RDS"
  metric_name         = "DatabaseConnections"
  period              = 300
  statistic           = "Maximum"

  # Threshold based on the max connections for the instance type.
  # WHY: Different instance types support different max_connections values.
  #       db.t3.medium supports ~120, db.r6g.large supports ~1600.
  #       We alert at the configured threshold.
  threshold = var.db_max_connections_threshold

  dimensions = {
    DBInstanceIdentifier = var.db_instance_id
  }

  alarm_actions      = [aws_sns_topic.critical_alerts.arn]
  ok_actions         = [aws_sns_topic.warning_alerts.arn]
  treat_missing_data = "notBreaching"

  tags = merge(local.common_tags, {
    Name     = "${local.name_prefix}-rds-connections-high"
    Priority = "P1-Critical"
  })
}

# =============================================================================
# CLOUDWATCH DASHBOARD
# =============================================================================
# WHAT: A CloudWatch dashboard providing a single-pane-of-glass view of
#       the entire ECTP platform's health, performance, and key metrics.
# WHY: Dashboards enable:
#       1. Quick health assessment during incidents
#       2. Trend analysis for capacity planning
#       3. Executive reporting on system performance
#       4. Correlation of metrics across tiers (ALB + ECS + RDS)
# SECURITY: Dashboard access is controlled by CloudWatch IAM permissions.
#           The dashboard itself contains no sensitive data, only metric graphs.
# LAYOUT: Organized by infrastructure tier:
#         Row 1: ALB metrics (traffic entry point)
#         Row 2: ECS metrics (application tier)
#         Row 3: RDS metrics (data tier)
# =============================================================================
resource "aws_cloudwatch_dashboard" "main" {
  # Dashboard name appears in the CloudWatch console navigation.
  dashboard_name = "${local.name_prefix}-dashboard"

  # Dashboard body is a JSON document defining widgets.
  # WHY: JSON format allows complex widget configurations with multiple
  #       metrics per widget, custom time ranges, and annotations.
  dashboard_body = jsonencode({
    widgets = [
      # =====================================================================
      # ROW 1: HEADER - Dashboard Title
      # =====================================================================
      {
        type   = "text"
        x      = 0          # Column position (0-23)
        y      = 0          # Row position
        width  = 24         # Full width (24 columns max)
        height = 1          # 1 row height
        properties = {
          # Markdown-formatted header for the dashboard.
          markdown = "# ECTP ${upper(var.environment)} Environment Dashboard\nEnterprise Cloud Transformation Platform - Real-time infrastructure monitoring | Author: Gopi Krishna Vajrala"
        }
      },

      # =====================================================================
      # ROW 2: ALB METRICS (Traffic Entry Point)
      # =====================================================================

      # ALB Request Count (total traffic volume).
      # WHY: Shows traffic patterns, peak periods, and trend over time.
      #       Useful for capacity planning and detecting DDoS attacks.
      {
        type   = "metric"
        x      = 0
        y      = 1
        width  = 8
        height = 6
        properties = {
          title  = "ALB Request Count"
          region = var.aws_region
          metrics = [
            [
              "AWS/ApplicationELB",        # Namespace
              "RequestCount",               # Metric name
              "LoadBalancer",               # Dimension name
              var.alb_arn_suffix,           # Dimension value
              {
                stat   = "Sum"              # Total count per period
                period = 300                # 5-minute intervals
                label  = "Total Requests"   # Legend label
              }
            ]
          ]
          view = "timeSeries"               # Line chart over time
          yAxis = {
            left = {
              min   = 0                     # Start Y axis at 0
              label = "Requests"            # Y axis label
            }
          }
        }
      },

      # ALB Response Time (user-perceived latency).
      # WHY: Directly correlates with user experience. Higher Ed users
      #       expect sub-second responses for most operations.
      {
        type   = "metric"
        x      = 8
        y      = 1
        width  = 8
        height = 6
        properties = {
          title  = "ALB Response Time"
          region = var.aws_region
          metrics = [
            [
              "AWS/ApplicationELB",
              "TargetResponseTime",
              "LoadBalancer",
              var.alb_arn_suffix,
              {
                stat   = "Average"
                period = 300
                label  = "Avg Response Time"
              }
            ],
            [
              "AWS/ApplicationELB",
              "TargetResponseTime",
              "LoadBalancer",
              var.alb_arn_suffix,
              {
                stat   = "p99"              # 99th percentile (worst 1%)
                period = 300
                label  = "p99 Response Time"
              }
            ]
          ]
          view = "timeSeries"
          yAxis = {
            left = {
              min   = 0
              label = "Seconds"
            }
          }
          annotations = {
            horizontal = [
              {
                value = 2.0                 # 2-second threshold line
                label = "Alert Threshold"
                color = "#d62728"           # Red for danger
              }
            ]
          }
        }
      },

      # ALB HTTP Status Codes (error monitoring).
      # WHY: Shows the breakdown of 2xx (success), 4xx (client error),
      #       and 5xx (server error) responses over time.
      {
        type   = "metric"
        x      = 16
        y      = 1
        width  = 8
        height = 6
        properties = {
          title  = "ALB HTTP Status Codes"
          region = var.aws_region
          metrics = [
            [
              "AWS/ApplicationELB",
              "HTTPCode_Target_2XX_Count",
              "LoadBalancer",
              var.alb_arn_suffix,
              { stat = "Sum", period = 300, label = "2xx Success", color = "#2ca02c" }
            ],
            [
              "AWS/ApplicationELB",
              "HTTPCode_Target_4XX_Count",
              "LoadBalancer",
              var.alb_arn_suffix,
              { stat = "Sum", period = 300, label = "4xx Client Error", color = "#ff7f0e" }
            ],
            [
              "AWS/ApplicationELB",
              "HTTPCode_ELB_5XX_Count",
              "LoadBalancer",
              var.alb_arn_suffix,
              { stat = "Sum", period = 300, label = "5xx Server Error", color = "#d62728" }
            ]
          ]
          view = "timeSeries"
          yAxis = {
            left = {
              min   = 0
              label = "Count"
            }
          }
        }
      },

      # =====================================================================
      # ROW 3: ECS METRICS (Application Tier)
      # =====================================================================

      # ECS CPU and Memory Utilization.
      # WHY: Shows resource consumption of the FastAPI application.
      #       High utilization triggers auto scaling and may indicate issues.
      {
        type   = "metric"
        x      = 0
        y      = 7
        width  = 8
        height = 6
        properties = {
          title  = "ECS CPU & Memory Utilization"
          region = var.aws_region
          metrics = [
            [
              "AWS/ECS",
              "CPUUtilization",
              "ClusterName", var.ecs_cluster_name,
              "ServiceName", var.ecs_service_name,
              { stat = "Average", period = 300, label = "CPU %", color = "#1f77b4" }
            ],
            [
              "AWS/ECS",
              "MemoryUtilization",
              "ClusterName", var.ecs_cluster_name,
              "ServiceName", var.ecs_service_name,
              { stat = "Average", period = 300, label = "Memory %", color = "#ff7f0e" }
            ]
          ]
          view = "timeSeries"
          yAxis = {
            left = {
              min   = 0
              max   = 100
              label = "Percent"
            }
          }
          annotations = {
            horizontal = [
              {
                value = 80
                label = "Alert Threshold"
                color = "#d62728"
              },
              {
                value = 70
                label = "Scaling Target"
                color = "#ff7f0e"
              }
            ]
          }
        }
      },

      # ECS Running Task Count.
      # WHY: Shows how many tasks are running and how auto scaling responds
      #       to load changes. Critical for capacity monitoring.
      {
        type   = "metric"
        x      = 8
        y      = 7
        width  = 8
        height = 6
        properties = {
          title  = "ECS Running Tasks"
          region = var.aws_region
          metrics = [
            [
              "AWS/ECS",
              "RunningTaskCount",
              "ClusterName", var.ecs_cluster_name,
              "ServiceName", var.ecs_service_name,
              { stat = "Average", period = 60, label = "Running Tasks", color = "#2ca02c" }
            ]
          ]
          view = "timeSeries"
          yAxis = {
            left = {
              min   = 0
              label = "Tasks"
            }
          }
          annotations = {
            horizontal = [
              {
                value = 1
                label = "Minimum (Alarm if below)"
                color = "#d62728"
              }
            ]
          }
        }
      },

      # =====================================================================
      # ROW 4: RDS METRICS (Data Tier)
      # =====================================================================

      # RDS CPU Utilization.
      # WHY: Database CPU is the primary indicator of query workload.
      #       Sustained high CPU requires query optimization or scaling.
      {
        type   = "metric"
        x      = 0
        y      = 13
        width  = 8
        height = 6
        properties = {
          title  = "RDS CPU Utilization"
          region = var.aws_region
          metrics = [
            [
              "AWS/RDS",
              "CPUUtilization",
              "DBInstanceIdentifier", var.db_instance_id,
              { stat = "Average", period = 300, label = "CPU %", color = "#9467bd" }
            ]
          ]
          view = "timeSeries"
          yAxis = {
            left = {
              min   = 0
              max   = 100
              label = "Percent"
            }
          }
          annotations = {
            horizontal = [
              {
                value = 80
                label = "Alert Threshold"
                color = "#d62728"
              }
            ]
          }
        }
      },

      # RDS Database Connections.
      # WHY: Shows connection pool utilization and helps detect connection
      #       leaks or exhaustion that would cause application failures.
      {
        type   = "metric"
        x      = 8
        y      = 13
        width  = 8
        height = 6
        properties = {
          title  = "RDS Database Connections"
          region = var.aws_region
          metrics = [
            [
              "AWS/RDS",
              "DatabaseConnections",
              "DBInstanceIdentifier", var.db_instance_id,
              { stat = "Maximum", period = 300, label = "Active Connections", color = "#8c564b" }
            ]
          ]
          view = "timeSeries"
          yAxis = {
            left = {
              min   = 0
              label = "Connections"
            }
          }
        }
      },

      # RDS Free Storage Space.
      # WHY: Monitors available storage to prevent database lockup.
      #       Critical for proactive capacity management.
      {
        type   = "metric"
        x      = 16
        y      = 13
        width  = 8
        height = 6
        properties = {
          title  = "RDS Free Storage Space"
          region = var.aws_region
          metrics = [
            [
              "AWS/RDS",
              "FreeStorageSpace",
              "DBInstanceIdentifier", var.db_instance_id,
              { stat = "Minimum", period = 300, label = "Free Storage (bytes)", color = "#e377c2" }
            ]
          ]
          view = "timeSeries"
          yAxis = {
            left = {
              min   = 0
              label = "Bytes"
            }
          }
          annotations = {
            horizontal = [
              {
                value = 10737418240          # 10 GB in bytes
                label = "Alert Threshold (10 GB)"
                color = "#d62728"
              }
            ]
          }
        }
      }
    ]
  })
}

# =============================================================================
# OUTPUTS
# =============================================================================

output "critical_alerts_topic_arn" {
  description = "ARN of the SNS topic for critical (P1) alerts. Subscribe PagerDuty, on-call phone, and critical Slack channels."
  value       = aws_sns_topic.critical_alerts.arn
}

output "warning_alerts_topic_arn" {
  description = "ARN of the SNS topic for warning (P2/P3) alerts. Subscribe email distribution lists and warning Slack channels."
  value       = aws_sns_topic.warning_alerts.arn
}

output "dashboard_name" {
  description = "Name of the CloudWatch dashboard. Access at: https://console.aws.amazon.com/cloudwatch/home#dashboards:name=${local.name_prefix}-dashboard"
  value       = aws_cloudwatch_dashboard.main.dashboard_name
}
