# terraform/modules/iam/main.tf
data "aws_caller_identity" "current" {}

# IAM Role for Main API Service Account
data "aws_iam_policy_document" "main_api_assume_role" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [var.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${var.oidc_provider_url}:sub"
      values   = ["system:serviceaccount:main-api:main-api-service-account"]
    }

    condition {
      test     = "StringEquals"
      variable = "${var.oidc_provider_url}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "main_api" {
  name               = "${var.general_tags.Project}-${var.general_tags.Environment}-main-api-role"
  assume_role_policy = data.aws_iam_policy_document.main_api_assume_role.json

  tags = merge(var.general_tags, {
    Name    = "${var.general_tags.Project}-${var.general_tags.Environment}-main-api-role"
    Service = "main-api"
  })
}

# IAM Policy for Main API
data "aws_iam_policy_document" "main_api_policy" {
  statement {
    effect = "Allow"
    actions = [
      "s3:ListAllMyBuckets",
      "s3:GetBucketLocation"
    ]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "ssm:GetParameter",
      "ssm:GetParameters",
      "ssm:GetParametersByPath",
      "ssm:DescribeParameters"
    ]
    resources = tolist([
      "arn:aws:ssm:${var.region}:${var.account_id}:parameter/${var.general_tags.Project}/${var.general_tags.Environment}/*"
    ])
  }
}

resource "aws_iam_policy" "main_api" {
  name        = "${var.general_tags.Project}-${var.general_tags.Environment}-main-api-policy"
  description = "IAM policy for main API service"
  policy      = data.aws_iam_policy_document.main_api_policy.json

  tags = var.general_tags
}

resource "aws_iam_role_policy_attachment" "main_api" {
  role       = aws_iam_role.main_api.name
  policy_arn = aws_iam_policy.main_api.arn
}

# IAM Role for Auxiliary Service Account
data "aws_iam_policy_document" "auxiliary_service_assume_role" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [var.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${var.oidc_provider_url}:sub"
      values   = ["system:serviceaccount:auxiliary-service:auxiliary-service-account"]
    }

    condition {
      test     = "StringEquals"
      variable = "${var.oidc_provider_url}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "auxiliary_service" {
  name               = "${var.general_tags.Project}-${var.general_tags.Environment}-auxiliary-service-role"
  assume_role_policy = data.aws_iam_policy_document.auxiliary_service_assume_role.json

  tags = merge(var.general_tags, {
    Name    = "${var.general_tags.Project}-${var.general_tags.Environment}-auxiliary-service-role"
    Service = "auxiliary-service"
  })
}

# IAM Policy for Auxiliary Service
data "aws_iam_policy_document" "auxiliary_service_policy" {
  statement {
    effect = "Allow"
    actions = [
      "s3:ListAllMyBuckets",
      "s3:ListBucket"
    ]
    resources = concat(["*"], var.s3_bucket_arns)
  }

  statement {
    effect = "Allow"
    actions = [
      "ssm:GetParameter",
      "ssm:GetParametersByPath",
    ]
    resources = tolist([
      "arn:aws:ssm:${var.region}:${var.account_id}:parameter/${var.general_tags.Project}/${var.general_tags.Environment}/*"
    ])
  }
}

resource "aws_iam_policy" "auxiliary_service" {
  name        = "${var.general_tags.Project}-${var.general_tags.Environment}-auxiliary-service-policy"
  description = "IAM policy for auxiliary service"
  policy      = data.aws_iam_policy_document.auxiliary_service_policy.json

  tags = var.general_tags
}

resource "aws_iam_role_policy_attachment" "auxiliary_service" {
  role       = aws_iam_role.auxiliary_service.name
  policy_arn = aws_iam_policy.auxiliary_service.arn
}

# GitHub OIDC Provider
resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com",
  ]

  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1",
    "1c58a3a8518e8759bf075b76b750d4f2df264fcd"
  ]

  tags = var.general_tags
}

# IAM Role for Main API Repository
resource "aws_iam_role" "github_actions_main_api" {
  name = "${var.general_tags.Project}-${var.general_tags.Environment}-github-main-api-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:${var.github_org}/${var.main_api_repo_name}:*"
          }
        }
      }
    ]
  })

  tags = var.general_tags
}

# IAM Role for Auxiliary Service Repository
resource "aws_iam_role" "github_actions_auxiliary_service" {
  name = "${var.general_tags.Project}-${var.general_tags.Environment}-github-auxiliary-service-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:${var.github_org}/${var.auxiliary_service_repo_name}:*"
          }
        }
      }
    ]
  })

  tags = var.general_tags
}

# GitHub Actions Policy (updated from your existing policy)
data "aws_iam_policy_document" "github_actions_policy" {
  statement {
    effect = "Allow"
    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
      "ecr:PutImage",
      "ecr:DescribeImages",
      "ecr:BatchDeleteImage"
    ]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "eks:DescribeCluster",
      "eks:ListClusters"
    ]
    resources = [
      "arn:aws:eks:*:*:cluster/${var.cluster_name}"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "ssm:GetParameter",
      "ssm:PutParameter"
    ]
    resources = [
      "arn:aws:ssm:*:*:parameter/${var.general_tags.Project}/${var.general_tags.Environment}/version/*"
    ]
  }
}

resource "aws_iam_policy" "github_actions" {
  name        = "${var.general_tags.Project}-${var.general_tags.Environment}-github-actions-policy"
  description = "IAM policy for GitHub Actions"
  policy      = data.aws_iam_policy_document.github_actions_policy.json

  tags = var.general_tags
}

# Attach policy to Main API role
resource "aws_iam_role_policy_attachment" "github_actions_main_api" {
  role       = aws_iam_role.github_actions_main_api.name
  policy_arn = aws_iam_policy.github_actions.arn
}

# Attach policy to Auxiliary Service role
resource "aws_iam_role_policy_attachment" "github_actions_auxiliary_service" {
  role       = aws_iam_role.github_actions_auxiliary_service.name
  policy_arn = aws_iam_policy.github_actions.arn
}
