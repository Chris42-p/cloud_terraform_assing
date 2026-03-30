# =============== Option 2 Assignment: Emergency Notification System==========
#   By: Chris 
#   Date: 3/30/26
#
#one regions 
#AWS GuardDuty
#SNS topic with set of email subscribers 
#
# ===========================================================


provider "aws" {
  region = var.region
  default_tags {
    tags = {
      Teacher = "Denis"
      Student = "Chris"
      Project = "Option 2 Assignment: Emergency Notification System"
    }
  }
}

#======================== Cloud Trail ===========================
#need cloud trail for the API user creation calls. 

#Get current AWS account ID (for s3 bucket)
data "aws_caller_identity" "current" {}

#S3 bucket to store cloud trail logs.
resource "aws_s3_bucket" "cloudtrail_logs" {
  bucket = "cloudtrail-logs-${data.aws_caller_identity.current.account_id}"
}

#S3 block public access #public access block (pab)
resource "aws_s3_bucket_public_access_block" "cloudtrail_pab" {
  bucket = aws_s3_bucket.cloudtrail_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "cloudtrail_policy" {
  bucket = aws_s3_bucket.cloudtrail_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AWSCloudTrailAclCheck"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.cloudtrail_logs.arn
      },
      {
        Sid    = "AWSCloudTrailWrite"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.cloudtrail_logs.arn}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      }
    ]
  })
}

#cloud trail itself. 
resource "aws_cloudtrail" "main" {
  depends_on = [aws_s3_bucket_policy.cloudtrail_policy]

  name                          = "main-cloudtrail"
  s3_bucket_name                = aws_s3_bucket.cloudtrail_logs.id
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_log_file_validation    = true
  is_organization_trail         = false

  event_selector {
    read_write_type           = "All"
    include_management_events = true

    data_resource {
      type   = "AWS::S3::Object"
      values = ["arn:aws:s3:::*/"]
    }

    data_resource {
      type   = "AWS::Lambda::Function"
      values = ["arn:aws:lambda:*:*:function/*"]
    }
  }

  tags = {
    Name = "Main CloudTrail"
  }
}

#================================================================

#========================= Guard Duty ===========================
resource "aws_guardduty_detector" "main" {
  enable                       = true
  finding_publishing_frequency = "FIFTEEN_MINUTES" # Required for datasources

  tags = {
    Name = "Guard Duty for the cloud infrastructure"
  }
  # ref: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/guardduty_detector
  #data source is deprecated -- need the aws_guardduty_detector_feature resoruce
}
#s3: protection 
resource "aws_guardduty_detector_feature" "s3_protection" {
  detector_id = aws_guardduty_detector.main.id
  name        = "S3_DATA_EVENTS"
  status      = "ENABLED"
  # ref: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/guardduty_detector_feature
}
#ec2: runtime monitoring (agent-based)
resource "aws_guardduty_detector_feature" "ec2_protection" { #run time ec2 monitoring 
  detector_id = aws_guardduty_detector.main.id
  name        = "RUNTIME_MONITORING"
  status      = "ENABLED"

  additional_configuration {
    name   = "EC2_AGENT_MANAGEMENT"
    status = "ENABLED"
  }
}
#ec2- Elastic Block Service (EBS) Volume malware monitoring 
resource "aws_guardduty_detector_feature" "ec2_volume_monitoring" {
  detector_id = aws_guardduty_detector.main.id
  name        = "EBS_MALWARE_PROTECTION"
  status      = "ENABLED"
}
#================================================================

#======================== Sns Topics =============================
resource "aws_sns_topic" "critical_updates" {
  name         = "critical-level-admin-updates"
  display_name = "AWS Critical Alert"
  #ref: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic.html
}

resource "aws_sns_topic_subscription" "distribution_list" {
  topic_arn = aws_sns_topic.critical_updates.arn
  protocol  = "email"

  #multiple subscribers -loop over them
  for_each = toset(var.email_list)
  endpoint = each.value
  #ref:https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic_subscription
}
#=================================================================

#======================== Event Rules ============================
#event bridge event bus. 
resource "aws_cloudwatch_event_bus" "critical_notifications" {
  name        = "critical_notifications_bridge"
  description = "bus to send critical level notification from guard duty to sns service throught event bridge"

  #ref: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_bus
}

