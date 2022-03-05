data "aws_partition" "current" {}
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

data "aws_ami" "windows" {
  most_recent = true
  filter {
    name   = "name"
    values = ["Windows_Server-2019-English-Full-Base-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["801119661308"]
}


resource "aws_security_group" "this" {
  vpc_id = var.vpc_id

  revoke_rules_on_delete = true

  ingress {
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    self        = true
    cidr_blocks = var.cidr_whitelist
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "${var.name}-sg"
  }

  name = "${var.name}-sg"

}

module "ec2_key" {
  source             = "andreswebs/insecure-ec2-key-pair/aws"
  version            = "1.0.0"
  key_name           = "${var.name}-ssh"
  ssm_parameter_name = "/${var.name}/ssh-key"
}

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

resource "aws_launch_template" "this" {
  name                   = var.name
  description            = "${var.name} launch template"
  update_default_version = true
  instance_type          = var.instance_type
  image_id               = data.aws_ami.windows.id
  vpc_security_group_ids = [aws_security_group.this.id]
  key_name               = module.ec2_key.key_pair.key_name

  monitoring {
    enabled = var.monitoring_enabled
  }

  iam_instance_profile {
    name = module.ec2_role.instance_profile.name
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = var.name
    }
  }

  lifecycle {
    create_before_destroy = true
  }

}

resource "aws_autoscaling_group" "this" {
  name = var.name

  desired_capacity = 1
  max_size         = 1
  min_size         = 0

  launch_template {
    id      = aws_launch_template.this.id
    version = aws_launch_template.this.latest_version
  }

  vpc_zone_identifier = var.subnet_ids

  lifecycle {
    ignore_changes = [
      desired_capacity,
      max_size,
      min_size
    ]
  }

}

resource "aws_autoscaling_lifecycle_hook" "launch" {
  name                   = "${var.name}-launch"
  autoscaling_group_name = aws_autoscaling_group.this.name
  default_result         = "ABANDON"
  heartbeat_timeout      = 3600
  lifecycle_transition   = "autoscaling:EC2_INSTANCE_LAUNCHING"
}

resource "aws_autoscaling_lifecycle_hook" "termination" {
  name                   = "${var.name}-termination"
  autoscaling_group_name = aws_autoscaling_group.this.name
  default_result         = "ABANDON"
  heartbeat_timeout      = 3600
  lifecycle_transition   = "autoscaling:EC2_INSTANCE_TERMINATING"
}
