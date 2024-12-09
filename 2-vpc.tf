resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  # Resources within the VPC like EC2 instances can resolve each other through DNS names 
  enable_dns_support   = true

  # Each EC2 instance will get a DNS name like ip-10-0-1-5.ec2.internal for an EC2 with ip 10.0.1.5
  enable_dns_hostnames = true

  tags = {
    Name = "${local.env}-main"
  }
}