# AWS Config

variable "aws_access_key" {
  default = "aws API key"
}

variable "aws_secret_key" {
  default = "aws API secret"
}

variable "cc_broker_url" {
  default = "confluent cloud broker url with port"
}

variable "cc_broker_key" {
  default = "confluent cloud broker API key"
}

variable "cc_broker_secret" {
  default = "confluent cloud broker API secret"
}

variable "cc_schema_url" {
  default = "confluent cloud schema registry URL"
}

variable "cc_schema_key" {
  default = "confluent cloud schema registry API key"
}

variable "cc_schema_secret" {
  default = "confluent cloud schema registry API secret"
}

variable "aws_region" {
  default = "eu-central-1"
}

variable "ssh_key_name" {
  default = "youre store ssh key in aws"
}

variable "instance_type_resource" {
  default = "t2.micro"
  # t2.mirco is cheaper but only 1GB RAM
}

variable "instance_count" {
    default = "1"
  }
