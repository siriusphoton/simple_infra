############################################
# 1. VPC – private network
############################################
resource "aws_vpc" "eks" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "eks-vpc"
  }
}

############################################
# 2. Subnets – where nodes live
############################################
resource "aws_subnet" "eks" {
  count                   = 2
  vpc_id                  = aws_vpc.eks.id
  cidr_block              = cidrsubnet("10.0.0.0/16", 8, count.index)
  availability_zone       = ["us-east-1a", "us-east-1b"][count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "eks-subnet-${count.index}"
  }
}

############################################
# 3. Internet Gateway – exit to internet
############################################
resource "aws_internet_gateway" "eks" {
  vpc_id = aws_vpc.eks.id

  tags = {
    Name = "eks-igw"
  }
}

############################################
# 4. Route Table – traffic rules
############################################
resource "aws_route_table" "eks_public" {
  vpc_id = aws_vpc.eks.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.eks.id
  }

  tags = {
    Name = "eks-public-rt"
  }
}

############################################
# 5. Route Table Association – apply rules
############################################
resource "aws_route_table_association" "eks_public" {
  count          = 2
  subnet_id      = aws_subnet.eks[count.index].id
  route_table_id = aws_route_table.eks_public.id
}

############################################
# 6. IAM Role – EKS Cluster
############################################
resource "aws_iam_role" "eks_cluster" {
  name = "eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "eks.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  role       = aws_iam_role.eks_cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

############################################
# 7. EKS Cluster – Kubernetes control plane
############################################
resource "aws_eks_cluster" "this" {
  name     = var.cluster_name
  role_arn = aws_iam_role.eks_cluster.arn

  vpc_config {
    subnet_ids              = aws_subnet.eks[*].id
    endpoint_public_access  = true
    endpoint_private_access = false
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy
  ]
}

############################################
# 8. IAM Role – Worker Nodes
############################################
resource "aws_iam_role" "node" {
  name = "eks-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "node_policies" {
  count = 3
  role  = aws_iam_role.node.name

  policy_arn = [
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  ][count.index]
}

############################################
# 9. Node Group – EC2 machines
############################################
resource "aws_eks_node_group" "this" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "demo-nodes"
  node_role_arn   = aws_iam_role.node.arn
  subnet_ids      = aws_subnet.eks[*].id
  instance_types  = [var.node_instance_type]

  scaling_config {
    desired_size = 3
    max_size     = 5
    min_size     = 2
  }

  depends_on = [
    aws_iam_role_policy_attachment.node_policies
  ]
}
