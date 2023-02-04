# Access the root user's credentials
locals {
  instances = csvdecode(file("../../srd22_accessKeys.csv"))
}

provider "aws" {
  access_key=tolist(local.instances)[0]["Access key ID"]
  secret_key=tolist(local.instances)[0]["Secret access key"]
  region = "us-east-1"
}

# ------------------------------------------------------

# Create a new IAM User
resource "aws_iam_user" "user" {
  name = "rearc-user"
}

# Create the user's key
resource "aws_iam_access_key" "user_key" {
  user    = "${aws_iam_user.user.name}"
  depends_on = [aws_iam_user.user]
}

# Save the user key locally
resource "local_file" "private_key" {
    content  = "Access key ID,Secret access key\n${aws_iam_access_key.user_key.id},${aws_iam_access_key.user_key.secret}"
    filename = "private_key.csv"
}

# ------------------------------------------------------

# Attach the required policies
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

# ------------------------------------------------------

# Get the existing policy for required for lambda function service
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

# Create a new IAM Policy and attach the lambda function service to it.
resource "aws_iam_role" "s3_quest_terraform" {
  name               = "automate_terraform"
  assume_role_policy = "${data.aws_iam_policy_document.AWSLambdaTrustPolicy.json}"
  depends_on = [
    aws_iam_access_key.user_key
  ]
}

# Add additional policies to newly created role.
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