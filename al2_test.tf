# Test with Amazon Linux 2 instead of 2023
# Some organizations have better success with AL2 for Image Builder

data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Ultra minimal component for AL2
resource "aws_imagebuilder_component" "al2_minimal_component" {
  name        = "al2-minimal-apache"
  description = "Minimal Apache installation on AL2"
  platform    = "Linux"
  version     = "1.0.0"

  data = yamlencode({
    schemaVersion = "1.0"
    description   = "Minimal Apache installation"
    phases = [
      {
        name = "build"
        steps = [
          {
            name   = "InstallApache"
            action = "ExecuteBash"
            inputs = {
              commands = [
                "yum install -y httpd"
              ]
            }
          }
        ]
      }
    ]
  })

  tags = {
    Name = "AL2MinimalComponent"
  }
}

# AL2 recipe
resource "aws_imagebuilder_image_recipe" "al2_recipe" {
  name         = "al2-minimal-recipe"
  description  = "Minimal recipe using Amazon Linux 2"
  parent_image = data.aws_ami.amazon_linux_2.id
  version      = "1.0.0"

  component {
    component_arn = aws_imagebuilder_component.al2_minimal_component.arn
  }

  block_device_mapping {
    device_name = "/dev/xvda"
    ebs {
      delete_on_termination = true
      volume_size           = 8
      volume_type           = "gp3"
    }
  }

  tags = {
    Name = "AL2MinimalRecipe"
  }
}

# AL2 image build
resource "aws_imagebuilder_image" "al2_image" {
  image_recipe_arn                 = aws_imagebuilder_image_recipe.al2_recipe.arn
  infrastructure_configuration_arn = aws_imagebuilder_infrastructure_configuration.webserver_infra.arn

  image_tests_configuration {
    image_tests_enabled = false
    timeout_minutes     = 60
  }

  tags = {
    Name = "AL2Image"
  }
}

# Outputs for AL2 debugging
output "al2_base_ami_id" {
  description = "The AL2 base AMI ID"
  value       = data.aws_ami.amazon_linux_2.id
}

output "al2_base_ami_name" {
  description = "The AL2 base AMI name"
  value       = data.aws_ami.amazon_linux_2.name
}
