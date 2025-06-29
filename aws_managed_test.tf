# Ultra simple Image Builder using only AWS managed components
resource "aws_imagebuilder_image_recipe" "aws_managed_only_recipe" {
  name         = "aws-managed-only-recipe"
  description  = "Recipe using only AWS managed components"
  parent_image = var.ami_id
  version      = "1.0.0"

  # Try with a different AWS managed component that's not deprecated
  component {
    component_arn = "arn:aws:imagebuilder:${var.aws_region}:aws:component/simple-boot-test-linux/1.0.0/1"
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
    Name = "AWSManagedOnlyRecipe"
  }
}

# Test build with AWS managed components only
resource "aws_imagebuilder_image" "test_aws_managed_image" {
  image_recipe_arn                 = aws_imagebuilder_image_recipe.aws_managed_only_recipe.arn
  infrastructure_configuration_arn = aws_imagebuilder_infrastructure_configuration.webserver_infra.arn

  image_tests_configuration {
    image_tests_enabled = false # Disable tests for faster build
    timeout_minutes     = 60
  }

  tags = {
    Name = "TestAWSManagedImage"
  }
}
