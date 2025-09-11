output "ecr_journal_repo_url" {
  value = aws_ecr_repository.journal.repository_url
}

output "ecr_journal_repo_arn" {
  value = aws_ecr_repository.journal.arn
}