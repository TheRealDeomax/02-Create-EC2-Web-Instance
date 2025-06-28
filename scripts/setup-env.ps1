$env:TF_VAR_AWS_ACCESS_KEY_ID = "ACCESSKEYID"
$env:TF_VAR_AWS_SECRET_ACCESS_KEY = "SECRETACCESSKEY"

$env:AWS_ACCESS_KEY_ID = "ACCESSKEYID"
$env:AWS_SECRET_ACCESS_KEY = "SECRETACCESSKEY"
$env:AWS_DEFAULT_REGION = "us-east-1" # Replace with your desired region

# ssh-keygen -t rsa -b 2048 -f ".\my-ec2key"