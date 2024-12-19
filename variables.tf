variable "name" {
  description = "The name of the SSM document"
  type        = string
  default     = "NixOS-Deploy"
}

variable "action" {
  description = "The deploy action to perform. One of switch, test, boot, reboot or dry-activate"
  type        = string
  default     = "switch"
}

variable "profile" {
  description = "The profile to operate on. See https://nix.dev/manual/nix/latest/command-ref/new-cli/nix3-build#opt-profile"
  type        = string
  default     = "/nix/var/nix/profiles/system"
}

variable "installable" {
  description = "A nix store path to substitute or a flake output attribute to build. See https://nix.dev/manual/nix/latest/command-ref/new-cli/nix#installables"
  type        = string
  default     = "/run/current-system"
}

variable "nix_config" {
  description = "Nix configuration to use. See https://nix.dev/manual/nix/latest/command-ref/conf-file for available options. Useful to set extra-substituters and extra-trusted-public-keys when using your own binary cache."
  type        = string
  default     = ""
}

variable "tags" {
  description = "A mapping of tags to assign to the document"
  type        = map(string)
  default     = {}
}