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

data "external" "lambda_dependencies" {
  program = [
    abspath("${path.module}/scripts/install.sh"),
    local.lambda_dir,
    random_uuid.lambda_src_hash.result
  ]
}


data "external" "lambda_dist" {
  depends_on = [data.external.lambda_dependencies]
  program    = [
    abspath("${path.module}/scripts/build.sh"),
    local.lambda_dir,
    random_uuid.lambda_src_hash.result
  ]
}

data "external" "lambda_bundle" {
  depends_on = [data.external.lambda_dist]
  program    = [
    abspath("${path.module}/scripts/bundle.sh"),
    "${local.lambda_dir}/node_modules",
    local.lambda_dist_dir,
    random_uuid.lambda_src_hash.result
  ]
}

data "archive_file" "lambda_package" {
  depends_on       = [data.external.lambda_bundle]
  type             = "zip"
  source_dir       = local.lambda_dist_dir
  output_path      = local.lambda_archive
  output_file_mode = "0644"
}
