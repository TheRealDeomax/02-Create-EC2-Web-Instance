# Debug Image Builder with latest Amazon Linux 2023
# This will use a data source to get the latest Amazon Linux 2023 AMI
# which should have proper SSM agent support

data "aws_ami" "amazon_linux_2023" {
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

# Minimal component for debugging with Amazon Linux 2023
resource "aws_imagebuilder_component" "debug_component" {
  name        = "debug-apache-al2023"
  description = "Debug Apache installation on AL2023"
  platform    = "Linux"
  version     = "1.0.0"

  data = yamlencode({
    schemaVersion = "1.0"
    description   = "Debug Apache installation"
    phases = [
      {
        name = "build"
        steps = [
          {
            name   = "UpdateSystem"
            action = "ExecuteBash"
            inputs = {
              commands = [
                "#!/bin/bash",
                "set -e",
                "echo 'Starting system update...'",
                "dnf update -y",
                "echo 'System update completed'"
              ]
            }
          },
          {
            name   = "InstallApache"
            action = "ExecuteBash"
            inputs = {
              commands = [
                "#!/bin/bash",
                "set -e",
                "echo 'Installing Apache...'",
                "dnf install -y httpd",
                "systemctl enable httpd",
                "echo 'Apache installation completed'"
              ]
            }
          },
          {
            name   = "CreateTestContent"
            action = "ExecuteBash"
            inputs = {
              commands = [
                "#!/bin/bash",
                "set -e",
                "echo 'Creating test content...'",
                "echo '<h1>Debug Image Builder Success!</h1>' > /var/www/html/index.html",
                "chown apache:apache /var/www/html/index.html",
                "echo 'Test content created'"
              ]
            }
          }
        ]
      }
    ]
  })

  tags = {
    Name = "DebugComponent"
  }
}

# Debug recipe using Amazon Linux 2023
resource "aws_imagebuilder_image_recipe" "debug_recipe" {
  name         = "debug-recipe-al2023"
  description  = "Debug recipe using Amazon Linux 2023"
  parent_image = data.aws_ami.amazon_linux_2023.id
  version      = "1.0.0"

  component {
    component_arn = aws_imagebuilder_component.debug_component.arn
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
    Name = "DebugRecipeAL2023"
  }
}

# Debug image build
resource "aws_imagebuilder_image" "debug_image" {
  image_recipe_arn                 = aws_imagebuilder_image_recipe.debug_recipe.arn
  infrastructure_configuration_arn = aws_imagebuilder_infrastructure_configuration.webserver_infra.arn

  image_tests_configuration {
    image_tests_enabled = false
    timeout_minutes     = 60
  }

  tags = {
    Name = "DebugImage"
  }
}

# Output the AMI ID we're using for debugging
output "debug_base_ami_id" {
  description = "The base AMI ID used for debugging"
  value       = data.aws_ami.amazon_linux_2023.id
}

output "debug_base_ami_name" {
  description = "The base AMI name used for debugging"
  value       = data.aws_ami.amazon_linux_2023.name
}
