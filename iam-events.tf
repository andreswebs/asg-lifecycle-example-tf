data "aws_iam_policy_document" "events_service" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "events" {
  name                  = "${var.name}-events"
  assume_role_policy    = data.aws_iam_policy_document.events_service.json
  force_detach_policies = true
}
