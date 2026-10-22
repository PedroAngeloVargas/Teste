# EKS precisa de subnets privadas em pelo menos 2 AZs.
# A segunda subnet privada fica aqui para não mexer no network.tf.
resource "aws_subnet" "private_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = {
    Name        = "subnet-privada-b-teste"
    Service     = "teste-infracost"
    Environment = "Dev"
  }
}
//teste
resource "aws_route_table_association" "private_b" {
  subnet_id      = aws_subnet.private_b.id
  route_table_id = aws_route_table.private.id
}

# ---------- IAM: control plane do EKS ----------

resource "aws_iam_role" "eks_cluster" {
  name = "role-eks-cluster-infracost-teste"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "eks.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = {
    Name        = "role-eks-cluster-infracost-teste"
    Service     = "teste-infracost"
    Environment = "Dev"
  }
}

resource "aws_iam_role_policy_attachment" "eks_cluster" {
  role       = aws_iam_role.eks_cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# ---------- Cluster EKS ----------

resource "aws_eks_cluster" "teste" {
  name     = "eks-infracost-teste"
  role_arn = aws_iam_role.eks_cluster.arn

  vpc_config {
    subnet_ids = [aws_subnet.private.id, aws_subnet.private_b.id]
  }

  depends_on = [aws_iam_role_policy_attachment.eks_cluster]

  tags = {
    Name        = "eks-infracost-teste"
    Service     = "teste-infracost"
    Environment = "Dev"
  }
}

# ---------- IAM: nodes ----------

resource "aws_iam_role" "eks_nodes" {
  name = "role-eks-nodes-infracost-teste"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = {
    Name        = "role-eks-nodes-infracost-teste"
    Service     = "teste-infracost"
    Environment = "Dev"
  }
}

resource "aws_iam_role_policy_attachment" "eks_nodes" {
  for_each = toset([
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
  ])

  role       = aws_iam_role.eks_nodes.name
  policy_arn = each.value
}

# ---------- Node group (EC2 gerenciadas pelo EKS) ----------

resource "aws_eks_node_group" "teste" {
  cluster_name    = aws_eks_cluster.teste.name
  node_group_name = "ng-infracost-teste"
  node_role_arn   = aws_iam_role.eks_nodes.arn
  subnet_ids      = [aws_subnet.private.id, aws_subnet.private_b.id]
  instance_types  = ["t3.medium"]

  scaling_config {
    desired_size = 2
    min_size     = 1
    max_size     = 3
  }

  depends_on = [aws_iam_role_policy_attachment.eks_nodes]

  tags = {
    Name        = "ng-infracost-teste"
    Service     = "teste-infracost"
    Environment = "Dev"
  }
}
