resource "aws_iam_role" "lambda_role" {
  name = "pipeline_lambda_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com" # Change from ec2 to lambda
        }
      },
    ]
  })
}
