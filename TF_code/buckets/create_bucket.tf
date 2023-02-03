locals {
  instances = csvdecode(file("../user/private_key.csv"))
}

provider "aws" {
  access_key=tolist(local.instances)[0]["Access key ID"]
  secret_key=tolist(local.instances)[0]["Secret access key"]
  region = "us-east-1"
}

resource "aws_s3_bucket" "s1quest" {
    bucket = "s1quest"
    website {
      index_document = "index.html"
      error_document = "index.html"
    }
}

resource "aws_s3_bucket_public_access_block" "s1quest" {
  bucket = aws_s3_bucket.s1quest.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "public_access" {
  bucket = aws_s3_bucket.s1quest.id

  policy = <<POLICY
  {
    
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": "*",
        "Action": "s3:GetObject",
        "Resource": "arn:aws:s3:::s1quest/*",
        "Condition": {
          "StringEquals": {
            "s3:ExistingObjectTag/public": "yes"
          }
        }
      }
    ]
  }
  POLICY
}

resource "aws_s3_bucket" "s2quest" {
    bucket = "s2quest"
}

resource "aws_s3_bucket_public_access_block" "s2quest" {
  bucket = aws_s3_bucket.s2quest.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}