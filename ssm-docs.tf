locals {
  ssm_docs = "${path.module}/tpl"
}

## ssm doc launch
resource "aws_ssm_document" "launch" {
  name            = "${var.name}-launch"
  document_format = "YAML"
  document_type   = "Command"
  target_type     = "/AWS::EC2::Instance"

  content = file("${local.ssm_docs}/launch.ssm-doc.yaml")
}

## ssm doc terminate
resource "aws_ssm_document" "terminate" {
  name            = "${var.name}-terminate"
  document_format = "YAML"
  document_type   = "Command"
  target_type     = "/AWS::EC2::Instance"

  content = file("${local.ssm_docs}/terminate.ssm-doc.yaml")
}
