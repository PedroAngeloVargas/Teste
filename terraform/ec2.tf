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

# Tópico de notificação. Quem se inscreve recebe os alarmes por e-mail.
resource "aws_sns_topic" "alertas" {
  name = "alertas-infracost-teste"

  tags = {
    Name        = "alertas-infracost-teste"
    Service     = "teste-infracost"
    Environment = "Dev"
  }
}

# Troque pelo seu e-mail. A AWS manda um e-mail de confirmação que precisa ser aceito.
resource "aws_sns_topic_subscription" "alertas_email" {
  topic_arn = aws_sns_topic.alertas.arn
  protocol  = "email"
  endpoint  = "seu-email@exemplo.com"
}

# Alarme de CPU da EC2: dispara se a média passar de 80% por 10 minutos.
resource "aws_cloudwatch_metric_alarm" "ec2_cpu" {
  alarm_name          = "ec2-cpu-alta-infracost-teste"
  alarm_description   = "CPU da EC2 acima de 80% por 10 minutos"
  namespace           = "AWS/EC2"
  metric_name         = "CPUUtilization"
  statistic           = "Average"
  period              = 300
  evaluation_periods  = 2
  threshold           = 80
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"

  dimensions = {
    InstanceId = aws_instance.teste.id
  }

  alarm_actions = [aws_sns_topic.alertas.arn]
  ok_actions    = [aws_sns_topic.alertas.arn]

  tags = {
    Name        = "ec2-cpu-alta-infracost-teste"
    Service     = "teste-infracost"
    Environment = "Dev"
  }
}

# Alarme de CPU do RDS: mesma lógica, para o banco.
resource "aws_cloudwatch_metric_alarm" "rds_cpu" {
  alarm_name          = "rds-cpu-alta-infracost-teste"
  alarm_description   = "CPU do RDS acima de 80% por 10 minutos"
  namespace           = "AWS/RDS"
  metric_name         = "CPUUtilization"
  statistic           = "Average"
  period              = 300
  evaluation_periods  = 2
  threshold           = 80
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.teste.identifier
  }

  alarm_actions = [aws_sns_topic.alertas.arn]
  ok_actions    = [aws_sns_topic.alertas.arn]

  tags = {
    Name        = "rds-cpu-alta-infracost-teste"
    Service     = "teste-infracost"
    Environment = "Dev"
  }
}

# Log group para logs de aplicação, com retenção de 14 dias para não acumular custo.
resource "aws_cloudwatch_log_group" "app" {
  name              = "/teste-infracost/app"
  retention_in_days = 14

  tags = {
    Name        = "/teste-infracost/app"
    Service     = "teste-infracost"
    Environment = "Dev"
  }
}
