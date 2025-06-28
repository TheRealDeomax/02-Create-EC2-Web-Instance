# AWS Terraform EC2 Web Instance Project

This Terraform project creates an AWS infrastructure with:
- A VPC with CIDR block 10.0.0.0/16
- Two private subnets (10.0.0.0/24 and 10.0.1.0/24)
- One public subnet for NAT Gateway
- Two EC2 web servers in separate private subnets
- NAT Gateway for internet access from private subnets
- Security groups with appropriate rules

## Architecture Overview

```
Internet Gateway
       |
   Public Subnet (10.0.2.0/24)
       |
   NAT Gateway
       |
Private Subnets:
├── Private Subnet 1 (10.0.0.0/24) - Web Server 1
└── Private Subnet 2 (10.0.1.0/24) - Web Server 2
```

## Prerequisites

1. **AWS CLI configured** with appropriate credentials
2. **Terraform installed** (version 1.0 or later)
3. **AWS Key Pair** (optional, for SSH access to EC2 instances)

## Quick Start

1. **Clone or navigate to this directory**

2. **Copy the example variables file:**
   ```powershell
   Copy-Item terraform.tfvars.example terraform.tfvars
   ```

3. **Edit terraform.tfvars** (optional):
   ```powershell
   notepad terraform.tfvars
   ```
   
   Customize the following variables:
   - `aws_region`: AWS region (default: us-east-1)
   - `instance_type`: EC2 instance type (default: t2.micro)
   - `key_pair_name`: Name of AWS key pair for SSH access (optional)

4. **Initialize Terraform:**
   ```powershell
   terraform init
   ```

5. **Plan the deployment:**
   ```powershell
   terraform plan
   ```

6. **Apply the configuration:**
   ```powershell
   terraform apply
   ```
   Type `yes` when prompted to confirm.

## File Structure

The project is organized into separate files for better maintainability:

```
02 Create EC2 Web Instance/
├── main.tf                    # Provider configuration, key pair, security groups, and EC2 instances
├── network.tf                 # VPC, subnets, gateways, and routing resources
├── variables.tf               # Variable definitions
├── outputs.tf                 # Output values
├── terraform.tfvars.example   # Example variables file
├── README.md                  # Comprehensive documentation
└── .gitignore                # Git ignore file
```

### File Descriptions

- **`main.tf`**: Contains the AWS provider configuration, key pair resource, security groups, and EC2 instances
- **`network.tf`**: Contains all networking resources including VPC, subnets, Internet Gateway, NAT Gateway, and routing
- **`variables.tf`**: Defines all input variables with descriptions and default values
- **`outputs.tf`**: Defines output values that will be displayed after successful deployment
- **`terraform.tfvars.example`**: Example configuration file showing how to customize variables

## What Gets Created

### VPC and Networking
- **VPC**: 10.0.0.0/16 with DNS hostnames and DNS support enabled
- **Private Subnet 1**: 10.0.0.0/24 in first AZ
- **Private Subnet 2**: 10.0.1.0/24 in second AZ
- **Public Subnet**: 10.0.2.0/24 for NAT Gateway
- **Internet Gateway**: For public internet access
- **NAT Gateway**: Allows private subnets to access internet
- **Route Tables**: Proper routing for public and private subnets

### Security
- **Security Group**: Allows HTTP (80), HTTPS (443), and SSH (22) within VPC

### Compute
- **EC2 Instance 1**: Amazon Linux 2 in private subnet 1 with Apache web server
- **EC2 Instance 2**: Amazon Linux 2 in private subnet 2 with Apache web server

## Accessing the Web Servers

Since the EC2 instances are in private subnets, they cannot be accessed directly from the internet. To access them:

1. **Create a bastion host** in the public subnet, or
2. **Use AWS Systems Manager Session Manager** for secure access
3. **Set up a VPN connection** to the VPC

Each web server runs Apache and serves a simple HTML page showing:
- Server identification
- Instance ID
- Availability Zone

## Outputs

After successful deployment, Terraform will display:
- VPC ID and CIDR block
- Subnet IDs
- EC2 instance IDs and private IP addresses
- NAT Gateway and Internet Gateway IDs

## Cost Considerations

This infrastructure will incur AWS charges:
- **EC2 instances**: ~$14/month for 2 t2.micro instances (if not in free tier)
- **NAT Gateway**: ~$45/month + data processing charges
- **Elastic IP**: Free when attached to running instance

## Cleanup

To destroy all resources:
```powershell
terraform destroy
```
Type `yes` when prompted to confirm.

## Customization

### Change Instance Type
Edit `terraform.tfvars`:
```
instance_type = "t3.small"
```

### Add SSH Access
1. Create an AWS Key Pair in the AWS Console
2. Edit `terraform.tfvars`:
```
key_pair_name = "your-key-pair-name"
```

### Change Region
Edit `terraform.tfvars`:
```
aws_region = "us-west-2"
```

## Troubleshooting

### Common Issues

1. **"No default VPC"**: This is normal, we're creating our own VPC
2. **"Insufficient capacity"**: Try a different AZ or instance type
3. **"Key pair not found"**: Ensure the key pair exists in the specified region

### Validation Commands

```powershell
# Check Terraform syntax
terraform validate

# Format Terraform files
terraform fmt

# Show current state
terraform show

# List resources
terraform state list
```

## Security Notes

- EC2 instances are in private subnets (no direct internet access)
- Security group restricts access to VPC CIDR only
- Consider enabling VPC Flow Logs for network monitoring
- Use IAM roles instead of hardcoded credentials

## Next Steps

Consider adding:
- Auto Scaling Groups
- RDS database in private subnets
- CloudWatch monitoring
- AWS Systems Manager for instance management
