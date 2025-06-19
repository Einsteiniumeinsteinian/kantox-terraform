resource "aws_iam_policy" "ebs_csi_driver" {
  # name        = "${local.cluster_name}-ebs-csi-policy"
  name        = "ebs-csi-policy"
  description = "IAM policy for EBS CSI driver"
  policy      = jsonencode({
    Version = "2012-10-17",
    Statement = [
             {
            "Effect": "Allow",
            "Action": [
                "ec2:CreateSnapshot",
                "ec2:AttachVolume",
                "ec2:DetachVolume",
                "ec2:ModifyVolume",
                "ec2:DescribeAvailabilityZones",
                "ec2:DescribeInstances",
                "ec2:DescribeSnapshots",
                "ec2:DescribeTags",
                "ec2:DescribeVolumes",
                "ec2:DescribeVolumesModifications"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "ec2:CreateTags"
            ],
            "Resource": [
                "arn:aws:ec2:*:*:volume/*",
                "arn:aws:ec2:*:*:snapshot/*"
            ],
            "Condition": {
                "StringEquals": {
                    "ec2:CreateAction": [
                        "CreateVolume",
                        "CreateSnapshot"
                    ]
                }
            }
        },
        {
            "Effect": "Allow",
            "Action": [
                "ec2:DeleteTags"
            ],
            "Resource": [
                "arn:aws:ec2:*:*:volume/*",
                "arn:aws:ec2:*:*:snapshot/*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "ec2:CreateVolume"
            ],
            "Resource": "*",
            "Condition": {
                "StringLike": {
                    "aws:RequestedRegion": "*"
                }
            }
        },
        {
            "Effect": "Allow",
            "Action": [
                "ec2:DeleteVolume"
            ],
            "Resource": "*",
            "Condition": {
                "StringLike": {
                    "ec2:ResourceTag/ebs.csi.aws.com/cluster": "true"
                }
            }
        },
        {
            "Effect": "Allow",
            "Action": [
                "ec2:DeleteSnapshot"
            ],
            "Resource": "*",
            "Condition": {
                "StringLike": {
                    "ec2:ResourceTag/CSIVolumeSnapshotName": "*"
                }
            }
        }
    ]
  })
}

data "tls_certificate" "oidc" {
  url = module.eks_cluster.oidc_provider_url_https
}

resource "aws_iam_role" "ebs_csi_driver" {
  name = "ebs-csi-driver-sa-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Federated = module.eks_cluster.oidc_provider_arn
      },
      Action = "sts:AssumeRoleWithWebIdentity",
      Condition = {
        StringEquals = {
          "${replace(module.eks_cluster.oidc_provider_url_https, "https://", "")}:sub" = "system:serviceaccount:kube-system:ebs-csi-controller-sa"
        }
      }
    }]
  })

  tags = var.general_tags
}

resource "aws_iam_role_policy_attachment" "ebs_csi_driver_attach" {
  role       = aws_iam_role.ebs_csi_driver.name
  policy_arn = aws_iam_policy.ebs_csi_driver.arn
}

