# Absolutely minimal test component - just echo
resource "aws_imagebuilder_component" "echo_test_component" {
  name        = "echo-test"
  description = "Just echo a message"
  platform    = "Linux"
  version     = "1.0.0"

  data = yamlencode({
    schemaVersion = "1.0"
    description   = "Echo test component"
    phases = [
      {
        name = "build"
        steps = [
          {
            name   = "EchoTest"
            action = "ExecuteBash"
            inputs = {
              commands = [
                "echo 'Hello from Image Builder'"
              ]
            }
          }
        ]
      }
    ]
  })

  tags = {
    Name = "EchoTestComponent"
  }
}

# Recipe with just echo
resource "aws_imagebuilder_image_recipe" "echo_test_recipe" {
  name         = "echo-test-recipe"
  description  = "Recipe with just echo command"
  parent_image = data.aws_ami.amazon_linux_2.id
  version      = "1.0.0"

  component {
    component_arn = aws_imagebuilder_component.echo_test_component.arn
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
    Name = "EchoTestRecipe"
  }
}

# Echo test image
resource "aws_imagebuilder_image" "echo_test_image" {
  image_recipe_arn                 = aws_imagebuilder_image_recipe.echo_test_recipe.arn
  infrastructure_configuration_arn = aws_imagebuilder_infrastructure_configuration.webserver_infra.arn

  image_tests_configuration {
    image_tests_enabled = false
    timeout_minutes     = 60
  }

  tags = {
    Name = "EchoTestImage"
  }
}

# Output results
output "echo_test_image_arn" {
  description = "ARN of the echo test image"
  value       = aws_imagebuilder_image.echo_test_image.arn
}
