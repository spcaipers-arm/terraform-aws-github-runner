terraform {
  backend "s3" {
    bucket          = "tf-state-file-287871436243"
    profile         = "debug-prod"
    key             = "tf_state"
    region          = "eu-west-1"
    dynamodb_table  = "s3_backend_terraform_state"
  }
}
