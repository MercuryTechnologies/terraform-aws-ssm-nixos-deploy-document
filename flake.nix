{
  description = "Terraform module for deploying to NixOS using SSM";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    pre-commit-hooks.url = "github:cachix/git-hooks.nix";
  };

  outputs =
    {
      self,
      nixpkgs,
      pre-commit-hooks,
      ...
    }:
    let
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];

      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
    in
    {
      checks = forAllSystems (system: {
        pre-commit-check = pre-commit-hooks.lib.${system}.run {
          src = ./.;
          hooks = {
            shellcheck.enable = true;
            actionlint.enable = true;
            tflint.enable = true;
            terraform-format.enable = true;
            # terraform-validate.enable = true;

            terraform-docs = {
              enable = true;
              name = "terraform-docs";
              entry = "terraform-docs markdown --recursive --recursive-path examples --output-file README.md .";
              files = "(README.md|\\.tf)$";
              pass_filenames = false;
              language = "system";

            };
            nixfmt-rfc-style.enable = true;
          };
        };
      });

      devShells = forAllSystems (system: {
        default =
          with nixpkgs.legacyPackages.${system};
          mkShell {
            inherit (self.checks.${system}.pre-commit-check) shellHook;
            packages = [
              opentofu
              tflint
              terraform-docs
              awscli2
            ];
          };
      });

    };
}
