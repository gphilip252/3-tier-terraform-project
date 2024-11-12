provider "aws" {
  region = "us-east-1"
}

module "vpc" {
  source              = "./VPC"
  vpc_cidr_block      = var.vpc_cidr_block
  tags                = local.project_tags
  frontend_cidr_block = var.frontend_cidr_block
  availability_zone   = var.availability_zone
  backend_cidr_block  = var.backend_cidr_block
}
module "alb" {
  source                   = "./alb"
  frontend_subnet_az_1a_id = module.vpc.frontend_subnet_az_1a_id
  frontend_subnet_az_1b_id = module.vpc.frontend_subnet_az_1b_id
  tags                     = local.project_tags
  ssl_policy               = var.ssl_policy
  vpc_id                   = module.vpc.vpc_id
  certificate_arn          = var.certificate_arn
}

module "auto-scaling" {
  source                   = "./auto-scaling"
  instance_type            = var.instance_type
  key_name                 = var.key_name
  frontend_subnet_az_1a_id = module.vpc.frontend_subnet_az_1a_id
  frontend_subnet_az_1b_id = module.vpc.frontend_subnet_az_1b_id
  alb_sg_id                = module.alb.alb_sg_id
  target_group_arn         = module.alb.target_group_arn
  image_id                 = var.image_id
  vpc_id                   = module.vpc.vpc_id
  zone_id                  = var.zone_id
}

module "route53" {
  source       = "./route53"
  alb_dns_name = module.alb.alb_dns_name
  dns_name     = var.dns_name
  zone_id      = var.zone_id
  alb_zone_id  = module.alb.alb_zone_id
}

module "ec2" {
  source                   = "./ec2"
  tags                     = local.project_tags
  key_name                 = var.key_name
  backend_subnet_az_1a_id  = module.vpc.backend_subnet_az_1a_id
  backend_subnet_az_1b_id  = module.vpc.backend_subnet_az_1b_id
  image_id                 = var.image_id
  frontend_subnet_az_1a_id = module.vpc.frontend_subnet_az_1a_id
  instance_type            = var.instance_type
  vpc_id                   = module.vpc.vpc_id
  bastion_host_sg_id       = var.bastion_host_sg_id
}