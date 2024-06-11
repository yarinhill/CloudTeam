resource "aws_s3_bucket" "s3_bucket" {
  bucket = var.s3_bucket_name
  acl    = "private"
  tags = {
    Name = var.s3_bucket_name
  }
}

/*
terraform {
  required_version = ">= 0.12.0"
  backend "s3" {
    region  = <your_region>
    profile = "default"
    key     = "terraformstatefile"
    bucket  = <your_bucket_name>
  }
}
*/
