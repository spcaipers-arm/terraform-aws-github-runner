data "aws_secretsmanager_secret_version" "github_app" {
  secret_id = "github_app"
}
