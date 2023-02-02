variable "s3_bucket" {
  default = "s2quest"
}

variable "lambda_function" {
  default = "lambda_handler"
}

variable "role_name" {
  default = "s3quest"
}

variable "AWS_ACCESS_KEY_ID" {}

variable "AWS_SECRET_ACCESS_KEY" {}