output "ecr_repository_url" {
  value = aws_ecr_repository.journal.repository_url
  description = "Registry URL for Docker tagging"
}