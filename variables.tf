variable "gcp_region" {
  default     = "us-east1"
  type        = string
  description = "GCP region"
}


variable "subnet_europe_west3" {
  default     = "10.156.0.0/20"
  type        = string
  description = "GCP Subnet for 'europe-west3'"
  # "10.156.0.0/20" - Default VPC CIDR for 'europe-west3'
  # For more on VPC CIDR visit the link
  # https://console.cloud.google.com/networking/networks/details/default?{YOUR-PROJECT-NAME-HERE}&pageTab=SUBNETS
  // Change {YOUR-PROJECT-NAME-HERE} within URL
}

variable "gcp_project" {
  type        = string
  default     = "soy-smile-435017-c5"
  description = "GCP project name"
}

variable "aws_region" {
  default     = "eu-west-2"
  type        = string
  description = "AWS region"
}

variable "aws_vpc_cidr" {
  default     = "10.0.0.0/16"
  type        = string
  description = "AWS VPC CIDR"
}

variable "aws_subnet_cidr" {
  default     = "10.0.1.0/24"
  type        = string
  description = "AWS Subnet CIDR"
}