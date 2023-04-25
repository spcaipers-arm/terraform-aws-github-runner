locals {
  environment = "ubuntu"
  prefix      = "Proj"
  aws_region  = "eu-west-1"
  profile     = "debug-prod"
  create_service_linked_role_spot = true
  subnet_ids = ["subnet-06a7c4e4386a34d64", "subnet-06bd33a279f9b1a2a"]
  vpc_id     = "vpc-012989de052a92752"
}

resource "random_id" "random" {
  byte_length = 20
}

# module "base" {
#   source = "../base"

#   prefix     = local.prefix
#   aws_region = local.aws_region
# }

module "runners" {
  source = "../../"

  aws_region = local.aws_region
  vpc_id     = local.vpc_id
  subnet_ids = local.subnet_ids

  create_service_linked_role_spot = local.create_service_linked_role_spot

  prefix = local.prefix
  tags = {
    Project = "ProjectX"
  }

  github_app = {
    key_base64     = var.github_app.key_base64
    id             = var.github_app.id
    webhook_secret = random_id.random.hex
  }

  # need to be manually downloaded
  webhook_lambda_zip                = "lambdas/webhook.zip"
  runner_binaries_syncer_lambda_zip = "lambdas/runner-binaries-syncer.zip"
  runners_lambda_zip                = "lambdas/runners.zip"


  enable_ssm_on_runners         = true
  enable_ephemeral_runners	    = false
  enable_organization_runners   = false
  # Using vanilla Ubuntu, should be false we have a custom AMI
  enable_userdata	              = true
  # The allocation strategy for spot instances. AWS recommends to use price-capacity-optimized however the AWS default is lowest-price.
  instance_allocation_strategy  = "lowest-price"
  instance_profile_path	        = null
  instance_target_capacity_type	= "spot"
  instance_types	              = [
    "m5.large",
    "m5a.large",
    "m5d.large",
    "c5.large",
    "m6i.large"
  ]
  role_path                     = "/"
  role_permissions_boundary	    = "arn:aws:iam::287871436243:policy/ProjAdminsPermBoundaryv2"
  runner_architecture	          = "x64"
  runner_as_root	              = false
  runner_ec2_tags	              = {}
  runner_extra_labels           = "debug-self-hosted-ubuntu-runner"
  runner_os	                    = "linux"
  runner_run_as                 = "ubuntu"
  runners_maximum_count         = 3


  # AMI selection and userdata
  #
  # option 1. configure your pre-built AMI + userdata
  userdata_template = "./templates/user-data.sh"
  ami_owners        = ["099720109477"] # Canonical's Amazon account ID
  ami_filter = {
    name = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  # Custom build AMI, no custom userdata needed.
  # option 2: Build custom AMI see ../../images/ubuntu-focal
  #           disable lines above (option 1) and enable the ones below
  # ami_filter = { name = ["github-runner-ubuntu-focal-amd64-*"] }
  # data "aws_caller_identity" "current" {}
  # ami_owners = [data.aws_caller_identity.current.account_id]

  block_device_mappings = [{
    # Set the block device name for Ubuntu root device
    device_name           = "/dev/sda1"
    delete_on_termination = true
    volume_type           = "gp3"
    volume_size           = 30
    encrypted             = true
    iops                  = null
    throughput            = null
    kms_key_id            = null
    snapshot_id           = null
  }]

  runner_log_files = [
    {
      "log_group_name" : "syslog",
      "prefix_log_group" : true,
      "file_path" : "/var/log/syslog",
      "log_stream_name" : "{instance_id}"
    },
    {
      "log_group_name" : "user_data",
      "prefix_log_group" : true,
      "file_path" : "/var/log/user-data.log",
      "log_stream_name" : "{instance_id}/user_data"
    },
    {
      "log_group_name" : "runner",
      "prefix_log_group" : true,
      "file_path" : "/opt/actions-runner/_diag/Runner_**.log",
      "log_stream_name" : "{instance_id}/runner"
    }
  ]

  # Uncomment to enable ephemeral runners
  # delay_webhook_event      = 0
  # enable_ephemeral_runners = true
  # enable_userdata         = true

  # Uncommet idle config to have idle runners from 9 to 5 in time zone Amsterdam
  # idle_config = [{
  #   cron      = "* * 9-17 * * *"
  #   timeZone  = "Europe/Amsterdam"
  #   idleCount = 1
  # }]

  # Enable logging all commands of user_data, secrets will be logged!!!
  # enable_user_data_debug_logging_runner = true
}
