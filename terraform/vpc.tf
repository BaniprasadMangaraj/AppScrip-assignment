module "vpc" {

  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name            = local.name
  cidr            = local.vpc_cidr
  azs             = local.azs
  public_subnets  = local.public_subnets
  private_subnets = local.private_subnets
  intra_subnets   = local.intra_subnets

  enable_nat_gateway = true

  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
  }
   # Ensure public subnets auto-assign public IPs
  map_public_ip_on_launch = true

}
resource "aws_security_group" "eks_node_ports" {
  name        = "${local.name}-node-ports"
  description = "Allow TCP ports 3000-4000 inbound to EKS worker nodes"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "Allow TCP ports 3000-4000"
    from_port   = 3000
    to_port     = 4000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.name}-node-ports"
  }
}
