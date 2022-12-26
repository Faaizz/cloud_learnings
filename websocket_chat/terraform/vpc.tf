module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.18.1"

  name = local.vpc.name
  cidr = local.vpc.cidr

  azs             = local.vpc.azs
  private_subnets = local.vpc.private_subnets.cidrs
  private_subnet_names = local.vpc.private_subnets.names
  public_subnets  = local.vpc.public_subnets.cidrs
  public_subnet_names  = local.vpc.public_subnets.names

  enable_nat_gateway = true
  single_nat_gateway = true
}


resource "aws_security_group" "http" {
  name = "allow HTTP"
  vpc_id = module.vpc.vpc_id

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }
}
