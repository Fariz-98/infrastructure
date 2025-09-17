resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = merge(var.tags, { Name = "${var.name_prefix}-vpc" })
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags = merge(var.tags, { Name = "${var.name_prefix}-igw" })
}

resource "aws_subnet" "public" {
  for_each = var.public_subnets
  vpc_id = aws_vpc.main.id
  cidr_block = each.value.cidr
  availability_zone = each.value.az
  map_public_ip_on_launch = true
  tags = merge(var.tags, { Name = "${var.name_prefix}-public-${each.key}" })
}

resource "aws_subnet" "private" {
  for_each                = var.private_subnets
  vpc_id                  = aws_vpc.main.id
  cidr_block              = each.value.cidr
  availability_zone       = each.value.az
  map_public_ip_on_launch = false
  tags = merge(var.tags, { Name = "${var.name_prefix}-private-${each.key}" })
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  tags = merge(var.tags, { Name = "${var.name_prefix}-rt-public" })
}

resource "aws_route" "public_internet" {
  route_table_id = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "public" {
  for_each = aws_subnet.public
  route_table_id = aws_route_table.public.id
  subnet_id = each.value.id
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
  tags = merge(var.tags, { Name = "${var.name_prefix}-rt-private" })
}

resource "aws_route_table_association" "private" {
  for_each = aws_subnet.private
  route_table_id = aws_route_table.private.id
  subnet_id = each.value.id
}

resource "aws_security_group" "vpce_sg" {
  name = "${var.name_prefix}-vpce-sg"
  description = "Allow HTTPS/HTTP from app to ENIs VPC Endpoints"
  vpc_id = aws_vpc.main.id

  egress {
    description = "Allow all egress"
    from_port = 0
    protocol  = "-1"
    to_port   = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${var.name_prefix}-vpce-sg" })
}

resource "aws_vpc_endpoint" "gateway" {
  count = var.create_s3_gateway_endpoint ? 1 : 0
  service_name = "com.amazonaws.${var.region}.s3"
  vpc_id       = aws_vpc.main.id
  vpc_endpoint_type = "Gateway"
  route_table_ids = [aws_route_table.private.id]

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow",
        Principal = "*",
        Action = ["s3:*"],
        Resource = ["*"]
      }
    ]
  })

  tags = merge(var.tags, { Name = "${var.name_prefix}-s3-gw" })
}

resource "aws_vpc_endpoint" "interfaces" {
  for_each = toset(var.interface_services)

  service_name = each.value
  vpc_id       = aws_vpc.main.id
  vpc_endpoint_type = "Interface"
  subnet_ids = [for s in aws_subnet.private : s.id]
  security_group_ids = [aws_security_group.vpce_sg.id]
  private_dns_enabled = true

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-${replace(each.value, "com.amazonaws.${var.region}.", "")}"
  })
}

# Logs
resource "aws_cloudwatch_log_group" "vpc_flow" {
  count = var.enable_vpc_flow_logs ? 1 : 0
  name = "/aws/vpc/${var.env}-flow"
  retention_in_days = var.vpc_flow_log_retention_days
}

data "aws_iam_policy_document" "vpc_flow_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      identifiers = ["vpc-flow-logs.amazonaws.com"]
      type        = "Service"
    }
  }
}

data "aws_iam_policy_document" "vpc_flow_policy" {
  statement {
    sid = "VpcLogs"
    effect = "Allow"
    actions = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = [aws_cloudwatch_log_group.vpc_flow[0].arn]
  }
}

module "vpc_flow_role" {
  source = "../../services/iam/role"

  count = var.enable_vpc_flow_logs ? 1 : 0
  name = "tf-${var.env}-vpc-flowlogs-role"

  trust_policy_json = data.aws_iam_policy_document.vpc_flow_assume.json
  inline_policies = {
    "vpc-logs-policy" = data.aws_iam_policy_document.vpc_flow_policy.json
  }
}

resource "aws_flow_log" "vpc" {
  count = var.enable_vpc_flow_logs ? 1 : 0

  vpc_id = aws_vpc.main.id
  log_destination_type = "cloud-watch-logs"
  log_destination = aws_cloudwatch_log_group.vpc_flow[0].arn
  iam_role_arn = module.vpc_flow_role[0].role_arn

  traffic_type = var.vpc_flow_log_traffic_type
  max_aggregation_interval = var.vpc_flow_log_aggregation_seconds
}