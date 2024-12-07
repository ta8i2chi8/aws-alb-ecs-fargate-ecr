variable "pj_name" {
  type        = string
  description = "PJ名"
}

variable "vpc_id" {
  type        = string
  description = "VPCのID"
}

variable "alb_public_subnet_ids" {
  type        = list(string)
  description = "ALBで利用するパブリックサブネットのIDのリスト"
}

variable "ecs_public_subnet_ids" {
  type        = list(string)
  description = "ECSで利用するパブリックサブネットのIDのリスト"
}

variable "ecs_cpu" {
  type        = string
  description = "ECSタスクのCPU上限"
}

variable "ecs_memory" {
  type        = string
  description = "ECSタスクのメモリ上限"
}

variable "ecs_task_desired_count" {
  type        = number
  description = "ECSサービスのタスク起動数"
}