#rule: IAM user created
resource "aws_cloudwatch_event_rule" "crit_iam_user_created" {
  name           = "iam_usr_created"
  description    = "admin account has a IAM user that was created"
  event_bus_name = aws_cloudwatch_event_bus.critical_notifications.name

  event_pattern = jsonencode({
    source      = ["aws.iam"]
    detail-type = ["CloudTrail IAM user creation request"]

    detail = {
      eventSource = ["iam.amazonaws.com"]
      eventName   = ["CreateUser"]
    }
  })

  depends_on = [aws_cloudwatch_event_bus.critical_notifications]
}

#rule: IAM ID center user created
resource "aws_cloudwatch_event_rule" "crit_iam_org_user_created" {
  name           = "org_iam_user_created"
  description    = "user has been created for the organization"
  event_bus_name = aws_cloudwatch_event_bus.critical_notifications.name

  event_pattern = jsonencode({
    source      = ["aws.identitystore"]
    detail-type = ["AWS API to create organizational user"]
    detail = {
      eventSource = ["identitystore.amazonaws.com"]
      eventName   = ["CreateUser"]
    }
  })

  depends_on = [aws_cloudwatch_event_bus.critical_notifications]
}

#rule: KMS key scheduled for deletion
resource "aws_cloudwatch_event_rule" "crit_kms_key_sched_deletion" {
  name           = "kms_key_deletion"
  description    = "a encryption key managed by KMS has been scheduled for deletion"
  event_bus_name = aws_cloudwatch_event_bus.critical_notifications.name

  event_pattern = jsonencode({
    source      = ["aws.kms"]
    detail-type = ["AWS API to delete a key in the Key Management Service (KMS) "]
    detail = {
      eventSource = ["kms.amazonaws.com"]
      eventName   = ["ScheduleKeyDeletion"]
    }
  })

  depends_on = [aws_cloudwatch_event_bus.critical_notifications]
}

#rule: AWS guardduty generate critical only findings
resource "aws_cloudwatch_event_rule" "crit_guardduty_crit_findings" {
  name           = "guardduty_critical_findings"
  description    = "AWS Guard Duty generated a notification at a 'critical' level - immediate attention"
  event_bus_name = aws_cloudwatch_event_bus.critical_notifications.name

  event_pattern = jsonencode({
    source      = ["aws.guardduty"]
    detail-type = ["GuardDuty Finding"]
    detail = {
      severity = var.severity
    }
  })

  depends_on = [aws_cloudwatch_event_bus.critical_notifications]
}


#=================================================================

#======================== SNS Policy ==============================
resource "aws_sns_topic_policy" "critical_updates_policy" {
  arn = aws_sns_topic.critical_updates.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "events.amazonaws.com"
        }
        Action   = "SNS:Publish"
        Resource = aws_sns_topic.critical_updates.arn
      }
    ]
  })
}
#=================================================================

#======================== Send Notification ======================
resource "aws_cloudwatch_event_target" "critical_notifications" {
  for_each = toset([
    aws_cloudwatch_event_rule.crit_iam_user_created.name,
    aws_cloudwatch_event_rule.crit_iam_org_user_created.name,
    aws_cloudwatch_event_rule.crit_kms_key_sched_deletion.name,
    aws_cloudwatch_event_rule.crit_guardduty_crit_findings.name,
  ])

  rule           = each.value
  target_id      = "SendToSNS"
  arn            = aws_sns_topic.critical_updates.arn
  event_bus_name = aws_cloudwatch_event_bus.critical_notifications.name
}
#=================================================================



#rules 
# EventBridge Event Patterns (base syntax):
# https://docs.aws.amazon.com/eventbridge/latest/userguide/eb-event-patterns.html

# GuardDuty Events in EventBridge:
# https://docs.aws.amazon.com/guardduty/latest/ug/guardduty-findings-cloudwatch-events.html

# CloudTrail API Events (for IAM, KMS events):
# https://docs.aws.amazon.com/awscloudtrail/latest/userguide/cloudtrail-log-file-examples.html

# AWS Service Event Sources:
# https://docs.aws.amazon.com/eventbridge/latest/userguide/eb-service-targets.html

# GuardDuty Finding Severity Levels:
# https://docs.aws.amazon.com/guardduty/latest/ug/guardduty_findings.html






