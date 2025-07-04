module "eks" {

  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0" //Uses the official AWS EKS Terraform module version

  cluster_name                   = local.name //Sets the cluster name from a local variable
  cluster_endpoint_public_access = true //Enables public access to the Kubernetes API endpoint

//Installs essential Kubernetes addons:
  cluster_addons = {
    coredns = {           //CoreDNS for DNS services
      most_recent = true
    }
    kube-proxy = {        //kube-proxy for network proxying
      most_recent = true
    }
    vpc-cni = {           //VPC CNI (Container Network Interface) for networking
      most_recent = true
    }
  }

//Network Configuration
  vpc_id                   = module.vpc.vpc_id  //Uses VPC and subnets created by another module
  subnet_ids               = module.vpc.public_subnets //Places worker nodes in public subnets
  control_plane_subnet_ids = module.vpc.intra_subnets //Places control plane in intra subnets (private subnets without NAT)

  # EKS Managed Node Group(s)

  eks_managed_node_group_defaults = {

    instance_types = ["t2.large"]

    attach_cluster_primary_security_group = true  //Attaches the primary cluster security group to nodes

  }

//Node Group Configuration
  eks_managed_node_groups = {

    tws-demo-ng = {          //2-3 nodes (starting with 2)
      min_size     = 2
      max_size     = 3
      desired_size = 2

      instance_types = ["t2.large"]
      capacity_type  = "SPOT"

      disk_size = 35 
      use_custom_launch_template = false  # Important to apply disk size!
      additional_security_group_ids = [aws_security_group.eks_node_ports.id]

      
      tags = {
        Name = "tws-demo-ng"
        Environment = "dev"
        ExtraTag = "e-commerce-app"
      }
    }
  }


  tags = local.tags
}

//Data Source for EKS Nodes
data "aws_instances" "eks_nodes" {   //Queries AWS for all running EC2 instances that belong to this EKS cluster
  instance_tags = {
    "eks:cluster-name" = module.eks.cluster_name
   
  }

  filter {
    name   = "instance-state-name"
    values = ["running"]
  }

  depends_on = [module.eks]
}
 