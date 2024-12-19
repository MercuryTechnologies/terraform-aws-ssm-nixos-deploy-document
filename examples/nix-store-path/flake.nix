{
  description = "An example flake containing a NixOS configuration";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-24.11";
  };
  outputs =
    { nixpkgs, ... }:
    {
      nixosConfigurations.webserver = nixpkgs.lib.nixosSystem {
        modules = [
          (
            { modulesPath, ... }:
            {
              imports = [ "${modulesPath}/virtualisation/amazon-image.nix" ];
              system.name = "webserver";
              services.nginx.enable = true;
              nixpkgs.hostPlatform = "x86_64-linux";
              system.stateVersion = "24.11";
            }
          )
        ];
      };
    };
}
