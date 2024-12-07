variable "pj_name" {
  type        = string
  description = "PJ名"
}

variable "vpc_cidr" {
  type        = string
  description = "VPCのCIDR"
}

variable "alb_public_subnets" {
  type = list(object(
    {
      az   = string
      cidr = string
    }
  ))
  description = "ALBで利用するパブリックサブネット情報のリスト"
}

variable "ecs_public_subnets" {
  type = list(object(
    {
      az   = string
      cidr = string
    }
  ))
  description = "ECSで利用するパブリックsサブネット情報のリスト"
}
