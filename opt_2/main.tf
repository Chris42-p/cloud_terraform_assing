#one region 
provider "aws" {
  region = var.region #ca-cental-1

    default_tags {
      tags = {
        Owner="Chris"
        Name="option2_guardduty"
        Env="dev"
      }
    }
}

#AWS SNS Topic With set of email subscribers 
resource "aws_sns_topic" "alerts_malware_s3_ec2" {
    name = "guard_duty_malware_alerts" #name of the topic.
}
    #aws sns topic subscription to email.
resource "aws_sns_topic_subscription" "guard_duty_s3_ec2_malware_notification" {
    count = length(var.email_list) #create a subscription for each email in the list.
    endpoint = var.email_list[count.index] #needs to be first else block is red
    protocol = "email"
    topic_arn = aws_sns_topics.alerts_malware_s3_ec2.arn
}

#AWS Guard Duty. 
resource "aws_guardduty_detector" "main" {
  #region = var.region #can be set here or in the provider block.
    enable = true #enable guard duty

    datasources {
        s3_logs {
        enable = true
        }
    }

    malware_protection {
        scan_ec2_instance_with_findings {
        ebs_volumes {
            enable = true
        }
        }
    }

    tags = {
      Name="guard_duty_detector"
      Description="Guard Duty malware detection for ec2 and s3 buckes"
    }

}

#EventBridge Rules which detect and notify to SNS 
resource "aws_cloudwatch_event_rule" "opt2_rules" {
    name="opt2_rule_set"
    description = "rules: 1) IAM user created. 2) IAM ID center user created, 3) AWS GuardDuty generate Critical only findings 4) KMS key scheduled for deletion"

    event_pattern = jsonencode({
        source =["aws.guardduty"]
        detail-type=["GuardDuty Finding"]
    })
}

#forward findings to SNS. 
resource "aws_cloudwatch_event_target" "guard_duty_to_sns" {
    rule=aws_cloudwatch_event_rule.opt2_rules.name
    arn       = aws_sns_topic.alerts_malware_s3_ec2.arn  # point to the topic, 
    target_id = "send_sns"
}
    
#allow eventbridge to publish to SNS 
resource "aws_sns_topic_policy" "guard_duty_malware_alerts" {
  arn = aws_sns_topic.alerts_malware_s3_ec2.arn  # point to topic, 
  
  policy = jsondecode({
    Version="2026-03-26_v1"
    Statement=[{
        Effect="Allow"
        Principal= {Service= "events.amazonaws.com"}
        Action="sns:Publish"
        Resource=aws_sns_topics.alerts_malware_s3_ec2.arn
    }]
  })

}

#-----------Guard duty rule set
#rule 1 - IAM user created
resource "aws_cloudwatch_event_rule" "iam_user_created" {
    name="iam-user-created"
    description = "Triggered because an IAM user was created"

    event_pattern = jsonencode({
        source=["aws.iam"]
        detail-type=["aws api call via CloudTrail"]
        detail={
            evertSource=["iam.amazonaws.com"]
            eventName=["CreateUser"]
        }
    })
}

#rule 2 - IAM ID center user created
resource "aws_cloudwatch_event_rule" "sso_user_created" {
    name="sso-user-created"
    description = "Triggers whe IAM ID center user is created"

    event_pattern = jsondecode({
        source=["aws.sso-directory"]
        detail-type=["AWS API Call via CloudTrail"]
        detail={
            eventSource=["sso-directory.amazonaws.com"]
            eventName=["CreateUser"]
        }
    })
}

#rule 3 - GuardDuty Critical findings only 
resource "aws_cloudwatch_event_rule" "guardduty_critical_event" {
    name="guardduty-critical-findings"
    description = "triggers on guardduty critical serverity findings only "

    event_pattern = jsondecode({
        source=["aws.guardduty"]
        detail-type=["GuardDuty findings"]
        detail={
            serverity=[{numeric = [">=",9.0]}] #7,8 =high, 9,10=critical
        }

    })
}

#rule 4 -KMS key scheduled for deletion 



