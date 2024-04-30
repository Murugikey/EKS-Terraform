
##Creates the below 4 Buckets
#1. Access Logs Bucket
#2. Startup scripts Bucket
#3. Artifacts Bucket

##Access logs bucket
resource "aws_s3_bucket" "access_logs_bucket" {
  bucket = "${replace(var.name_prefix, "/[^-a-zA-Z0-9]/", "-")}-access-logs"
  force_destroy = true
  tags = var.default_tags
}

resource "aws_s3_bucket_acl" "access_logs_bucket_acl" {
  bucket = aws_s3_bucket.access_logs_bucket.id
  acl    = "log-delivery-write"
}
resource "aws_s3_bucket_server_side_encryption_configuration" "access_logs_bucket_server_side_encryption_configuration" {
  bucket = aws_s3_bucket.access_logs_bucket.id
  rule {
      apply_server_side_encryption_by_default {
      sse_algorithm     = "AES256"
    }
  }
}

#resource "aws_s3_bucket_logging" "access_logs_bucket_logging" {
#  bucket        = aws_s3_bucket.access_logs_bucket.id
#  target_bucket = "${var.s3_logging_bucket}"
#  target_prefix = "${var.name_prefix}-${data.aws_region.current.name}-access-logs-logs/log-"
#}

resource "aws_s3_bucket_lifecycle_configuration" "access_logs_bucket_lifecycle_configuration_lifecycle" {
  bucket = aws_s3_bucket.access_logs_bucket.id
  rule {
    id = "lifecycle-log"
    status = "Enabled"
    expiration {
      days = 90
    }
  }
}


resource "aws_s3_bucket_policy" "access_logs_bucket_ssl_policy" {
  bucket = aws_s3_bucket.access_logs_bucket.id

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Deny",
      "Principal": "*",
      "Action": "*",
      "Resource": [
        "${aws_s3_bucket.access_logs_bucket.arn}",
        "${aws_s3_bucket.access_logs_bucket.arn}/*"
      ],
      "Condition": {
        "Bool": {
          "aws:SecureTransport": "false"
        }
      }
    }
  ]
}
POLICY
}


##Startupscripts bkt
resource "aws_s3_bucket" "startup_scripts_s3_bucket" {
  bucket = "${replace(var.name_prefix, "/[^-a-zA-Z0-9]/", "-")}-start-up-scripts"
  force_destroy = true
  tags = var.default_tags
}

resource "aws_s3_bucket_acl" "startup_scripts_bucket_acl" {
  bucket = aws_s3_bucket.startup_scripts_s3_bucket.id
  acl    = "log-delivery-write"
}
resource "aws_s3_bucket_server_side_encryption_configuration" "startup_scripts_bucket_server_side_encryption_configuration" {
  bucket = aws_s3_bucket.startup_scripts_s3_bucket.id
  rule {
      apply_server_side_encryption_by_default {
      sse_algorithm     = "AES256"
    }
  }
}

resource "aws_s3_bucket_logging" "startup_scripts_s3_bucket_logging" {
  bucket        = aws_s3_bucket.startup_scripts_s3_bucket.id
  target_bucket = aws_s3_bucket.access_logs_bucket.id
  target_prefix = "startup-scripts/log-"
}

resource "aws_s3_bucket_policy" "startup_scripts_bucket_ssl_policy" {
  bucket = aws_s3_bucket.startup_scripts_s3_bucket.id

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Deny",
      "Principal": "*",
      "Action": "*",
      "Resource": [
        "${aws_s3_bucket.startup_scripts_s3_bucket.arn}",
        "${aws_s3_bucket.startup_scripts_s3_bucket.arn}/*"
      ],
      "Condition": {
        "Bool": {
          "aws:SecureTransport": "false"
        }
      }
    }
  ]
}
POLICY
}


resource "aws_s3_bucket" "artifacts_s3_bucket" {
  bucket = "${replace(var.name_prefix, "/[^-a-zA-Z0-9]/", "-")}-${data.aws_caller_identity.current.account_id}-artifacts"
  force_destroy = true

  tags = var.default_tags
}


resource "aws_s3_bucket_acl" "artifacts_s3_bucket_acl" {
  bucket = aws_s3_bucket.artifacts_s3_bucket.id
  acl    = "private"
}
resource "aws_s3_bucket_server_side_encryption_configuration" "artifacts_s3_bucket_server_side_encryption_configuration" {
  bucket = aws_s3_bucket.artifacts_s3_bucket.id
  rule {
      apply_server_side_encryption_by_default {
      sse_algorithm     = "AES256"
    }
  }
}

resource "aws_s3_bucket_logging" "artifacts_s3_bucket_logging" {
  bucket        = aws_s3_bucket.artifacts_s3_bucket.id
  target_bucket = aws_s3_bucket.access_logs_bucket.id
  target_prefix = "artifacts/log-"
}

resource "aws_s3_bucket_policy" "artifacts_s3_bucket_ssl_policy" {

  bucket = aws_s3_bucket.artifacts_s3_bucket.id
  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Deny",
      "Principal": "*",
      "Action": [
                "s3:GetObject",
                "s3:ListBucket",
                "s3:PutObject",
                "s3:ListBucketMultipartUploads",
                "s3:ListMultipartUploadParts"
                ],
      "Resource": [
        "${aws_s3_bucket.artifacts_s3_bucket.arn}",
        "${aws_s3_bucket.artifacts_s3_bucket.arn}/*"
      ],
      "Condition": {
        "Bool": {
          "aws:SecureTransport": "false"
        }
      }
    }
  ]
}
POLICY
} 