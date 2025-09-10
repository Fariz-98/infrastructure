output "ecr_journal_repo_url" {
  value = aws_ecr_repository.journal.repository_url
  description = "Registry URL for Docker tagging"
}

output "ecr_journal_repo_arn" {
  value = aws_ecr_repository.journal.arn
}