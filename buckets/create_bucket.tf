locals {
  instances = csvdecode(file("../user/private_key.csv"))
}

provider "aws" {
  access_key=tolist(local.instances)[0]["Access key ID"]
  secret_key=tolist(local.instances)[0]["Secret access key"]
  region = "us-east-1"
}


data "aws_iam_policy_document" "AWSLambdaTrustPolicy" {
  statement {
    actions    = ["sts:AssumeRole"]
    effect     = "Allow"
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "s3_quest_terraform" {
  name               = "automate_terraform"
  assume_role_policy = "${data.aws_iam_policy_document.AWSLambdaTrustPolicy.json}"
}

resource "aws_iam_role_policy_attachment" "srd_policy-attachment" {
  for_each = toset([
    "arn:aws:iam::aws:policy/AmazonS3FullAccess", 
    "arn:aws:iam::aws:policy/AWSLambda_FullAccess",
    "arn:aws:iam::aws:policy/AmazonSQSFullAccess",
    "arn:aws:iam::aws:policy/AmazonEventBridgeFullAccess",
    "arn:aws:iam::aws:policy/AmazonEventBridgeSchemasFullAccess",
    "arn:aws:iam::aws:policy/AmazonEventBridgeSchedulerFullAccess",
    "arn:aws:iam::aws:policy/CloudWatchFullAccess",
    "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  ])
  role       = "${aws_iam_role.s3_quest_terraform.name}"
  policy_arn = each.value
}

resource "aws_s3_bucket" "s1quest" {
    bucket = "s1quest"
    acl    = "public-read"
}

resource "aws_s3_bucket" "s2quest" {
    bucket = "s2quest"
}
