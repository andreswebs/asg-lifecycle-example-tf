resource "aws_cloudwatch_event_rule" "lifecycle" {
  name        = "${var.name}-autoscaling-lifecycle"
  description = "Notify on autoscaling lifecycle events for ${aws_autoscaling_group.this.name}"
  event_pattern = templatefile("${path.module}/tpl/lifecycle.event-pattern.json.tftpl", {
    asg_name = aws_autoscaling_group.this.name
  })
}

resource "aws_cloudwatch_event_target" "lambda" {
  target_id = "${var.name}-autoscaling-lifecycle-launch"
  rule      = aws_cloudwatch_event_rule.lifecycle.name
  arn       = aws_lambda_function.this.arn
}

resource "aws_lambda_permission" "lifecycle_event" {
  statement_id_prefix = "eventbridge"
  principal           = "events.amazonaws.com"
  action              = "lambda:InvokeFunction"
  function_name       = aws_lambda_function.this.function_name
  source_arn          = aws_cloudwatch_event_rule.lifecycle.arn
}
