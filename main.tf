
# Cloud provider and region details
provider "aws" {
  region = "us-east-1"  # Change to your desired region
}

# Create a VPC as per our requirement
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = {
    Name = "main-vpc"
  }
}

# Create public and private subnets as per assignment
resource "aws_subnet" "public" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "public-subnet"
  }
}

resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1a"
  tags = {
    Name = "private-subnet"
  }
}



# Create an Internet Gateway to provide connectivity
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "main-igw"
  }
}

# Create a route table for the public subnet
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "public-route-table"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# Security Group for EC2 instance as per assignment requirement
resource "aws_security_group" "ec2_sg" {
  vpc_id = aws_vpc.main.id
  name   = "ec2_sg"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Adjust to your IP for security
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create EFS file system
resource "aws_efs_file_system" "my_efs" {
  lifecycle {
    prevent_destroy = true
  }
  tags = {
    Name = "my-efs"
  }
}

# Create EFS mount target
resource "aws_efs_mount_target" "my_efs_mount" {
  file_system_id = aws_efs_file_system.my_efs.id
  subnet_id      = aws_subnet.private.id
  security_groups = [aws_security_group.ec2_sg.id]
}

# Create EC2 instance
resource "aws_instance" "my_instance" {
  ami           = "ami-0c55b159cbfafe1f0"  # Change to your desired AMI
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.public.id
  security_groups = [aws_security_group.ec2_sg.name]
  key_name      = "your-key-name"  # Replace with your SSH key name

  tags = {
    Name = "my-instance"
  }
}

# Fetch exisiting Elastic IP
data "aws_eip" "existing" {
  filter {
    name   = "tag:Name"          
    values = ["NetSPI_EIP"]      
  }
}


# Associate the existing Elastic IP with the EC2 instance
resource "aws_eip_association" "example" {
  instance_id   = aws_instance.example.id
  allocation_id  = data.aws_eip.existing.allocation_id
}

# Create an S3 bucket with private access
resource "aws_s3_bucket" "my_private_bucket" {
  bucket = "my-private-bucket-unique-name"  # Replace with a unique bucket name
  acl    = "private"  # Set the ACL to private

  # Block public access settings
  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy      = true
  restrict_public_buckets  = true

  tags = {
    Name        = "MyPrivateBucket"
    Environment = "Development"
  }
}

# Outputs
output "s3_bucket_id" {
  value = aws_s3_bucket.my_private_bucket.id
}

output "efs_volume_id" {
  value = aws_efs_file_system.my_efs.id
}

output "ec2_instance_id" {
  value = aws_instance.my_instance.id
}

output "security_group_id" {
  value = aws_security_group.ec2_sg.id
}

output "subnet_id" {
  value = aws_subnet.private.id
}
