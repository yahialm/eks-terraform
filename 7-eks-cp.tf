# Create the IAM role that EKS will use to manage K8s Cluster
resource "aws_iam_role" "eks" {
  name = "${local.env}-${local.eks_name}-eks-cluster"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "eks.amazonaws.com"
      }
    }
  ]
}
POLICY
}

# Attach the created role to "AmazonEKSClusterPolicy" policy
resource "aws_iam_role_policy_attachment" "eks" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks.name
}


# It is here where the actual provisioning happens of the eks control plane(s)
resource "aws_eks_cluster" "eks" {
  name     = "${local.env}-${local.eks_name}"
  version  = local.eks_version
  role_arn = aws_iam_role.eks.arn

  vpc_config {
    # The Kubernetes API server is not accessible from private subnets in the VPC.
    endpoint_private_access = false

    # The API server is exposed via a publicly accessible endpoint, you only need valid credentials (ideal for dev environments).
    # This help developers to manage workloads on the cluster from their local machines without being in the same subnet where the cluster lives.
    endpoint_public_access  = true

    # For prod environment we generally have "endpoint_private_access = true" and "endpoint_public_access  = false"
    # By using this config, we need a bastion host in order to connect to the production cluster.
    # This increases the security of the production environment by making cp not accessible through public internet.

    # 2 master nodes will be created each on a private subnet
    subnet_ids = [
      aws_subnet.private_zone1.id,
      aws_subnet.private_zone2.id
    ]
  }

  access_config {
    # Specifies that access to the cluster will be authenticated via the Kubernetes API (other methods exists like CONFIG_MAP --> deprecated)
    authentication_mode                         = "API"

    # Grants the user who creates the cluster, which is 'terraform' IAM user in this case, full administrative access to the cluster.
    bootstrap_cluster_creator_admin_permissions = true
  }

  depends_on = [aws_iam_role_policy_attachment.eks]
}