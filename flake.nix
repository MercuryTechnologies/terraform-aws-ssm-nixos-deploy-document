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
      checks = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
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
                entry = "${pkgs.terraform-docs}/bin/terraform-docs markdown --recursive --recursive-path examples --output-file README.md .";
                files = "(README.md|\\.tf)$";
                pass_filenames = false;
                language = "system";

              };
              nixfmt-rfc-style.enable = true;
            };
          };
        }
      );

      devShells = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          default = pkgs.mkShell {
            inherit (self.checks.${system}.pre-commit-check) shellHook;
            packages = [
              pkgs.opentofu
              pkgs.tflint
              pkgs.terraform-docs
              pkgs.awscli2
              pkgs.nixfmt-rfc-style
            ];
          };
        }
      );

    };
}
