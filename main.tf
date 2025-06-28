# Configure the AWS Provider
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region     = var.aws_region
  access_key = var.AWS_ACCESS_KEY_ID
  secret_key = var.AWS_SECRET_ACCESS_KEY
}

# Create AWS Key Pair
resource "aws_key_pair" "my_keypair" {
  key_name   = "my-keypair"
  public_key = file("./my-keypair.pub")
}

# IAM role for EC2 instances to use SSM
resource "aws_iam_role" "ec2_ssm_role" {
  name = "EC2-SSM-Role"

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
    Name = "EC2-SSM-Role"
  }
}

# Attach AWS managed policy for SSM
resource "aws_iam_role_policy_attachment" "ssm_managed_instance_core" {
  role       = aws_iam_role.ec2_ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Attach CloudWatch agent policy
resource "aws_iam_role_policy_attachment" "cloudwatch_agent_server_policy" {
  role       = aws_iam_role.ec2_ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# Create instance profile
resource "aws_iam_instance_profile" "ec2_ssm_profile" {
  name = "EC2-SSM-Profile"
  role = aws_iam_role.ec2_ssm_role.name
}

# CloudWatch Log Groups
resource "aws_cloudwatch_log_group" "webserver1_access_logs" {
  name              = "/aws/ec2/webserver1/httpd/access"
  retention_in_days = 7

  tags = {
    Name = "WebServer1-Access-Logs"
  }
}

resource "aws_cloudwatch_log_group" "webserver1_error_logs" {
  name              = "/aws/ec2/webserver1/httpd/error"
  retention_in_days = 7

  tags = {
    Name = "WebServer1-Error-Logs"
  }
}

resource "aws_cloudwatch_log_group" "webserver2_access_logs" {
  name              = "/aws/ec2/webserver2/httpd/access"
  retention_in_days = 7

  tags = {
    Name = "WebServer2-Access-Logs"
  }
}

resource "aws_cloudwatch_log_group" "webserver2_error_logs" {
  name              = "/aws/ec2/webserver2/httpd/error"
  retention_in_days = 7

  tags = {
    Name = "WebServer2-Error-Logs"
  }
}

# Security group for web servers
resource "aws_security_group" "web_sg" {
  name        = "web-security-group"
  description = "Security group for web servers"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "HTTP from ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  ingress {
    description     = "HTTPS from ALB"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "web-security-group"
  }
}

# EC2 instance in private subnet 1
resource "aws_instance" "web_server_1" {
  ami           = var.ami_id
  instance_type = var.instance_type
  key_name      = var.key_pair_name
  subnet_id     = aws_subnet.private_1.id

  vpc_security_group_ids = [aws_security_group.web_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_ssm_profile.name

  # Configure metadata service
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"  # Enforce IMDSv2
    http_put_response_hop_limit = 1
  }

  user_data = base64encode(<<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd amazon-ssm-agent amazon-cloudwatch-agent
              systemctl start httpd
              systemctl enable httpd
              systemctl start amazon-ssm-agent
              systemctl enable amazon-ssm-agent
              sleep 30  # Wait for services to start
              
              # Configure CloudWatch agent
              cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json << 'CWCONFIG'
{
  "metrics": {
    "namespace": "WebServer/EC2",
    "metrics_collected": {
      "cpu": {
        "measurement": [
          "cpu_usage_idle",
          "cpu_usage_iowait",
          "cpu_usage_user",
          "cpu_usage_system"
        ],
        "metrics_collection_interval": 60,
        "totalcpu": false
      },
      "disk": {
        "measurement": [
          "used_percent"
        ],
        "metrics_collection_interval": 60,
        "resources": [
          "*"
        ]
      },
      "diskio": {
        "measurement": [
          "io_time"
        ],
        "metrics_collection_interval": 60,
        "resources": [
          "*"
        ]
      },
      "mem": {
        "measurement": [
          "mem_used_percent"
        ],
        "metrics_collection_interval": 60
      },
      "netstat": {
        "measurement": [
          "tcp_established",
          "tcp_time_wait"
        ],
        "metrics_collection_interval": 60
      },
      "swap": {
        "measurement": [
          "swap_used_percent"
        ],
        "metrics_collection_interval": 60
      }
    }
  },
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/httpd/access_log",
            "log_group_name": "/aws/ec2/webserver1/httpd/access",
            "log_stream_name": "{instance_id}",
            "timezone": "UTC"
          },
          {
            "file_path": "/var/log/httpd/error_log",
            "log_group_name": "/aws/ec2/webserver1/httpd/error",
            "log_stream_name": "{instance_id}",
            "timezone": "UTC"
          }
        ]
      }
    }
  }
}
CWCONFIG

              # Start CloudWatch agent
              /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
                -a fetch-config -m ec2 -s \
                -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
              
              # Get IMDSv2 token with retries
              for i in {1..5}; do
                TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" \
                  -H "X-aws-ec2-metadata-token-ttl-seconds: 21600" \
                  --connect-timeout 5 --max-time 10 -s)
                if [ ! -z "$TOKEN" ]; then
                  break
                fi
                echo "Retry $i: Failed to get token, waiting..."
                sleep 5
              done
              
              # Get metadata with token
              if [ ! -z "$TOKEN" ]; then
                INSTANCE_ID=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" \
                  http://169.254.169.254/latest/meta-data/instance-id \
                  --connect-timeout 5 --max-time 10 -s)
                AVAILABILITY_ZONE=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" \
                  http://169.254.169.254/latest/meta-data/placement/availability-zone \
                  --connect-timeout 5 --max-time 10 -s)
              else
                INSTANCE_ID="Token acquisition failed"
                AVAILABILITY_ZONE="Token acquisition failed"
              fi
              
              echo "<h1>Web Server 1 - Private Subnet 1</h1>" > /tmp/index.html
              echo "<p>Instance ID: $INSTANCE_ID</p>" >> /tmp/index.html
              echo "<p>Availability Zone: $AVAILABILITY_ZONE</p>" >> /tmp/index.html
              echo "<p>CloudWatch Agent: Enabled</p>" >> /tmp/index.html
              echo "<p>Token: $${TOKEN:0:10}...</p>" >> /tmp/index.html
              mv /tmp/index.html /var/www/html/index.html
              EOF
  )

  tags = {
    Name = "web-server-1"
  }
}

