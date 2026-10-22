data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "teste" {
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.private.id
  associate_public_ip_address = false
  vpc_security_group_ids      = [aws_security_group.ec2.id]

  root_block_device {
    volume_type = "gp3"
    volume_size = 20
    encrypted   = true

    tags = {
      Name        = "disco-ec2-infracost-teste"
      Service     = "teste-infracost"
      Environment = "Dev"
    }
  }

  tags = {
    Name        = "ec2-infracost-teste"
    Service     = "teste-infracost"
    Environment = "Dev"
  }
}

output "ec2_private_ip" {
  description = "IP privado da instância"
  value       = aws_instance.teste.private_ip
}
