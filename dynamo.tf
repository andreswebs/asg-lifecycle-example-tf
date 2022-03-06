locals {
  asg_handler_hash_key = "AutoscalingGroupName"
  asg_handler_config = [
   {
      asg_name = aws_autoscaling_group.this.name
      launch_doc_name = aws_ssm_document.launch.name
      terminate_doc_name = aws_ssm_document.terminate.name
   }
  ]
}

resource "aws_dynamodb_table" "asg_handler_config" {
  name         = "autoscaling-handler-config"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = local.asg_handler_hash_key

  attribute {
    name = local.asg_handler_hash_key
    type = "S"
  }

  tags = {
    Name = "autoscaling-handler-config"
  }
}

resource "aws_dynamodb_table_item" "asg_doc_map" {
  count      = length(local.asg_handler_config)
  table_name = aws_dynamodb_table.asg_handler_config.name
  hash_key   = aws_dynamodb_table.asg_handler_config.hash_key
  item = templatefile("${path.module}/tpl/handler-config-item.json.tftpl", {
    hash_key           = local.asg_handler_hash_key
    asg_name           = local.asg_handler_config[count.index].asg_name
    launch_doc_name    = local.asg_handler_config[count.index].launch_doc_name
    terminate_doc_name = local.asg_handler_config[count.index].terminate_doc_name
  })
}
