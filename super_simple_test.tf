# Super simple Image Builder component for debugging
resource "aws_imagebuilder_component" "super_simple_component" {
  name        = "super-simple-apache"
  description = "Super simple Apache installation"
  platform    = "Linux"
  version     = "1.0.0"

  data = yamlencode({
    schemaVersion = "1.0"
    description   = "Just install Apache"
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
    Name = "SuperSimpleComponent"
  }
}

# Super simple recipe
resource "aws_imagebuilder_image_recipe" "super_simple_recipe" {
  name         = "super-simple-recipe"
  description  = "Super simple recipe for debugging"
  parent_image = var.ami_id
  version      = "1.0.0"

  component {
    component_arn = aws_imagebuilder_component.super_simple_component.arn
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
    Name = "SuperSimpleRecipe"
  }
}

# Test build with super simple component
resource "aws_imagebuilder_image" "test_super_simple_image" {
  image_recipe_arn                 = aws_imagebuilder_image_recipe.super_simple_recipe.arn
  infrastructure_configuration_arn = aws_imagebuilder_infrastructure_configuration.webserver_infra.arn

  image_tests_configuration {
    image_tests_enabled = false
    timeout_minutes     = 60
  }

  tags = {
    Name = "TestSuperSimpleImage"
  }
}
