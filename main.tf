resource "aws_iam_role" "lambda-ec2handler" {
  name               = "lambda-ec2handler"
  description        = "Allows Lambda functions to call AWS services on your behalf."
  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": [
          "lambda.amazonaws.com"
        ]
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_policy" "lambda-ec2handler" {
  name        = "lambda-ec2handler-terminate"
  description = "EC2 state handler policy"
  policy      = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["logs:*"],
      "Resource": "arn:aws:logs:*:*:*"
    },
    {
      "Effect": "Allow",
      "Action": [
                "ec2:DescribeInstances",
                "route53domains:ListDomains",
                "route53:ListHostedZones",
                "route53:ListTagsForResource",
                "route53:GetHostedZone",
                "route53:ListHostedZonesByName",
                "route53:ListResourceRecordSets",
                "route53:ChangeResourceRecordSets",
                "route53:ListTagsForResources",
                "route53:ChangeTagsForResource"
      ],
      "Resource": ["*"]
    }
  ]
}
POLICY
}


# store script path
resource "aws_iam_role_policy_attachment" "lambda-ec2handler" {
  role       = "${aws_iam_role.lambda-ec2handler.name}"
  policy_arn = "${aws_iam_policy.lambda-ec2handler.arn}"
}

data "archive_file" "lambda-ec2handler" {
  type        = "zip"
  source_dir  = ".terraform/modules/${basename(path.module)}/files/source/"
  output_path = ".terraform/modules/${basename(path.module)}/files/python36_env.zip"
}

resource "aws_lambda_function" "lambda-ec2handler-terminate" {
  filename         = "${data.archive_file.lambda-ec2handler.output_path}"
  function_name    = "lambda-ec2handler-terminate"
  description      = "Lambda EC2 terminate state handler"
  role             = "${aws_iam_role.lambda-ec2handler.arn}"
  handler          = "ec2handler-terminate.lambda_handler"
  source_code_hash = "${base64sha256(file("${data.archive_file.lambda-ec2handler.output_path}"))}"
  runtime          = "python3.6"
  timeout          = 300
  publish          = false

  environment {
    variables = {
      ZONE_NAME = "${var.zone_name}",
      ZONE_ID = "${var.zone_id}"
    }
  }

  tags = "${var.tags}"
}


resource "aws_cloudwatch_event_rule" "cloudwatch-ec2handler-terminate" {
  name        = "cloudwatch-ec2handler-terminate"
  event_pattern = <<PATTERN
{
  "source": [
    "aws.ec2"
  ],
  "detail-type": [
    "EC2 Instance State-change Notification"
  ],
  "detail": {
    "state": [
      "terminated"
    ]
  }
}
PATTERN

}

resource "aws_cloudwatch_event_target" "lambda-ec2handler-terminate" {
  rule      = "${aws_cloudwatch_event_rule.cloudwatch-ec2handler-terminate.name}"
  target_id = "lambda-ec2handler-terminate"
  arn       = "${aws_lambda_function.lambda-ec2handler-terminate.arn}"
}




