# VPC Endpoints for Image Builder
# These endpoints allow Image Builder instances to communicate with AWS services
# without going through the internet, which can resolve SSM connectivity issues

# SSM VPC Endpoint
resource "aws_vpc_endpoint" "ssm" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.aws_region}.ssm"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.public_1.id, aws_subnet.public_2.id]
  security_group_ids  = [aws_security_group.vpc_endpoint_sg.id]
  
  private_dns_enabled = true

  tags = {
    Name = "SSM VPC Endpoint"
  }
}

# SSM Messages VPC Endpoint
resource "aws_vpc_endpoint" "ssm_messages" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.aws_region}.ssmmessages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.public_1.id, aws_subnet.public_2.id]
  security_group_ids  = [aws_security_group.vpc_endpoint_sg.id]
  
  private_dns_enabled = true

  tags = {
    Name = "SSM Messages VPC Endpoint"
  }
}

# EC2 Messages VPC Endpoint
resource "aws_vpc_endpoint" "ec2_messages" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.aws_region}.ec2messages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.public_1.id, aws_subnet.public_2.id]
  security_group_ids  = [aws_security_group.vpc_endpoint_sg.id]
  
  private_dns_enabled = true

  tags = {
    Name = "EC2 Messages VPC Endpoint"
  }
}

# S3 VPC Endpoint (Gateway type)
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.public.id, aws_route_table.private.id]

  tags = {
    Name = "S3 VPC Endpoint"
  }
}

# CloudWatch Logs VPC Endpoint
resource "aws_vpc_endpoint" "logs" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.aws_region}.logs"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.public_1.id, aws_subnet.public_2.id]
  security_group_ids  = [aws_security_group.vpc_endpoint_sg.id]
  
  private_dns_enabled = true

  tags = {
    Name = "CloudWatch Logs VPC Endpoint"
  }
}

# Security group for VPC endpoints
resource "aws_security_group" "vpc_endpoint_sg" {
  name        = "vpc-endpoint-security-group"
  description = "Security group for VPC endpoints"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTPS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "vpc-endpoint-security-group"
  }
}

# Update Image Builder security group to allow HTTPS for VPC endpoints
resource "aws_security_group_rule" "imagebuilder_vpc_endpoint_access" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = [aws_vpc.main.cidr_block]
  security_group_id = aws_security_group.imagebuilder_sg.id
}

# Outputs for VPC endpoints
output "vpc_endpoints" {
  description = "VPC Endpoints created for Image Builder"
  value = {
    ssm          = aws_vpc_endpoint.ssm.id
    ssm_messages = aws_vpc_endpoint.ssm_messages.id
    ec2_messages = aws_vpc_endpoint.ec2_messages.id
    s3           = aws_vpc_endpoint.s3.id
    logs         = aws_vpc_endpoint.logs.id
  }
}