# EC2 instance in private subnet 2
resource "aws_instance" "web_server_2" {
  ami           = var.ami_id
  instance_type = var.instance_type
  key_name      = var.key_pair_name
  subnet_id     = aws_subnet.private_2.id

  vpc_security_group_ids = [aws_security_group.web_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_ssm_profile.name

  # Configure metadata service
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"  # Enforce IMDSv2
    http_put_response_hop_limit = 1
  }

  user_data = base64encode(<<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd amazon-ssm-agent amazon-cloudwatch-agent
              systemctl start httpd
              systemctl enable httpd
              systemctl start amazon-ssm-agent
              systemctl enable amazon-ssm-agent
              sleep 30  # Wait for services to start
              
              # Configure CloudWatch agent
              cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json << 'CWCONFIG'
{
  "metrics": {
    "namespace": "WebServer/EC2",
    "metrics_collected": {
      "cpu": {
        "measurement": [
          "cpu_usage_idle",
          "cpu_usage_iowait",
          "cpu_usage_user",
          "cpu_usage_system"
        ],
        "metrics_collection_interval": 60,
        "totalcpu": false
      },
      "disk": {
        "measurement": [
          "used_percent"
        ],
        "metrics_collection_interval": 60,
        "resources": [
          "*"
        ]
      },
      "diskio": {
        "measurement": [
          "io_time"
        ],
        "metrics_collection_interval": 60,
        "resources": [
          "*"
        ]
      },
      "mem": {
        "measurement": [
          "mem_used_percent"
        ],
        "metrics_collection_interval": 60
      },
      "netstat": {
        "measurement": [
          "tcp_established",
          "tcp_time_wait"
        ],
        "metrics_collection_interval": 60
      },
      "swap": {
        "measurement": [
          "swap_used_percent"
        ],
        "metrics_collection_interval": 60
      }
    }
  },
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/httpd/access_log",
            "log_group_name": "/aws/ec2/webserver2/httpd/access",
            "log_stream_name": "{instance_id}",
            "timezone": "UTC"
          },
          {
            "file_path": "/var/log/httpd/error_log",
            "log_group_name": "/aws/ec2/webserver2/httpd/error",
            "log_stream_name": "{instance_id}",
            "timezone": "UTC"
          }
        ]
      }
    }
  }
}
CWCONFIG

              # Start CloudWatch agent
              /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
                -a fetch-config -m ec2 -s \
                -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
              
              # Get IMDSv2 token with retries
              for i in {1..5}; do
                TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" \
                  -H "X-aws-ec2-metadata-token-ttl-seconds: 21600" \
                  --connect-timeout 5 --max-time 10 -s)
                if [ ! -z "$TOKEN" ]; then
                  break
                fi
                echo "Retry $i: Failed to get token, waiting..."
                sleep 5
              done
              
              # Get metadata with token
              if [ ! -z "$TOKEN" ]; then
                INSTANCE_ID=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" \
                  http://169.254.169.254/latest/meta-data/instance-id \
                  --connect-timeout 5 --max-time 10 -s)
                AVAILABILITY_ZONE=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" \
                  http://169.254.169.254/latest/meta-data/placement/availability-zone \
                  --connect-timeout 5 --max-time 10 -s)
              else
                INSTANCE_ID="Token acquisition failed"
                AVAILABILITY_ZONE="Token acquisition failed"
              fi
              
              echo "<h1>Web Server 2 - Private Subnet 2</h1>" > /tmp/index.html
              echo "<p>Instance ID: $INSTANCE_ID</p>" >> /tmp/index.html
              echo "<p>Availability Zone: $AVAILABILITY_ZONE</p>" >> /tmp/index.html
              echo "<p>CloudWatch Agent: Enabled</p>" >> /tmp/index.html
              echo "<p>Token: $${TOKEN:0:10}...</p>" >> /tmp/index.html
              mv /tmp/index.html /var/www/html/index.html
              EOF
  )

  tags = {
    Name = "web-server-2"
  }
}
