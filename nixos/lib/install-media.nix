# Build NixOS installation media (ISO and kexec images)
#
# Usage in flake.nix:
#   installMedia = import ./nixos/lib/install-media.nix {
#     inherit nixpkgs;
#     inherit (nixpkgs) lib;
#   };
#
#   packages.x86_64-linux = {
#     iso = installMedia.buildIso { modules = [ ./nixos/installer-image.nix ]; };
#     kexec = installMedia.buildKexec { modules = [ ./nixos/installer-image.nix ]; };
#   };

{ nixpkgs, lib }:

let
  system = "x86_64-linux";
  pkgs = import nixpkgs { inherit system; };

  # Common installer modules
  baseInstallerModules = [
    "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
  ];

  # Build a NixOS ISO image
  buildIso = { modules ? [ ] }:
    (lib.nixosSystem {
      inherit system;
      modules = baseInstallerModules ++ modules;
    }).config.system.build.isoImage;

  # Build a kexec UKI for nixos-anywhere (Secure Boot compatible)
  buildKexec = { modules ? [ ] }:
    let
      configuration = lib.nixosSystem {
        inherit system;
        modules = [
          "${nixpkgs}/nixos/modules/installer/netboot/netboot-minimal.nix"
        ] ++ modules;
      };
    in
    pkgs.runCommand "nixos-kexec-uki" {
      nativeBuildInputs = [ pkgs.systemdUkify ];
    } ''
      mkdir -p $out
      ukify build \
        --linux=${configuration.config.system.build.kernel}/${configuration.config.system.boot.loader.kernelFile} \
        --initrd=${configuration.config.system.build.initialRamdisk}/${configuration.config.system.boot.loader.initrdFile} \
        --cmdline="init=${configuration.config.system.build.toplevel}/init ${toString configuration.config.boot.kernelParams}" \
        --os-release=${configuration.config.system.build.etc}/etc/os-release \
        --output=$out/nixos-kexec.efi
    '';

in
{
  inherit buildIso buildKexec;
}
