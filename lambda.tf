locals {
  lambda_name           = "autoscaling-lifecycle-handler"
  lambda_log_group_name = "/aws/lambda/${local.lambda_name}"
  lambda_log_group_arn  = "arn:${data.aws_partition.current.partition}:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:${local.lambda_log_group_name}"
}

resource "aws_cloudwatch_log_group" "this" {
  name              = local.lambda_log_group_name
  retention_in_days = 7
}

locals {
  lambda_env = {
    DB_TABLE_NAME = aws_dynamodb_table.asg_handler_config.name
    DB_HASH_KEY = aws_dynamodb_table.asg_handler_config.hash_key
  }
}

resource "aws_lambda_function" "this" {
  function_name    = local.lambda_name
  role             = aws_iam_role.lambda_exec.arn
  description      = "Handle Autoscaling Lifecycle hooks"
  runtime          = "nodejs14.x"
  package_type     = "Zip"
  filename         = data.archive_file.lambda_package.output_path
  source_code_hash = data.archive_file.lambda_package.output_base64sha256
  handler          = "app.handler"
  timeout          = 900

  tracing_config {
    mode = "Active"
  }

  depends_on = [
    aws_cloudwatch_log_group.this,
    aws_iam_role_policy_attachment.xray_permissions
  ]

  environment {
    variables = local.lambda_env
  }

}
