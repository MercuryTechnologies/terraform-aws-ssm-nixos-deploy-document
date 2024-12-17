{
  description = "Terraform module for deploying to NixOS using SSM";

  inputs = { nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable"; };

  outputs = { nixpkgs, ... }: {

    devShells = nixpkgs.lib.genAttrs [ "aarch64-darwin" "x86_64-linux" ]
      (system: {
        default = with nixpkgs.legacyPackages.${system};
          mkShell { packages = [ opentofu terraform-docs awscli2 ]; };
      });

  };
}
