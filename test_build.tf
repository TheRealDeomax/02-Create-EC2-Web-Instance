# Manual image build for testing the minimal recipe
resource "aws_imagebuilder_image" "test_minimal_image" {
  image_recipe_arn                 = aws_imagebuilder_image_recipe.minimal_webserver_recipe.arn
  infrastructure_configuration_arn = aws_imagebuilder_infrastructure_configuration.webserver_infra.arn
  distribution_configuration_arn   = aws_imagebuilder_distribution_configuration.webserver_distribution.arn

  image_tests_configuration {
    image_tests_enabled = true
    timeout_minutes     = 90
  }

  tags = {
    Name = "TestMinimalWebServerImage"
  }
}
