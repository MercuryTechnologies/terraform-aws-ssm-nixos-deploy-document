resource "aws_ssm_document" "nixos_deploy" {
  name          = var.name
  document_type = "Command"
  tags          = var.tags
  content = jsonencode({
    schemaVersion = "2.2"
    description   = "Deploy to NixOS"
    parameters = {
      action = {
        type          = "String"
        description   = "The deploy action to perform. One of switch, test, boot, reboot or dry-activate"
        allowedValues = ["switch", "test", "boot", "reboot", "dry-activate"]
        default       = var.action
      }
      profile = {
        type        = "String"
        description = "The profile to operate on. See https://nix.dev/manual/nix/latest/command-ref/new-cli/nix3-build#opt-profile"
        default     = var.profile
      }
      installable = {
        type        = "String"
        description = "A nix store path to substitute or a flake output attribute to build. See https://nix.dev/manual/nix/latest/command-ref/new-cli/nix#installables"
        default     = var.installable
      }
      nixConfig = {
        type        = "String"
        description = "Nix configuration to use. See https://nix.dev/manual/nix/latest/command-ref/conf-file for available options. Useful to set extra-substituters and extra-trusted-public-keys when using your own binary cache."
        default     = var.nix_config
      }
    }
    mainSteps = [
      {
        action = "aws:runShellScript"
        name   = "deploy"
        inputs = { runCommand = [file("${path.module}/deploy.sh")] }
      }
    ]
  })
}