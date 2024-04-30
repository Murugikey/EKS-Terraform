resource "aws_s3_bucket" "load_balancers_s3_bucket" {
  bucket = "${replace(var.NAME_PREFIX, "/[^-a-zA-Z0-9]/", "-")}-lb-${var.LOGGING_BUCKET_NAME}"
  force_destroy = true
  
  tags = var.DEFAULT_TAGS
}

resource "aws_s3_bucket_lifecycle_configuration" "load_balancers_s3_bucket_lifecycle" {
  bucket = aws_s3_bucket.load_balancers_s3_bucket.id
  rule {
    id = "lifecycle-log"
    status = "Enabled"
    expiration {
      days = 90
    }
  }
}
resource "aws_s3_bucket_versioning" "load_balancers_s3_bucket_versioning" {
  bucket = aws_s3_bucket.load_balancers_s3_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}
resource "aws_s3_bucket_server_side_encryption_configuration" "load_balancers_s3_bucket_server_side_encryption_configuration" {
  bucket = aws_s3_bucket.load_balancers_s3_bucket.id

  rule {
      apply_server_side_encryption_by_default {
        sse_algorithm     = "AES256"
    }
  }
}

resource "aws_s3_bucket_logging" "load_balancers_s3_bucket_logging" {
  bucket        = aws_s3_bucket.load_balancers_s3_bucket.id
  target_bucket = var.ACCESS_LOGS_BUCKET_ID
  target_prefix = "load-balancers/log-"
}

resource "aws_s3_bucket_policy" "load_balancers_bucket_policy" {
  bucket = aws_s3_bucket.load_balancers_s3_bucket.id

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Deny",
      "Principal": "*",
      "Action": "*",
      "Resource": [
        "${aws_s3_bucket.load_balancers_s3_bucket.arn}",
        "${aws_s3_bucket.load_balancers_s3_bucket.arn}/*"
      ],
      "Condition": {
        "Bool": {
          "aws:SecureTransport": "false"
        }
      }
    },
    {
        "Effect": "Allow",
        "Principal": {
          "AWS": "${data.aws_caller_identity.current.arn}"
        },
        "Action": [
            "s3:PutObject",
            "s3:GetObject",
            "s3:ListBucket",
            "s3:PutObjectAcl",
            "s3:GetEncryptionConfiguration"
        ],
      "Resource": ["${aws_s3_bucket.load_balancers_s3_bucket.arn}", "${aws_s3_bucket.load_balancers_s3_bucket.arn}/*"]
    },
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::156460612806:root"
      },
      "Action": "s3:PutObject",
      "Resource": ["${aws_s3_bucket.load_balancers_s3_bucket.arn}", "${aws_s3_bucket.load_balancers_s3_bucket.arn}/*"]
    },
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "delivery.logs.amazonaws.com"
      },
      "Action": "s3:PutObject",
      "Resource": ["${aws_s3_bucket.load_balancers_s3_bucket.arn}", "${aws_s3_bucket.load_balancers_s3_bucket.arn}/*"],
      "Condition": {
        "StringEquals": {
          "s3:x-amz-acl": "bucket-owner-full-control"
        }
      }
    },
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "delivery.logs.amazonaws.com"
      },
      "Action": "s3:GetBucketAcl",
      "Resource": ["${aws_s3_bucket.load_balancers_s3_bucket.arn}", "${aws_s3_bucket.load_balancers_s3_bucket.arn}/*"]
    }
  ]
}
POLICY
  lifecycle {
    ignore_changes = [
          policy
    ]
  }
}