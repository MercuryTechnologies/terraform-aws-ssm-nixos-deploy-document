# Deploying a flake ref

> [!NOTE]
> This example assumes that [Default Host Management Configuration](https://docs.aws.amazon.com/systems-manager/latest/userguide/fleet-manager-default-host-management-configuration.html) is **not** used.  If you use DHMC, you need to attach the IAM poliy to the IAM role that is configured there instead of the instance profile.

In this example, we will deploy a flake ref to a set of EC2 instances. The flake will be evaluated and built on the instances themselves.

First we define some instances:

```hcl
resource "aws_instance" "webserver" {
  count         = 2
  ami           = data.aws_ami.nixos.id
  instance_type = "t3a.small"
  tags = {
    Role = "webserver"
  }
}
```

Then we can associate the SSM document with the instances based
on their tags.

In this case we want to deploy the flake ref `github:arianvp/terraform-aws-ssm-nixos-deploy-document?dir=examples/ec2_instance_flakeref#nixosConfigurations.webserver.config.system.build.toplevel`.


```hcl
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
```

This setup works but is not ideal. It doesn't work on instances with limited memory as nix evaluation and building is happening
on the instance and you will require sufficient CPU and memory for that to succeed. The instance also needs access to the public internet to fetch the flake and substitute the dependencies.

In the next example we will show how you can deploy a pre-built NixOS configuration pushed to an S3 cache.

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

| Name | Source | Version |
|------|--------|---------|
| <a name="module_nixos_deploy_document"></a> [nixos\_deploy\_document](#module\_nixos\_deploy\_document) | ./../.. | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_iam_instance_profile.webserver](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_instance_profile) | resource |
| [aws_iam_role.webserver](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.ssm](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_instance.webserver](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance) | resource |
| [aws_ssm_association.webserver](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_association) | resource |
| [aws_ami.nixos](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |

## Inputs

No inputs.

## Outputs

No outputs.
<!-- END_TF_DOCS -->