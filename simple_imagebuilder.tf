# Simple Image Builder Recipe (Alternative)
# This version uses only unique components to avoid the duplicate component error

# Basic image recipe with unique components only
resource "aws_imagebuilder_image_recipe" "simple_webserver_recipe" {
  name         = "simple-webserver-recipe"
  description  = "Simple recipe for building web server AMIs (no duplicates)"
  parent_image = var.ami_id
  version      = "1.0.1"

  # Only use custom component to avoid deprecated AWS components
  component {
    component_arn = aws_imagebuilder_component.webserver_component.arn
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
    Name        = "SimpleWebServerRecipe"
    Environment = "Test"
  }
}
