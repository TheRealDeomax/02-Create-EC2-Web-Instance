variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "key_pair_name" {
  description = "Name of the AWS key pair to use for EC2 instances"
  type        = string
  default     = "my-keypair"
}

variable "ami_id" {
  description = "AMI ID for EC2 instances"
  type        = string
  default     = "ami-05ffe3c48a9991133" # Update this to the latest AMI ID for your region
}

variable "AWS_ACCESS_KEY_ID" {
  description = "AWS access key"
}

variable "AWS_SECRET_ACCESS_KEY" {
  description = "AWS secret key"
}