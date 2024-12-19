provider "aws" {
  region = "eu-central-1"
}

module "nixos_deploy_document" {
  source = "./../.."
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

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.webserver.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "webserver" {
  name = "webserver"
  role = aws_iam_role.webserver.name
}

resource "aws_instance" "webserver" {
  count                = 2
  ami                  = data.aws_ami.nixos.id
  iam_instance_profile = aws_iam_instance_profile.webserver.name
  instance_type        = "t3a.small"
  tags = {
    Role = "webserver"
  }
}

resource "aws_ssm_association" "webserver" {
  name = module.nixos_deploy_document.id
  targets {
    key    = "tag:Role"
    values = ["webserver"]
  }
  parameters = {
    installable = "github:arianvp/terraform-aws-ssm-nixos-deploy-document?dir=examples/ec2_instance_flakeref#nixosConfigurations.webserver.config.system.build.toplevel"
  }
  max_concurrency = "50%"
}