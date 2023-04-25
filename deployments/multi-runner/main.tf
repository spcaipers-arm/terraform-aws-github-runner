locals {
  prefix      = "Proj"
  aws_region  = "eu-west-1"
  profile     = "debug-prod"
  create_service_linked_role_spot = true
  # debug_prod vpc and subnets.
  subnet_ids = ["subnet-06a7c4e4386a34d64", "subnet-06bd33a279f9b1a2a"]
  vpc_id     = "vpc-012989de052a92752"
  s3_backend_bucket_name = "tf-state-file-287871436243"
  dynamodb_table = "s3_backend_terraform_state"

  # Load runner configurations from Yaml files
  multi_runner_config = { for c in fileset("${path.module}/templates/runner-configs", "*.yaml") : trimsuffix(c, ".yaml") => yamldecode(file("${path.module}/templates/runner-configs/${c}")) }
}

resource "random_id" "random" {
  byte_length = 20
}

module "multi-runner" {
  source              = "../../modules/multi-runner"
  multi_runner_config = local.multi_runner_config

  aws_region                        = local.aws_region
  vpc_id                            = local.vpc_id
  subnet_ids                        = local.subnet_ids

  runners_scale_up_lambda_timeout   = 60
  runners_scale_down_lambda_timeout = 60

  prefix                            = local.prefix
  tags = {
    Project = "SpikeSelfHostedRunners"
  }

  # Getting from Secrets Manager - manually added it there.
  github_app = {
    key_base64     = jsondecode(data.aws_secretsmanager_secret_version.github_app.secret_string)["key_base64"]
    id             = jsondecode(data.aws_secretsmanager_secret_version.github_app.secret_string)["id"]
    webhook_secret = random_id.random.hex
  }

  role_path                     = "/"
  role_permissions_boundary	    = "arn:aws:iam::287871436243:policy/ProjAdminsPermBoundaryv2"

  # run lambdas-download terraform module
  webhook_lambda_zip                = "../lambdas-download/webhook.zip"
  runner_binaries_syncer_lambda_zip = "../lambdas-download/runner-binaries-syncer.zip"
  runners_lambda_zip                = "../lambdas-download/runners.zip"
}
