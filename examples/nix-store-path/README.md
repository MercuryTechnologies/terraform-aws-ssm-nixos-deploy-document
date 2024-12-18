# Deploying a Nix Store Path

In this example, we will deploy a Nix store path to a set of EC2 instances.  We
will build the NixOS configuration, push the resulting Nix store path to an S3
bucket, and then substitute the store path on the instances. The benefit of this
approach is that the instances themselves do not evaluate or build the NixOS
configuration, but only substitute the store path. This means that the instances
do not require a lot of memory or CPU to deploy the configuration and also means
they only need access to S3 but not the public internet.

First, we need to generate a signing key to sign store paths that we want to push to the cache.

```shell
nix key generate-secret --key-name cache-1 > key.sec
nix key convert-secret-to-public < key.sec > key.pub

export TF_VAR_public_key="$(cat key.pub)"
```

Next, we define the S3 bucket that will be used as the cache. Together with a policy that allows reading from the bucket. We
will attach this policy to our instances later.

I advise putting the S3 bucket in a separate root module, so you can create it before
the instances and the SSM document. But in this example it's all in one file.

```hcl
resource "aws_s3_bucket" "cache" {
  bucket_prefix = "cache"
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
```

We define our server configuration in our `flake.nix`:

```nix
{
  description = "An example flake containing a NixOS configuration";
  inputs = { nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable"; };
  outputs = { nixpkgs, ... }: {
    nixosConfigurations.webserver = nixpkgs.lib.nixosSystem {
      modules = [
        ({ modulesPath, ... }: {
          imports = [ "${modulesPath}/virtualisation/amazon-image.nix" ];
          services.nginx.enable = true;
          nixpkgs.hostPlatform = "x86_64-linux";
          system.stateVersion = "24.11";
        })
      ];
    };
  };
}
```

We can now build the NixOS configuration and push it to the S3 bucket:
```shell
store_uri=$(terraform output -raw store_uri)
out_path=$(nix build --print-out-paths .#nixosConfigurations.webserver.config.system.build.toplevel)
nix copy --to "${store_uri}&secret-key=./key.sec" "${out_path}"

export TF_VAR_store_path="${out_path}"
```

Now that our NixOS configuration is pushed to our cache, we can set up our SSM
doucment to deploy NixOS configurations from our cache.  Note that this time we
pass the substituter and public key while creating the document. This means that
for all runs of the document we will use the same substituter and public key.
This way we do not have to specify it as a parameter for each association or
when doing a one-off `aws ssm send-command`. This is useful when you have many
NixOS deployments in a single AWS account that all use the same binary cache.

```hcl
variable "public_key" {
  description = "The public key used to sign store paths pushed to store_uri"
  type        = string
}

locals {
  store_uri = "s3://${aws_s3_bucket.cache.bucket}?region=${aws_s3_bucket.cache.region}"
}

module "nixos_deploy_document" {
  source     = "github.com/MercuryTechnologies/terraform-aws-ssm-nixos-deploy-document"
  nix_config = <<-EOF
    extra-substituters        = ${local.store_uri}
    extra-trusted-public-keys = ${var.public_key}
  EOF
}
```


With the document in place, we can create an association that associates the document and
the store path we want to deploy to a set of instances tagged with `Role=webserver`.
```hcl
variable "store_path" {
  type    = string
  default = "/run/current-system"
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
}
```

With the association in place, all that is left is creating the instances
themselves. We need to attach the `ReadCache` IAM policy to the instances so
they can read from the cache.
```hcl
resource "aws_iam_role_policy_attachment" "webserver" {
  for_each = {
    "ssm"        = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
    "read_cache" = aws_iam_policy.read_cache.arn
  }
  role       = aws_iam_role.webserver.name
  policy_arn = each.value
}

resource "aws_instance" "webserver" {
  count              = 2
  ami                = data.aws_ami.nixos.id
  instance_type      = "t3a.nano"
  iam_instance_profile = aws_iam_instance_profile.webserver.name
  tags = {
    Role = "webserver"
  }
}
```

If you use [Default Host Management Configuration](https://docs.aws.amazon.com/systems-manager/latest/userguide/fleet-manager-default-host-management-configuration.html) you need to attach the IAM policy to the IAM role that is configured there instead of the instance profile. For example like this:

```hcl
resource "aws_iam_role_policy_attachment" "dhmc" {
  role       = "AWS-QuickSetup-SSM-DefaultEC2MgmtRole-eu-central-1"
  policy_arn = aws_iam_policy.read_cache.arn
}
```

And that's all! You've succefully deployed a NixOS configuration to a set of instances
using SSM and a self-hosted binary cache. A next step would be to put this all in a pipeline.


<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.81.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_nixos_deploy_document"></a> [nixos\_deploy\_document](#module\_nixos\_deploy\_document) | ./../.. | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_iam_instance_profile.webserver](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_instance_profile) | resource |
| [aws_iam_policy.read_cache](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.webserver](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.webserver](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_instance.webserver](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance) | resource |
| [aws_s3_bucket.cache](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_ssm_association.webserver](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_association) | resource |
| [aws_ami.nixos_arm64](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_public_key"></a> [public\_key](#input\_public\_key) | The public key used to sign store paths pushed to store\_uri | `string` | n/a | yes |
| <a name="input_store_path"></a> [store\_path](#input\_store\_path) | The nix store path to substitute on the machine. Must be pushed to outputs.store\_uri and signed with var.public\_key beforehand. | `string` | `"/run/current-system"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_store_uri"></a> [store\_uri](#output\_store\_uri) | the store URI for the S3 binary cache |
<!-- END_TF_DOCS -->