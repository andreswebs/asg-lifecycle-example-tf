locals {
  lambda_dir         = abspath("${path.module}/lambda")
  lambda_src_dir     = abspath("${local.lambda_dir}/src")
  lambda_dist_dir    = abspath("${local.lambda_dir}/dist")
  lambda_archive_dir = abspath("${local.lambda_dir}/archive")
  lambda_archive     = "${local.lambda_archive_dir}/lambda.zip"
  keeper_config      = { for filename in fileset(local.lambda_dir, "*.json") : filename => filemd5("${local.lambda_dir}/${filename}") }
  keeper_src         = { for filename in fileset(local.lambda_src_dir, "*.ts") : filename => filemd5("${local.lambda_src_dir}/${filename}") }
}

resource "random_uuid" "lambda_src_hash" {
  keepers = merge(local.keeper_config, local.keeper_src)
}

resource "null_resource" "lambda_dependencies" {
  provisioner "local-exec" {
    working_dir = local.lambda_dir
    interpreter = [
      "sh", "-c"
    ]
    command = "npm install"
  }

  triggers = {
    uuid = random_uuid.lambda_src_hash.result
  }
}

resource "null_resource" "lambda_dist" {
  depends_on = [null_resource.lambda_dependencies]
  provisioner "local-exec" {
    working_dir = local.lambda_dir
    interpreter = [
      "sh", "-c"
    ]
    command = "npm run build"
  }

  triggers = {
    uuid = random_uuid.lambda_src_hash.result
  }
}

resource "null_resource" "lambda_all" {
  depends_on = [null_resource.lambda_dist]
  provisioner "local-exec" {
    working_dir = local.lambda_dir
    interpreter = [
      "sh", "-c"
    ]
    command = "cp -r ${local.lambda_dir}/node_modules ${local.lambda_dist_dir}"
  }

  triggers = {
    uuid = random_uuid.lambda_src_hash.result
  }
}

data "archive_file" "lambda_package" {
  depends_on       = [null_resource.lambda_all]
  type             = "zip"
  source_dir       = local.lambda_dist_dir
  output_path      = local.lambda_archive
  output_file_mode = "0644"
}
