resource "aws_db_subnet_group" "teste" {
  name       = "dbsubnet-infracost-teste"
  subnet_ids = [aws_subnet.private.id, aws_subnet.private_b.id]

  tags = {
    Name        = "dbsubnet-infracost-teste"
    Service     = "teste-infracost"
    Environment = "Dev"
  }
}

resource "aws_security_group" "rds" {
  name        = "sg-rds-infracost-teste"
  description = "PostgreSQL apenas de dentro da VPC"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "PostgreSQL da VPC"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  tags = {
    Name        = "sg-rds-infracost-teste"
    Service     = "teste-infracost"
    Environment = "Dev"
  }
}

resource "aws_db_instance" "teste" {
  identifier     = "rds-infracost-teste"
  engine         = "postgres"
  instance_class = "db.t3.micro"

  allocated_storage = 20
  storage_type      = "gp3"
  storage_encrypted = true

  db_name  = "appdb"
  username = "dbadmin"

  # A senha fica no Secrets Manager, gerenciada pela AWS (não fica no .tf)
  manage_master_user_password = true

  db_subnet_group_name   = aws_db_subnet_group.teste.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = false
  multi_az               = false

  backup_retention_period = 7
  skip_final_snapshot     = true # só para teste; remova em produção

  tags = {
    Name        = "rds-infracost-teste"
    Service     = "teste-infracost"
    Environment = "Dev"
  }
}

output "rds_endpoint" {
  description = "Endpoint do banco"
  value       = aws_db_instance.teste.address
}

output "eks_cluster_name" {
  description = "Nome do cluster EKS"
  value       = aws_eks_cluster.teste.name
}
