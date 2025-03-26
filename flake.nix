{
  description = "Flake for own infra monorepo";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    flake-utils.lib.eachSystem [ "x86_64-linux" "aarch64-linux" ] (
      system:
      with nixpkgs.lib;
      let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
          config.allowUnsupportedSystem = true;
        };

        mkNixOsConfiguration =
          hostname:
          {
            system,
            config,
          }:
          nameValuePair hostname (nixosSystem {
            inherit system;
            modules = [
              disko.nixosModules.disko
              (
                {
                  inputs,
                  hostname,
                  pkgs,
                  ...
                }:
                {
                  # Set the hostname to the name of the configuration being applied (since the
                  # configuration being applied is determined by the hostname).
                  networking.hostName = hostname;

                  # Use the nixpkgs from the flake.
                  nixpkgs.pkgs = pkgsBySystem.${system};

                  # For compatibility with nix-shell, nix-build, etc.
                  # See also the setting of NIX_PATH in the home-manager host config
                  environment.etc.nixpkgs.source = inputs.nixpkgs;
                  environment.etc.unstable.source = inputs.unstable;
                  nix.nixPath = [
                    "nixpkgs=/etc/nixpkgs"
                    "unstable=/etc/unstable"
                  ];

                  nix = {
                    # Don't rely on the configuration to enable a flake-compatible version of Nix.
                    # package = pkgs.nixFlakes;
                    extraOptions = "experimental-features = nix-command flakes";
                    # Re-expose self, nixpkgs and unstable as flakes.
                    registry = {
                      self.flake = inputs.self;
                      nixpkgs = {
                        from = {
                          id = "nixpkgs";
                          type = "indirect";
                        };
                        flake = inputs.nixpkgs;
                      };
                      unstable = {
                        from = {
                          id = "unstable";
                          type = "indirect";
                        };
                        flake = inputs.unstable;
                      };
                    };
                    settings = {
                      auto-optimise-store = true;
                    };
                  };
                }
              )
              (import config)
            ];
            specialArgs = {
              inherit hostname inputs;
              unstable = unstableBySystem."${system}";
            };
          });
      in
      {
        devShells.default = import ./shell.nix { inherit pkgs; };
        formatter = pkgs.nixfmt-rfc-style;
        nixosHostConfigurations = mapAttrs' mkNixOsConfiguration {
          de-man-backup = {
            system = "x86_64-linux";
            config = ./nixos/nuc.nix;
          };
          Daniel-PC = {
            system = "x86_64-linux";
            config = ./nixos/wsl.nix;
          };
        };
      }
    );
}
