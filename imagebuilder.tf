# IAM role for EC2 Image Builder
resource "aws_iam_role" "imagebuilder_instance_role" {
  name = "ImageBuilderInstanceRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "ImageBuilderInstanceRole"
  }
}

# Attach required policies for Image Builder
resource "aws_iam_role_policy_attachment" "imagebuilder_instance_core" {
  role       = aws_iam_role.imagebuilder_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/EC2InstanceProfileForImageBuilder"
}

resource "aws_iam_role_policy_attachment" "imagebuilder_ssm_core" {
  role       = aws_iam_role.imagebuilder_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Additional SSM permissions that might be needed
resource "aws_iam_role_policy_attachment" "imagebuilder_ssm_full" {
  role       = aws_iam_role.imagebuilder_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMFullAccess"
}

# CloudWatch agent permissions
resource "aws_iam_role_policy_attachment" "imagebuilder_cloudwatch" {
  role       = aws_iam_role.imagebuilder_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# Additional custom policy for specific SSM operations
resource "aws_iam_role_policy" "imagebuilder_custom_policy" {
  name = "ImageBuilderCustomPolicy"
  role = aws_iam_role.imagebuilder_instance_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:SendCommand",
          "ssm:ListCommands",
          "ssm:ListCommandInvocations",
          "ssm:DescribeCommandInvocations",
          "ssm:GetCommandInvocation",
          "ssm:UpdateInstanceInformation",
          "ssm:CreateAssociation",
          "ssm:DescribeAssociations",
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Resource = "*"
      }
    ]
  })
}

# Instance profile for Image Builder
resource "aws_iam_instance_profile" "imagebuilder_instance_profile" {
  name = "ImageBuilderInstanceProfile"
  role = aws_iam_role.imagebuilder_instance_role.name
}

# Custom component for web server setup
resource "aws_imagebuilder_component" "webserver_component" {
  name        = "webserver-setup"
  description = "Install and configure Apache web server with CloudWatch agent"
  platform    = "Linux"
  version     = "1.0.1"

  data = yamlencode({
    schemaVersion = "1.0"
    description   = "Install Apache, SSM agent, CloudWatch agent, and update system"
    phases = [
      {
        name = "build"
        steps = [
          {
            name   = "UpdateOS"
            action = "ExecuteBash"
            inputs = {
              commands = [
                "set -e",
                "echo 'Starting OS update...'",
                "yum update -y",
                "echo 'OS update completed'"
              ]
            }
          },
          {
            name   = "InstallPackages"
            action = "ExecuteBash"
            inputs = {
              commands = [
                "set -e",
                "echo 'Installing packages...'",
                "yum install -y httpd",
                "yum install -y amazon-ssm-agent",
                "yum install -y amazon-cloudwatch-agent",
                "yum install -y wget curl unzip",
                "echo 'Package installation completed'"
              ]
            }
          },
          {
            name   = "ConfigureServices"
            action = "ExecuteBash"
            inputs = {
              commands = [
                "set -e",
                "echo 'Configuring services...'",
                "systemctl enable httpd",
                "systemctl enable amazon-ssm-agent",
                "echo 'Service configuration completed'"
              ]
            }
          },
          {
            name   = "CreateCloudWatchConfig"
            action = "ExecuteBash"
            inputs = {
              commands = [
                "set -e",
                "echo 'Creating CloudWatch configuration...'",
                "mkdir -p /opt/aws/amazon-cloudwatch-agent/etc",
                "cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json << 'EOF'",
                "{",
                "  \"metrics\": {",
                "    \"namespace\": \"WebServer/EC2\",",
                "    \"metrics_collected\": {",
                "      \"cpu\": {",
                "        \"measurement\": [\"cpu_usage_idle\", \"cpu_usage_user\", \"cpu_usage_system\"],",
                "        \"metrics_collection_interval\": 60,",
                "        \"totalcpu\": false",
                "      },",
                "      \"disk\": {",
                "        \"measurement\": [\"used_percent\"],",
                "        \"metrics_collection_interval\": 60,",
                "        \"resources\": [\"*\"]",
                "      },",
                "      \"mem\": {",
                "        \"measurement\": [\"mem_used_percent\"],",
                "        \"metrics_collection_interval\": 60",
                "      }",
                "    }",
                "  }",
                "}",
                "EOF",
                "echo 'CloudWatch configuration created'"
              ]
            }
          },
          {
            name   = "CreateBasicWebPage"
            action = "ExecuteBash"
            inputs = {
              commands = [
                "set -e",
                "echo 'Creating basic web page...'",
                "cat > /var/www/html/index.html << 'EOF'",
                "<h1>Image Builder Web Server</h1>",
                "<p>This server was built using AWS EC2 Image Builder</p>",
                "<p>Build Date: $(date)</p>",
                "EOF",
                "chown apache:apache /var/www/html/index.html",
                "echo 'Basic web page created'"
              ]
            }
          },
          {
            name   = "CleanupAndValidate"
            action = "ExecuteBash"
            inputs = {
              commands = [
                "set -e",
                "echo 'Running cleanup and validation...'",
                "yum clean all",
                "rm -rf /tmp/*",
                "echo 'Validating installations...'",
                "httpd -v || echo 'Apache not properly installed'",
                "ls -la /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json || echo 'CloudWatch config missing'",
                "echo 'Build completed successfully'"
              ]
            }
          }
        ]
      }
    ]
  })

  tags = {
    Name = "WebServerComponent"
  }
}

