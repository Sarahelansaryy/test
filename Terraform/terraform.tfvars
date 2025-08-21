region                     = "eu-central-1"
availability_zones = [ "eu-central-1a", "eu-central-1b" ]
private_subnet_cidrs = [ "10.0.1.0/24", "10.0.2.0/24" ]
public_subnet_cidrs  = [ "10.0.101.0/24", "10.0.102.0/24" ]
vpc_cidr = "10.0.0.0/16"
cluster_name = "sarah-eks-cluster-45678"
cluster_version = "1.33"


node_groups = {
  default = {
    capacity_type  = "ON_DEMAND"
    instance_types = ["t3.small"]
    scaling_config = {
      desired_size = 1
      max_size     = 2
      min_size     = 1
    
    }
  }
}

