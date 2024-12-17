
provider "aws" {
  region = "eu-central-1"
}

resource "aws_s3_bucket" "cache" {
  bucket_prefix = "cache"
}

locals {
  store_uri = "s3://${aws_s3_bucket.cache.bucket}?region=${aws_s3_bucket.cache.region}"
}

output "store_uri" {
  description = "the store URI for the S3 binary cache"
  value       = local.store_uri
}

resource "aws_iam_policy" "read_cache" {
  name_prefix = "ReadCache"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["s3:GetObject"]
      Resource = "${aws_s3_bucket.cache.arn}/*"
    }]
  })
}

variable "public_key" {
  description = "The public key used to sign store paths pushed to store_uri"
  type        = string
}

module "nixos_deploy_document" {
  source     = "./../.."
  name       = "NixOS-Deploy2"
  nix_config = <<-EOF
    extra-substituters        = ${local.store_uri}
    extra-trusted-public-keys = ${var.public_key}
  EOF
}

resource "aws_iam_role" "webserver" {
  name = "webserver"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = {
      Effect    = "Allow"
      Action    = "sts:AssumeRole"
      Principal = { Service = "ec2.amazonaws.com" }
    }
  })
}

resource "aws_iam_role_policy_attachment" "webserver" {
  for_each = {
    "ssm"        = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
    "read_cache" = aws_iam_policy.read_cache.arn
  }
  role       = aws_iam_role.webserver.name
  policy_arn = each.value
}

variable "use_dhmc" {
  description = "Whether to use the default EC2 management role"
  type        = bool
  default     = false
}

resource "aws_iam_role_policy_attachment" "dhmc" {
  count      = var.use_dhmc ? 1 : 0
  role       = "AWS-QuickSetup-SSM-DefaultEC2MgmtRole-eu-central-1"
  policy_arn = aws_iam_policy.read_cache.arn
}

resource "aws_iam_instance_profile" "webserver" {
  name = "webserver"
  role = aws_iam_role.webserver.name
}

# https://nixos.org/download/#nixos-amazon
data "aws_ami" "nixos" {
  owners      = ["427812963091"]
  most_recent = true

  filter {
    name   = "name"
    values = ["nixos/24.11*"]
  }
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

resource "aws_instance" "webserver" {
  count                = 2
  ami                  = data.aws_ami.nixos.id
  instance_type        = "t3a.small"
  iam_instance_profile = aws_iam_instance_profile.webserver.name
  root_block_device {
    volume_size = 20
  }
  tags = {
    Role = "webserver"
  }
}

variable "store_path" {
  description = "The nix store path to substitute on the machine. Must be pushed to outputs.store_uri and signed with var.public_key beforehand."
  type        = string
  default     = "/run/current-system"
}

resource "aws_ssm_association" "webserver" {
  name = module.nixos_deploy_document.id
  targets {
    key    = "tag:Role"
    values = ["webserver"]
  }
  parameters = {
    installable = var.store_path
  }
  max_concurrency = "50%"
}