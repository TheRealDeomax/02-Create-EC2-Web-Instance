# Minimal Image Builder Component - Focused on reliability
resource "aws_imagebuilder_component" "minimal_webserver_component" {
  name        = "minimal-webserver-setup"
  description = "Minimal web server setup for testing"
  platform    = "Linux"
  version     = "1.0.1"

  data = yamlencode({
    schemaVersion = "1.0"
    description   = "Ultra simple Apache installation"
    phases = [
      {
        name = "build"
        steps = [
          {
            name   = "InstallApache"
            action = "ExecuteBash"
            inputs = {
              commands = [
                "yum update -y",
                "yum install -y httpd",
                "systemctl enable httpd"
              ]
            }
          },
          {
            name   = "CreateWebPage"
            action = "ExecuteBash"
            inputs = {
              commands = [
                "echo '<h1>Success!</h1>' > /var/www/html/index.html"
              ]
            }
          }
        ]
      }
    ]
  })

  tags = {
    Name = "MinimalWebServerComponent"
  }
}

# Minimal Image Recipe using the reliable component
resource "aws_imagebuilder_image_recipe" "minimal_webserver_recipe" {
  name         = "minimal-webserver-recipe"
  description  = "Minimal recipe for testing Image Builder"
  parent_image = var.ami_id
  version      = "1.0.0"

  # Only use our minimal custom component
  component {
    component_arn = aws_imagebuilder_component.minimal_webserver_component.arn
  }

  block_device_mapping {
    device_name = "/dev/xvda"
    ebs {
      delete_on_termination = true
      volume_size           = 8
      volume_type           = "gp3"
      encrypted             = true
    }
  }

  tags = {
    Name        = "MinimalWebServerRecipe"
    Environment = "Test"
  }
}
