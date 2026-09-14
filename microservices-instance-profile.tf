resource "aws_iam_role" "microservice-ec2-role" {
  name = "${local.name_prefix}-app-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}


resource "aws_iam_policy" "app_ssm_parameter_read" {
  name        = "${local.name_prefix}-app-ssm-parameter-read"
  description = "Allow EC2 instance to read the order/payment DB connection parameters from SSM"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ReadAppDbParameters"
        Effect = "Allow"
        Action = "ssm:GetParameter"
        Resource = [
          "arn:aws:ssm:${var.region}:${data.aws_caller_identity.current.account_id}:parameter/${var.environment}/order-*",
          "arn:aws:ssm:${var.region}:${data.aws_caller_identity.current.account_id}:parameter/${var.environment}/payment-*"
        ]
      },
      {
        Sid      = "DecryptSecureStringDefaultKey"
        Effect   = "Allow"
        Action   = "kms:Decrypt"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_policy" "app_s3_access" {
  name        = "${local.name_prefix}-app-s3-access"
  description = "Allow EC2 instances to read/write objects under osers/ and payments/ prefices in the microservices S3 bucket"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ReadWriteObjects"
        Effect = "Allow"
        Action = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
        Resource = [
          "${aws_s3_bucket.microservices.arn}/orders/*",
          "${aws_s3_bucket.microservices.arn}/payments/*"
        ]
      },
      {
        Sid      = "ListBucketPrefixes"
        Effect   = "Allow"
        Action   = "s3:ListBucket"
        Resource = aws_s3_bucket.microservices.arn
        Condition = {
          StringLike = { "s3:prefix" = ["orders/*", "payments/*"] }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "app_ssm_parameter_read" {
  role       = aws_iam_role.microservice-ec2-role.name
  policy_arn = aws_iam_policy.app_ssm_parameter_read.arn
}


# resource "aws_iam_role_policy_attachment" "cloudwatch_logs" {
#   role       = aws_iam_role.microservice-ec2-role.name
#   policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
# }

resource "aws_iam_role_policy_attachment" "app_s3_access" {
  role       = aws_iam_role.microservice-ec2-role.name
  policy_arn = aws_iam_policy.app_s3_access.arn
}

resource "aws_iam_role_policy_attachment" "ssm_attach" {
  role       = aws_iam_role.microservice-ec2-role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "ecr_readonly" {
  role       = aws_iam_role.microservice-ec2-role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "cloudwatch_agent" {
  role       = aws_iam_role.microservice-ec2-role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_instance_profile" "microservice_instance_profile" {
  name = "${local.name_prefix}-ec2-profile"
  role = aws_iam_role.microservice-ec2-role.name
}
