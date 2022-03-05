
# resource "aws_sns_topic" "this" {
#   name = var.name
# }

# data "aws_iam_policy_document" "publish_notifications" {
#   statement {
#     actions   = ["sns:Publish"]
#     resources = [aws_sns_topic.this.arn]
#   }
# }

# data "aws_iam_policy_document" "ssm_trust" {
#   statement {
#     actions = ["sts:AssumeRole"]
#     principals {
#       type        = "Service"
#       identifiers = ["ssm.amazonaws.com"]
#     }
#   }
# }

# data "aws_iam_policy_document" "complete_lifecycle" {
#   statement {
#     actions   = ["autoscaling:CompleteLifecyleAction"]
#     resources = [aws_autoscaling_group.this.arn]
#   }
# }

# resource "aws_iam_role_policy" "ec2_complete_lifecycle" {
#   name   = "complete-lifecycle"
#   role   = module.ec2_role.role.name
#   policy = data.aws_iam_policy_document.complete_lifecycle.json
# }

# data "aws_iam_policy_document" "autoscaling_trust" {
#   statement {
#     actions = ["sts:AssumeRole"]
#     principals {
#       type        = "Service"
#       identifiers = ["autoscaling.amazonaws.com"]
#     }
#   }
# }

# resource "aws_iam_role" "ssm" {
#   name               = "${var.name}-ssm"
#   assume_role_policy = data.aws_iam_policy_document.ssm_trust.json
# }

# resource "aws_iam_role_policy" "ssm_publish_notifications" {
#   name   = "sns-publish"
#   role   = aws_iam_role.ssm.id
#   policy = data.aws_iam_policy_document.publish_notifications.json
# }

# resource "aws_iam_role_policy" "ssm_complete_lifecycle" {
#   name   = "complete-lifecycle"
#   role   = aws_iam_role.ssm.id
#   policy = data.aws_iam_policy_document.complete_lifecycle.json
# }

# resource "aws_iam_role" "autoscaling_lifecycle" {
#   name               = "${var.name}-autoscaling-lifecycle"
#   assume_role_policy = data.aws_iam_policy_document.autoscaling_trust.json
# }

# resource "aws_iam_role_policy" "autoscaling_publish_notifications" {
#   name   = "sns-publish"
#   role   = aws_iam_role.autoscaling_lifecycle.id
#   policy = data.aws_iam_policy_document.publish_notifications.json
# }



/*
Permissions:

Lambda, or Maintenance Window, or User, must have the iam:PassRole permission to pass the role created for SSM (aws_iam_role.ssm.arn)

<https://docs.aws.amazon.com/systems-manager/latest/userguide/monitoring-sns-notifications.html

*/
