module "network" {
  source = "./modules/network"

  pj_name  = "training-tf"
  vpc_cidr = "13.0.0.0/16"
  alb_public_subnets = [
    {
      az   = "ap-northeast-1a"
      cidr = "13.0.0.0/24"
    },
    {
      az   = "ap-northeast-1c"
      cidr = "13.0.1.0/24"
    }
  ]
  ecs_public_subnets = [
    {
      az   = "ap-northeast-1a"
      cidr = "13.0.2.0/24"
    }
  ]
}

module "compute" {
  source = "./modules/compute"

  pj_name                = "training-tf"
  vpc_id                 = module.network.vpc_id
  alb_public_subnet_ids  = module.network.alb_public_subnet_ids
  ecs_public_subnet_ids  = module.network.ecs_public_subnet_ids
  ecs_cpu                = "256"
  ecs_memory             = "1024"
  ecs_task_desired_count = "1"
}
