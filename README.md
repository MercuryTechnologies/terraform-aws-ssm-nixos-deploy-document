# AWS SSM NixOS Deploy Document

This module creates an AWS SSM document that can be used to deploy NixOS
configurations to EC2 instances.

More info about how Mercury is using this module in production can be found in
this NixCon talk:
[![NixCon2024 Scalable and secure NixOS deploys on AWS](https://img.youtube.com/vi/Ee4JN3Fp17o/0.jpg)](https://www.youtube.com/watch?v=Ee4JN3Fp17o)

## Example usage

See [examples](./examples) for complete  examples with step by step explanations.

```hcl
module "nixos_deploy_document" {
  source = "github.com/MercuryTechnologies/terraform-aws-ssm-nixos-deploy-document"
  nix_config = <<-EOF
    extra-substituters        = s3://our-internal-cache
    extra-trusted-public-keys = our-internal-cache-1:GJSsQKjGT+cXUTmx5y5BEUGfPf25dMkZhpJZtVNklTk=
  EOF
}
```

### Using `aws ssm send-command`

You can trigger deploys from the command line using `aws ssm send-command`:

```shell
out_path=$(nix build --print-out-paths '.#nixosConfigurations.webserver.config.system.build.toplevel')
nix copy --to "s3://our-internal-cache&secret-key=./key.sec" "$out_path"
aws ssm send-command \
  --document-name NixOS-Deploy \
  --targets 'Key=tag:Role,Values=webserver' 'Key=tag:Env,Values=production' \
  --parameters "installable=$out_path"
```


### Deploying a flake ref using an SSM State Manager association

See [examples/flakeref](./examples/flakeref) for a complete example.

```hcl
resource "aws_ssm_association" {
  name = module.nixos_deploy_document.id
  targets {
    key    = "tag:Role"
    values = ["webserver"]
  }
  parameters = {
    installable = "github:MercuryTechnologies/nixos-configs#nixosConfigurations.webserver.config.system.build.toplevel"
  }
}
```

### Deploying a nix store path an SSM State Manager association


See [examples/flakeref](./examples/nix-store-path) for a complete example.

```hcl
resource "aws_ssm_association" {
  name = module.nixos_deploy_document.id
  targets {
    key    = "tag:Role"
    values = ["webserver"]
  }
  parameters = {
    installable = "/nix/store/2hf8wy165v5n5xzajbv13bqrlr70bh6y-nixos-system-webserver-24.11.20241216.3945713"
  }
}
```

## Default values and parameters

All variables to the module are also re-exposed as parameters in the SSM
document. This means you can set parameter defaults globally, but also override
them using parameters on a case per case basis.

For example, we can define that by default deploys are always dry runs, and use
our S3 bucket as a binary cache, but only enable deploys on specific
associations by overriding the `action` parameter in the association.

```hcl
module "nixos_deploy_document" {
  source = "github.com/mercury-technologies/terraform-aws-ssm-nixos-deploy-document"

  nix_config   = <<-EOF
    substituters = "s3://our-internal-cache"
  EOF
  action       = "dry-activate" # By default deploys are no-ops
}

resource "aws_ssm_association" "assoc1" {
  name = module.nixos_deploy_document.id
  targets {
    key    = "tag:Role"
    values = ["webserver"]
  }
  parameters = {
    action      = "switch"
    installable = var.nix_store_path
  }
}

resource "aws_ssm_association" "assoc2" {
  name = module.nixos_deploy_document.id
  targets {
    key    = "tag:Role"
    values = ["dbserver"]
  }
  parameters = {
    action      = "reboot"
    installable = var.nix_store_path
  }
}
```

## IAM Permissions

> [!NOTE]
> When [Default Host Management Configuration](https://docs.aws.amazon.com/systems-manager/latest/userguide/fleet-manager-default-host-management-configuration.html)
> is used, you need to attach any IAM policies that give access to S3 buckets
> and such mentioned in the document to the IAM role that was configured there.
> Else, the permissions need to be attached to the instance profile of the
> instances that are targeted by the SSM Document.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.46 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.81.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_ssm_document.nixos_deploy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_document) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_action"></a> [action](#input\_action) | The deploy action to perform. One of switch, test, boot, reboot or dry-activate | `string` | `"switch"` | no |
| <a name="input_installable"></a> [installable](#input\_installable) | A nix store path to substitute or a flake output attribute to build. See https://nix.dev/manual/nix/latest/command-ref/new-cli/nix#installables | `string` | `"/run/current-system"` | no |
| <a name="input_name"></a> [name](#input\_name) | The name of the SSM document | `string` | `"NixOS-Deploy"` | no |
| <a name="input_nix_config"></a> [nix\_config](#input\_nix\_config) | Nix configuration to use. See https://nix.dev/manual/nix/latest/command-ref/conf-file for available options. Useful to set extra-substituters and extra-trusted-public-keys when using your own binary cache. | `string` | `""` | no |
| <a name="input_profile"></a> [profile](#input\_profile) | The profile to operate on. See https://nix.dev/manual/nix/latest/command-ref/new-cli/nix3-build#opt-profile | `string` | `"/nix/var/nix/profiles/system"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | A mapping of tags to assign to the document | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_arn"></a> [arn](#output\_arn) | The Amazon Resource Name (ARN) of the document |
| <a name="output_created_date"></a> [created\_date](#output\_created\_date) | The date the document was created |
| <a name="output_default_version"></a> [default\_version](#output\_default\_version) | The default version of the document |
| <a name="output_description"></a> [description](#output\_description) | The description of the document |
| <a name="output_document_version"></a> [document\_version](#output\_document\_version) | The document version |
| <a name="output_hash_type"></a> [hash\_type](#output\_hash\_type) | The hash type of the document. Valid values: `Sha256`, `Sha1` |
| <a name="output_id"></a> [id](#output\_id) | The name of the document |
| <a name="output_latest_version"></a> [latest\_version](#output\_latest\_version) | The latest version of the document |
| <a name="output_parameter"></a> [parameter](#output\_parameter) | The parameters of the document |
| <a name="output_platform_types"></a> [platform\_types](#output\_platform\_types) | The list of operating systems compatible with the document |
| <a name="output_schema_version"></a> [schema\_version](#output\_schema\_version) | The schema version of the document |
| <a name="output_status"></a> [status](#output\_status) | The status of the document |
| <a name="output_tags_all"></a> [tags\_all](#output\_tags\_all) | A map of tags assigned to the resource, including those inherited from the provider |
<!-- END_TF_DOCS -->