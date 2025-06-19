# modules/eks-node-groups/main.tf

# Data source for EKS worker AMI
data "aws_ami" "eks_worker" {
  for_each = {
    for k, v in var.node_groups : k => v.ami_type
  }

  filter {
    name   = "name"
    values = ["amazon-eks-node-${var.cluster.version}-v*"]
  }

  filter {
    name   = "architecture"
    values = [contains(["AL2_ARM_64"], each.value) ? "arm64" : "x86_64"]
  }

  most_recent = true
  owners      = ["602401143452"] # Amazon EKS AMI Account ID
}

# Node Group IAM Role
data "aws_iam_policy_document" "node_group_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "node_group" {
  name               = "${var.cluster.name}-ng-role"
  assume_role_policy = data.aws_iam_policy_document.node_group_assume_role.json

  tags = merge(
    var.general_tags,
    {
      Name = "${var.cluster.name}-worker-role"
    }
  )
}

resource "aws_iam_role_policy_attachment" "node_group_worker_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.node_group.name
}

resource "aws_iam_role_policy_attachment" "node_group_cni_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.node_group.name
}

resource "aws_iam_role_policy_attachment" "node_group_registry_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.node_group.name
}

resource "aws_iam_role_policy_attachment" "node_group_ssm_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.node_group.name
}

resource "aws_launch_template" "node_group" {
  for_each = var.node_groups

  name_prefix   = "${var.cluster.name}-${each.key}"
  description   = "Launch template for ${var.cluster.name} ${each.key} node group"
  image_id      = data.aws_ami.eks_worker[each.key].id
  instance_type = each.value.instance_types[0]
  key_name      = each.value.remote_access_enabled && each.value.ec2_ssh_key != null ? each.value.ec2_ssh_key : null

user_data = base64encode(templatefile("${path.module}/userdata.sh", {
  cluster_name = var.cluster.name
}))

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size           = each.value.disk_size
      volume_type           = each.value.disk_type
      iops                  = contains(["io1", "io2", "gp3"], each.value.disk_type) ? each.value.disk_iops : null
      throughput            = each.value.disk_type == "gp3" ? each.value.disk_throughput : null
      encrypted             = true
      delete_on_termination = true
    }
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = var.settings.enable_imdsv2 ? "required" : "optional"
    http_put_response_hop_limit = 2
    instance_metadata_tags      = "enabled"
  }

  monitoring {
    enabled = var.settings.enable_monitoring
  }

  tag_specifications {
    resource_type = "instance"

    tags = merge(
      var.general_tags,
      var.optional_tags.launch_template,
      {
        Name = "${var.cluster.name}-${each.key}-worker"
      }
    )
  }

  tag_specifications {
    resource_type = "volume"
    tags = merge(
      var.general_tags,
      var.optional_tags.launch_template,
      {
        Name = "${var.cluster.name}-${each.key}-worker-volume"
      }
    )
  }

  tag_specifications {
    resource_type = "network-interface"
    tags = merge(
      var.general_tags,
      var.optional_tags.launch_template,
      {
        Name = "${var.cluster.name}-${each.key}-worker-eni"
      }
    )
  }

  tags = merge(
    var.general_tags,
    {
      Name = "${var.cluster.name}-launch-template"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_eks_node_group" "main" {
  for_each = var.node_groups

  cluster_name    = var.cluster.name
  node_group_name = "${var.cluster.name}-${each.key}"
  node_role_arn   = aws_iam_role.node_group.arn
  subnet_ids      = each.value.subnet_ids != null ? each.value.subnet_ids : var.network.subnet_ids

  capacity_type        = each.value.capacity_type
  force_update_version = each.value.force_update_version

  launch_template {
    id      = aws_launch_template.node_group[each.key].id
    version = aws_launch_template.node_group[each.key].latest_version
  }

  # capacity_type    = each.value.capacity_type
  # instance_types   = each.value.instance_types
  # ami_type        = each.value.ami_type
  # disk_size       = each.value.disk_size
  # force_update_version = each.value.force_update_version

  scaling_config {
    desired_size = each.value.desired_capacity
    max_size     = each.value.max_capacity
    min_size     = each.value.min_capacity
  }

  update_config {
    max_unavailable            = each.value.max_unavailable_percentage == null ? each.value.max_unavailable : null
    max_unavailable_percentage = each.value.max_unavailable_percentage
  }

  dynamic "remote_access" {
    for_each = each.value.remote_access_enabled ? [1] : []
    content {
      ec2_ssh_key               = each.value.ec2_ssh_key
      source_security_group_ids = each.value.source_security_groups
    }
  }

  labels = each.value.k8s_labels

  dynamic "taint" {
    for_each = each.value.k8s_taints
    content {
      key    = taint.value.key
      value  = taint.value.value
      effect = taint.value.effect
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.node_group_worker_policy,
    aws_iam_role_policy_attachment.node_group_cni_policy,
    aws_iam_role_policy_attachment.node_group_registry_policy,
  ]

  tags = merge(
    var.general_tags,
    {
      Name = "${var.cluster.name}-${each.key}-node-group"
    }
  )

  lifecycle {
    ignore_changes = [scaling_config[0].desired_size]
  }
}



