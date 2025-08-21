resource "aws_eks_cluster" "main" {
  name          = var.cluster_name
  version       = var.cluster_version
  role_arn      = aws_iam_role.cluster.arn

  access_config {
    authentication_mode                           = "API_AND_CONFIG_MAP"
    bootstrap_cluster_creator_admin_permissions   = true
  }

  vpc_config {
    subnet_ids = var.subnet_ids
  }

  depends_on = [
    aws_iam_role_policy_attachment.cluster_policy
  ]
}

resource "aws_iam_role" "cluster" {
  name = "${var.cluster_name}-cluster-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "sts:AssumeRole",
          "sts:TagSession"
        ]
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.cluster.name
}

# data "aws_eks_cluster" "main" {
#   name = var.cluster_name
# }

# data "aws_eks_cluster_auth" "main" {
#   name = var.cluster_name
# }

# resource "aws_iam_openid_connect_provider" "eks" {
#   client_id_list  = ["sts.amazonaws.com"]
#   thumbprint_list = ["9e99a48a9960b14926bb7f3b02e22da0afd0d3f3"] # AWS recommended root CA
#   url             = data.aws_eks_cluster.main.identity[0].oidc[0].issuer
# }

# resource "aws_iam_role" "image_processor_sa" {
#   name = "${var.cluster_name}-image-processor-sa"

#   assume_role_policy = jsonencode({
#     Version = "2012-10-17",
#     Statement = [{
#       Effect = "Allow",
#       Principal = {
#         Federated = aws_iam_openid_connect_provider.eks.arn
#       },
#       Action = "sts:AssumeRoleWithWebIdentity",
#       Condition = {
#         StringEquals = {
#           "${replace(data.aws_eks_cluster.main.identity[0].oidc[0].issuer, "https://", "")}:sub" = "system:serviceaccount:default:image-processor-sa"
#         }
#       }
#     }]
#   })
# }


resource "aws_iam_role" "node" {
  name = "${var.cluster_name}-node-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "node_policy" {
  for_each = toset([
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPullOnly",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  ])

  policy_arn = each.value
  role       = aws_iam_role.node.name
}


resource "aws_eks_node_group" "main" {
  for_each          = var.node_groups
  cluster_name      = aws_eks_cluster.main.name
  node_group_name   = each.key
  node_role_arn     = aws_iam_role.node.arn
  subnet_ids        =  var.subnet_ids
  instance_types = each.value.instance_types   
  capacity_type  = each.value.capacity_type     
  

  scaling_config {
    desired_size = each.value.scaling_config.desired_size
    max_size     = each.value.scaling_config.max_size
    min_size     = each.value.scaling_config.min_size
  }

  update_config {
    max_unavailable = 1
  }

  depends_on = [
    aws_iam_role_policy_attachment.node_policy
  ]
}
resource "aws_iam_role_policy_attachment" "node_s3_sqs" {
  policy_arn = aws_iam_policy.node_s3_sqs.arn
  role       = aws_iam_role.node.name
}
# resource "aws_iam_role_policy_attachment" "image_processor_sa_policy" {
#   role       = aws_iam_role.image_processor_sa.name
#   policy_arn = aws_iam_policy.node_s3_sqs.arn
# }

resource "aws_iam_policy" "node_s3_sqs" {
  name        = "${var.cluster_name}-node-s3-sqs"
  description = "Allow S3 read/write and SQS consume for image processor"
  policy      = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:PutObject"]
        Resource = "arn:aws:s3:::my-raw-images-bucket-0123/*"
      },
      {
        Effect   = "Allow"
        Action   = ["sqs:ReceiveMessage", "sqs:DeleteMessage", "sqs:GetQueueAttributes"]
        Resource = "arn:aws:sqs:eu-central-1:468587035708:raw-images-queue"
      }
    ]
  })
}
