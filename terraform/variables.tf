variable "aws_region" {
  description = "AWS region where resources will be provisioned"
  default     = "us-east-2"
}

variable "ami_id" {
  description = "AMI ID for the EC2 instance"
  default     = "ami-085f9c64a9b75eed5"
}

variable "instance_type" {
  description = "Instance type for the EC2 instance"
  default     = "t2.medium"
}

variable "my_enviroment" {
  description = "Instance type for the EC2 instance"
  default     = "dev"
}

variable "ami_owner" {
  description = "The AWS account ID of the AMI owner (Canonical for Ubuntu)"
  type        = string
  default     = "099720109477"
}

variable "ami_name_pattern" {
  description = "The AMI name pattern for Ubuntu 24.04"
  type        = string
  default     = "ubuntu/images/hvm-ssd-gp3/*24.04-amd64*"
}