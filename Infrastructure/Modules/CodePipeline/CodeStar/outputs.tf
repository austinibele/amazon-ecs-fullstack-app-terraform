output "codestar_connection_arn" {
  description = "The ARN of the CodeStar connection"
  value       = aws_codestarconnections_connection.codestar_connection.arn
}