# Infrastructure configuration
resource "aws_imagebuilder_infrastructure_configuration" "webserver_infra" {
  name                          = "webserver-infrastructure"
  description                   = "Infrastructure configuration for web server image"
  instance_profile_name         = aws_iam_instance_profile.imagebuilder_instance_profile.name
  instance_types                = ["t2.micro", "t3.micro"]
  subnet_id                     = aws_subnet.public_1.id
  security_group_ids            = [aws_security_group.imagebuilder_sg.id]
  terminate_instance_on_failure = true

  logging {
    s3_logs {
      s3_bucket_name = aws_s3_bucket.imagebuilder_logs.bucket
      s3_key_prefix  = "imagebuilder-logs"
    }
  }

  tags = {
    Name = "WebServerInfrastructure"
  }
}

# Security group for Image Builder instances
resource "aws_security_group" "imagebuilder_sg" {
  name        = "imagebuilder-security-group"
  description = "Security group for Image Builder instances"
  vpc_id      = aws_vpc.main.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "imagebuilder-security-group"
  }
}

# S3 bucket for Image Builder logs
resource "aws_s3_bucket" "imagebuilder_logs" {
  bucket        = "imagebuilder-logs-${random_id.bucket_suffix.hex}"
  force_destroy = true

  tags = {
    Name = "ImageBuilderLogs"
  }
}

resource "random_id" "bucket_suffix" {
  byte_length = 8
}

# S3 bucket versioning
resource "aws_s3_bucket_versioning" "imagebuilder_logs_versioning" {
  bucket = aws_s3_bucket.imagebuilder_logs.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Image recipe
resource "aws_imagebuilder_image_recipe" "webserver_recipe" {
  name         = "webserver-recipe"
  description  = "Recipe for building web server AMIs"
  parent_image = var.ami_id
  version      = "1.0.0"

  # Using only our custom component to avoid deprecated AWS components
  # The custom component includes system updates and CloudWatch agent setup
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
    Name = "WebServerRecipe"
  }
}

# Distribution configuration
resource "aws_imagebuilder_distribution_configuration" "webserver_distribution" {
  name        = "webserver-distribution"
  description = "Distribution configuration for web server AMIs"

  distribution {
    ami_distribution_configuration {
      name        = "webserver-ami-{{ imagebuilder:buildDate }}"
      description = "Web server AMI built on {{ imagebuilder:buildDate }}"
      ami_tags = {
        Name        = "WebServer-AMI"
        BuildDate   = "{{ imagebuilder:buildDate }}"
        SourceAMI   = var.ami_id
        Environment = "Production"
      }
    }
    region = var.aws_region
  }

  tags = {
    Name = "WebServerDistribution"
  }
}

# Image pipeline
resource "aws_imagebuilder_image_pipeline" "webserver_pipeline" {
  name                             = "webserver-pipeline"
  description                      = "Pipeline for building web server AMIs"
  image_recipe_arn                 = aws_imagebuilder_image_recipe.webserver_recipe.arn
  infrastructure_configuration_arn = aws_imagebuilder_infrastructure_configuration.webserver_infra.arn
  distribution_configuration_arn   = aws_imagebuilder_distribution_configuration.webserver_distribution.arn
  status                           = "ENABLED"

  # Schedule to run weekly
  schedule {
    schedule_expression                = "cron(0 2 ? * SUN *)"
    pipeline_execution_start_condition = "EXPRESSION_MATCH_AND_DEPENDENCY_UPDATES_AVAILABLE"
  }

  image_tests_configuration {
    image_tests_enabled = true
    timeout_minutes     = 90
  }

  tags = {
    Name = "WebServerPipeline"
  }
}
