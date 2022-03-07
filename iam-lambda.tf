data "aws_iam_policy_document" "lambda_exec" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "lambda_logs" {

  statement {
    sid = "logs"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = [
      "${local.lambda_log_group_arn}",
      "${local.lambda_log_group_arn}:*",
      "${local.lambda_log_group_arn}:*:*"
    ]
  }

}

locals {
  instance_arn_prefix = "arn:${data.aws_partition.current.partition}:ec2:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:instance"
}

data "aws_iam_policy_document" "lambda_send_command" {
  
  statement {
    effect    = "Allow"
    actions   = ["ssm:SendCommand"]
    resources = ["${local.instance_arn_prefix}/*"]
  }

  statement {
    effect  = "Allow"
    actions = ["ssm:SendCommand"]
    resources = [
      aws_ssm_document.launch.arn,
      aws_ssm_document.terminate.arn,
    ]
  }

  statement {
    effect    = "Allow"
    actions   = ["ec2:DescribeInstanceStatus"]
    resources = ["*"]
  }

}

data "aws_iam_policy_document" "lambda_read_config" {
  statement {
    effect = "Allow"
    actions = [
      "dynamodb:GetItem",
      "dynamodb:BatchGetItem",
      "dynamodb:Scan",
      "dynamodb:Query",
      "dynamodb:ConditionCheckItem"      
    ]
    resources = [aws_dynamodb_table.asg_handler_config.arn]
  }
}

data "aws_iam_policy_document" "lambda_permissions" {
  source_policy_documents = [
    data.aws_iam_policy_document.lambda_logs.json,
    data.aws_iam_policy_document.lambda_send_command.json,
    data.aws_iam_policy_document.lambda_read_config.json,
  ]
}

resource "aws_iam_role" "lambda_exec" {
  name                  = local.lambda_name
  assume_role_policy    = data.aws_iam_policy_document.lambda_exec.json
  force_detach_policies = true
}

resource "aws_iam_role_policy" "lambda_permissions" {
  name   = "lambda-permissions"
  role   = aws_iam_role.lambda_exec.id
  policy = data.aws_iam_policy_document.lambda_permissions.json
}

resource "aws_iam_role_policy_attachment" "xray_permissions" {
  role       = aws_iam_role.lambda_exec.id
  policy_arn = "arn:aws:iam::aws:policy/AWSXrayWriteOnlyAccess"
}
