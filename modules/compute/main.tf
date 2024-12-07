locals {
  alb_security_group_ingress_rules = [
    {
      cidr      = "0.0.0.0/0"
      from_port = "80"
      to_port   = "80"
    }
  ]
  ecs_security_group_ingress_rules = [
    {
      referenced_security_group_id = aws_security_group.alb.id
      from_port                    = "80"
      to_port                      = "80"
    }
  ]
}

# ALB
resource "aws_lb" "main" {
  name               = "${var.pj_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = var.alb_public_subnet_ids

  tags = {
    Name = "${var.pj_name}-alb"
  }
}

# ターゲットグループ
resource "aws_lb_target_group" "main" {
  name             = "${var.pj_name}-tg"
  target_type      = "ip"
  protocol_version = "HTTP1"
  port             = 80
  protocol         = "HTTP"
  vpc_id           = var.vpc_id

  health_check {
    path                = "/"
    port                = "traffic-port"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200"
  }

  tags = {
    Name = "${var.pj_name}-tg"
  }
}

# リスナー（HTTP）
resource "aws_lb_listener" "main" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }
}

# ALB用セキュリティグループ
resource "aws_security_group" "alb" {
  name        = "${var.pj_name}-alb-sg"
  description = "${var.pj_name} alb sg"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.pj_name}-alb-sg"
  }
}
resource "aws_vpc_security_group_ingress_rule" "alb" {
  count = length(local.alb_security_group_ingress_rules)

  security_group_id = aws_security_group.alb.id
  cidr_ipv4         = local.alb_security_group_ingress_rules[count.index].cidr
  ip_protocol       = "TCP"
  from_port         = local.alb_security_group_ingress_rules[count.index].from_port
  to_port           = local.alb_security_group_ingress_rules[count.index].to_port
}
resource "aws_vpc_security_group_egress_rule" "alb" {
  security_group_id = aws_security_group.alb.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}



# 既存のECRリポジトリを参照
data "aws_ecr_repository" "nginx" {
  name = "nginx"
}

# ECSタスク定義
resource "aws_ecs_task_definition" "nginx" {
  family = "nginx"

  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"

  cpu    = var.ecs_cpu
  memory = var.ecs_memory

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "ARM64"
  }

  # 起動するコンテナの定義
  container_definitions = jsonencode([
    {
      name  = "nginx",
      image = "${data.aws_ecr_repository.nginx.repository_url}:0.0.1",
      portMappings = [
        {
          containerPort = 80,
          hostPort      = 80,
          protocol      = "tcp"
        }
      ],
      logConfiguration = {
        logDriver = "awslogs",
        options = {
          awslogs-group         = aws_cloudwatch_log_group.ecs.name,
          awslogs-region        = "ap-northeast-1",
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
}

# ECSクラスタ
resource "aws_ecs_cluster" "main" {
  name = "${var.pj_name}-ecs-cluster"
}

# ECSサービス
resource "aws_ecs_service" "nginx" {
  name = "${var.pj_name}-ecs-service"

  cluster     = aws_ecs_cluster.main.id
  launch_type = "FARGATE"

  desired_count   = var.ecs_task_desired_count
  task_definition = aws_ecs_task_definition.nginx.arn

  network_configuration {
    subnets          = var.ecs_public_subnet_ids
    security_groups  = [aws_security_group.ecs.id]
    assign_public_ip = true
  }

  # ECSタスクの起動に使用するロードバランサー
  load_balancer {
    target_group_arn = aws_lb_target_group.main.arn
    container_name   = "nginx"
    container_port   = "80"
  }
}

# CloudWatch ロググループ
resource "aws_cloudwatch_log_group" "ecs" {
  name = "/ecs/logs/nginx"
}

# ECS用セキュリティグループ
resource "aws_security_group" "ecs" {
  name        = "${var.pj_name}-ecs-sg"
  description = "${var.pj_name} ecs sg"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.pj_name}-ecs-sg"
  }
}
resource "aws_vpc_security_group_ingress_rule" "ecs" {
  count = length(local.ecs_security_group_ingress_rules)

  security_group_id            = aws_security_group.ecs.id
  referenced_security_group_id = local.ecs_security_group_ingress_rules[count.index].referenced_security_group_id
  ip_protocol                  = "TCP"
  from_port                    = local.ecs_security_group_ingress_rules[count.index].from_port
  to_port                      = local.ecs_security_group_ingress_rules[count.index].to_port
}
resource "aws_vpc_security_group_egress_rule" "ecs" {
  security_group_id = aws_security_group.ecs.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

# ECS用 タスク実行ロール
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "${var.pj_name}-ecs-task-execution-role"

  assume_role_policy = jsonencode(
    {
      Statement = [
        {
          Action = "sts:AssumeRole"
          Effect = "Allow"
          Principal = {
            Service = "ecs-tasks.amazonaws.com"
          }
        },
      ]
      Version = "2012-10-17"
    }
  )
}
resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}
