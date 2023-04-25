provider "aws" {
  region = local.aws_region
  profile = local.profile
  default_tags {
    tags = {
      Example = local.environment
    }
  }
  // If you use roles with specific permissions please add your role
  // assume_role {
  //   role_arn = "arn:aws:iam::123456789012:role/MyAdminRole"
  // }
}

provider "random" {
}
