module "ec2_role" {
  source       = "andreswebs/ec2-role/aws"
  version      = "1.0.0"
  role_name    = var.name
  profile_name = var.name
  policies = [
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
    "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy",
    "arn:aws:iam::aws:policy/AmazonSSMDirectoryServiceAccess"
  ]
}

module "s3_requisites_for_ssm" {
  source  = "andreswebs/s3-requisites-for-ssm-policy-document/aws"
  version = "1.0.0"
}

resource "aws_iam_role_policy" "s3_requisites_for_ssm" {
  name   = "s3-requisites-for-ssm"
  role   = module.ec2_role.role.name
  policy = module.s3_requisites_for_ssm.json
}

data "aws_iam_policy_document" "complete_lifecycle_action" {
  statement {
    sid       = "completeaction"
    actions   = ["autoscaling:CompleteLifecycleAction"]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "complete_lifecycle_action" {
  name   = "complete-lifecycle-action"
  role   = module.ec2_role.role.name
  policy = data.aws_iam_policy_document.complete_lifecycle_action.json
}
