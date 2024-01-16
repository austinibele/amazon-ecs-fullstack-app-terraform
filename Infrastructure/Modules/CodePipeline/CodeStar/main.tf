resource "aws_codestarconnections_connection" "codestar_connection" {
  name               = var.connection_name
  provider_type      = "GitHub"
}