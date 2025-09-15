resource "aws_iam_role" "this" {
  name = var.name
  path = var.path
  assume_role_policy = var.trust_policy_json
  max_session_duration = var.max_session_duration
  permissions_boundary = var.permissions_boundary_arn
  tags = var.tags
}

resource "aws_iam_role_policy" "inline" {
  for_each = var.inline_policies
  name = each.key
  policy = each.value
  role   = aws_iam_role.this.id
}

resource "aws_iam_role_policy_attachment" "managed" {
  for_each = toset(var.managed_policy_arns)
  policy_arn = each.value
  role       = aws_iam_role.this.name
}