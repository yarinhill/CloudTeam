variable "region" {
  default = "eu-central-1"
}

variable "project_name" {
  default = "cloudteam"
}

variable "s3_bucket_name" {
  default = "python-app-s3-cloudteam110624"
}

variable "sqs_queue_name" {
  default = "python-app-sqs-cloudteam110624"
}

variable "node_instance_type" {
  type    = string
  default = "t3.medium"
}