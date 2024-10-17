# AWS Lambda function
resource "aws_lambda_function" "aws_lambda_iterate" {
  filename         = "iterate.zip"
  function_name    = "${var.prefix}-iterate"
  role             = aws_iam_role.aws_lambda_iterate_execution_role.arn
  handler          = "iterate.handler"
  runtime          = "python3.12"
  source_code_hash = filebase64sha256("iterate.zip")
  timeout          = 300
  environment {
    variables = {
      ENV_PREFIX = var.prefix
    }
  }
  vpc_config {
    subnet_ids         = data.aws_subnets.private_application_subnets.ids
    security_group_ids = data.aws_security_groups.vpc_default_sg.ids
  }
  file_system_config {
    arn              = data.aws_efs_access_point.fsap_iterate.arn
    local_mount_path = "/mnt/input"
  }
  tags = {
    "Name" = "${var.prefix}-iterate"
  }
}

# AWS Lambda execution role & policy
resource "aws_iam_role" "aws_lambda_iterate_execution_role" {
  name = "${var.prefix}-lambda-iterate-execution-role"
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "lambda.amazonaws.com"
        },
        "Action" : "sts:AssumeRole"
      }
    ]
  })
}

# Execution policy
resource "aws_iam_role_policy_attachment" "aws_lambda_iterate_execution_role_policy_attach" {
  role       = aws_iam_role.aws_lambda_iterate_execution_role.name
  policy_arn = aws_iam_policy.aws_lambda_iterate_execution_policy.arn
}

resource "aws_iam_policy" "aws_lambda_iterate_execution_policy" {
  name        = "${var.prefix}-lambda-iterate-execution-policy"
  description = "Enable EventBridge schedule."
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "AllowCreatePutLogs",
        "Effect" : "Allow",
        "Action" : [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        "Resource" : "arn:aws:logs:*:*:*"
      },
      {
        "Sid" : "AllowVPCAccess",
        "Effect" : "Allow",
        "Action" : [
          "ec2:CreateNetworkInterface"
        ],
        "Resource" : concat([for subnet in data.aws_subnet.private_application_subnet : subnet.arn], ["arn:aws:ec2:${var.aws_region}:${local.account_id}:*/*"])
      },
      {
        "Sid" : "AllowVPCDelete",
        "Effect" : "Allow",
        "Action" : [
          "ec2:DeleteNetworkInterface"
        ],
        "Resource" : "arn:aws:ec2:${var.aws_region}:${local.account_id}:*/*"
      },
      {
        "Sid" : "AllowVPCDescribe",
        "Effect" : "Allow",
        "Action" : [
          "ec2:DescribeNetworkInterfaces"
        ],
        "Resource" : "*"
      },
      {
        "Sid" : "AllowEFSAccess",
        "Effect" : "Allow",
        "Action" : [
          "elasticfilesystem:ClientMount",
          "elasticfilesystem:ClientWrite",
          "elasticfilesystem:DescribeMountTargets"
        ],
        "Resource" : "${data.aws_efs_access_point.fsap_iterate.file_system_arn}"
        "Condition" : {
          "StringEquals" : {
            "elasticfilesystem:AccessPointArn" : "${data.aws_efs_access_point.fsap_iterate.arn}"
          }
        }
      },
      {
        "Sid" : "AllowStepFunctions",
        "Effect" : "Allow",
        "Action" : [
          "states:SendTaskFailure",
          "states:SendTaskSuccess"
        ],
        "Resource" : "arn:aws:states:${var.aws_region}:${local.account_id}:stateMachine:${var.prefix}-workflow"
      }
    ]
  })
}
