# locals {
#   instances = csvdecode(file("../srd22_accessKeys.csv"))
# }

variable "AWS_ACCESS_KEY_ID" {}

variable "AWS_SECRET_ACCESS_KEY" {}

provider "aws" {
  # access_key=tolist(local.instances)[0]["Access key ID"]
  # secret_key=tolist(local.instances)[0]["Secret access key"]
  access_key="${var.AWS_ACCESS_KEY_ID}"
  secret_key="${var.AWS_SECRET_ACCESS_KEY}"
  region = "us-east-1"
}


resource "aws_iam_user" "user" {
  name = "rearc-user"
}

resource "aws_iam_access_key" "user_key" {
  user    = "${aws_iam_user.user.name}"
  depends_on = [aws_iam_user.user]
}


resource "aws_iam_user_policy_attachment" "attach-user" {
  user       = "${aws_iam_user.user.name}"
  for_each = toset([
    "arn:aws:iam::aws:policy/IAMFullAccess", 
    "arn:aws:iam::aws:policy/AmazonS3FullAccess", 
    "arn:aws:iam::aws:policy/AWSLambda_FullAccess",
    "arn:aws:iam::aws:policy/AmazonSQSFullAccess",
    "arn:aws:iam::aws:policy/AmazonEventBridgeFullAccess",
    "arn:aws:iam::aws:policy/AmazonEventBridgeSchemasFullAccess",
    "arn:aws:iam::aws:policy/AmazonEventBridgeSchedulerFullAccess",
    "arn:aws:iam::aws:policy/CloudWatchFullAccess"
  ])
  policy_arn = each.value   
}

resource "local_file" "private_key" {
    content  = "Access key ID,Secret access key\n${aws_iam_access_key.user_key.id},${aws_iam_access_key.user_key.secret}"
    filename = "private_key.csv"
}