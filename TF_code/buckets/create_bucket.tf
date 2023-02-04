# Acccess the user's credentials
locals {
  instances = csvdecode(file("../user/private_key.csv"))
}

provider "aws" {
  access_key=tolist(local.instances)[0]["Access key ID"]
  secret_key=tolist(local.instances)[0]["Secret access key"]
  region = "us-east-1"
}

# ------------------------------------------------------

# Create a publicly available S3 Bucket that will store the Datasetfrom Step 1
resource "aws_s3_bucket" "s1quest" {
    bucket = "s1quest"

    # Allow making https/http get post request to the staticly hosted website of the S3.
    cors_rule {
      allowed_headers = ["Authorization", "Content-Length"]
      allowed_methods = ["GET", "POST"]
      allowed_origins = ["*"]
      max_age_seconds = 3000
    }

    website {
      index_document = "index.html"
    }
}

# Remove all the public blockers from S3.
resource "aws_s3_bucket_public_access_block" "s1quest" {
  bucket = aws_s3_bucket.s1quest.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# Give the public access.
resource "aws_s3_bucket_policy" "public_access" {
  bucket = aws_s3_bucket.s1quest.id

  policy = <<POLICY
  {
    
    "Version": "2012-10-17",
    "Statement": [
      {
        "Sid": "PublicReadGetObject",
        "Effect": "Allow",
        "Principal": "*",
        "Action": "s3:GetObject",
        "Resource": "arn:aws:s3:::s1quest/*"
      }
    ]
  }
  POLICY
}

# ------------------------------------------------------

# Create another bucket for data.json asked in step 2
resource "aws_s3_bucket" "s2quest" {
    bucket = "s2quest"
}

# Block all the public access to this S3 bucket.
resource "aws_s3_bucket_public_access_block" "s2quest" {
  bucket = aws_s3_bucket.s2quest.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}