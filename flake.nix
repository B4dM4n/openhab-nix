{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, ... } @ inputs:
    let
      inherit (builtins) intersectAttrs;
      inherit (inputs.nixpkgs) lib;
    in
    with lib;
    let
      systems = [
        "aarch64-linux"
        "armv6l-linux"
        "armv7l-linux"
        "i686-linux"
        "x86_64-linux"
      ];

      forAllSystems = fn: genAttrs systems (system:
        fn (intersectAttrs (functionArgs fn) {
          inherit system;
          nixpkgs = inputs.nixpkgs.legacyPackages.${system};
        }));
    in
    {
      nixosModule = import ./module.nix { inherit self; };

      packages = forAllSystems ({ system, nixpkgs }: rec {
        openhab = nixpkgs.callPackage ./pkg.nix { };

        openhabWithAddons = openhab.override { withAddons = true; };
      });

      checks = forAllSystems ({ system, nixpkgs }: {
        openhab = nixpkgs.nixosTest ({ pkgs, ... }: {
          name = "openhab";

          machine = { ... }: {
            imports = [
              self.nixosModule
            ];
            config = {
              services.openhab = {
                enable = true;
              };
            };
          };

          testScript = ''
            start_all()

            machine.wait_for_unit("openhab.service")
          '';
        });
      });
    };
}
