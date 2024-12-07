# VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.pj_name}-vpc"
  }
}

# インターネットゲートウェイ
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.pj_name}-igw"
  }
}

# パブリックサブネット（ALB)
resource "aws_subnet" "alb_public" {
  count = length(var.alb_public_subnets)

  vpc_id            = aws_vpc.main.id
  cidr_block        = var.alb_public_subnets[count.index].cidr
  availability_zone = var.alb_public_subnets[count.index].az

  tags = {
    Name = "${var.pj_name}-alb-public-${var.alb_public_subnets[count.index].az}-subnet"
  }
}

# パブリックサブネット（ECS)
resource "aws_subnet" "ecs_public" {
  count = length(var.ecs_public_subnets)

  vpc_id            = aws_vpc.main.id
  cidr_block        = var.ecs_public_subnets[count.index].cidr
  availability_zone = var.ecs_public_subnets[count.index].az

  tags = {
    Name = "${var.pj_name}-ecs-public-${var.ecs_public_subnets[count.index].az}-subnet"
  }
}

# パブリックサブネット用RT
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.pj_name}-public-rt"
  }
}
resource "aws_route" "public_default_route" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id
}
# 各パブリックサブネットをルートテーブルに関連付ける
resource "aws_route_table_association" "alb_public" {
  count = length(aws_subnet.alb_public)

  subnet_id      = aws_subnet.alb_public[count.index].id
  route_table_id = aws_route_table.public.id
}
resource "aws_route_table_association" "ecs_public" {
  count = length(aws_subnet.ecs_public)

  subnet_id      = aws_subnet.ecs_public[count.index].id
  route_table_id = aws_route_table.public.id
}
