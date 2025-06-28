# Network Outputs
output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "vpc_cidr_block" {
  description = "VPC CIDR block"
  value       = aws_vpc.main.cidr_block
}

output "private_subnet_1_id" {
  description = "Private subnet 1 ID"
  value       = aws_subnet.private_1.id
}

output "private_subnet_2_id" {
  description = "Private subnet 2 ID"
  value       = aws_subnet.private_2.id
}

output "public_subnet_id" {
  description = "Public subnet ID"
  value       = aws_subnet.public.id
}

output "nat_gateway_id" {
  description = "NAT Gateway ID"
  value       = aws_nat_gateway.main.id
}

output "internet_gateway_id" {
  description = "Internet Gateway ID"
  value       = aws_internet_gateway.main.id
}

# Compute Outputs
output "web_server_1_id" {
  description = "Web server 1 instance ID"
  value       = aws_instance.web_server_1.id
}

output "web_server_1_private_ip" {
  description = "Web server 1 private IP"
  value       = aws_instance.web_server_1.private_ip
}

output "web_server_2_id" {
  description = "Web server 2 instance ID"
  value       = aws_instance.web_server_2.id
}

output "web_server_2_private_ip" {
  description = "Web server 2 private IP"
  value       = aws_instance.web_server_2.private_ip
}

# Key Pair Output
output "key_pair_name" {
  description = "Name of the created key pair"
  value       = aws_key_pair.my_keypair.key_name
}
