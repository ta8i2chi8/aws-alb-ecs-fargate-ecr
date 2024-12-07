output "vpc_id" {
  value       = aws_vpc.main.id
  description = "VPCのID"
}

output "alb_public_subnet_ids" {
  value       = aws_subnet.alb_public[*].id
  description = "ALBで利用するパブリックサブネットのID"
}

output "ecs_public_subnet_ids" {
  value       = aws_subnet.ecs_public[*].id
  description = "ECSで利用するパブリックサブネットのID"
}
