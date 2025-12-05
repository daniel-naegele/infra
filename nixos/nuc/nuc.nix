# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{
  ...
}:
{
  imports = [
    ./disk-config.nix
    ./hardware-configuration.nix
    ../configuration.nix
    ../k8s/server.nix
    ../secure-boot.nix
  ];

  sops.defaultSopsFile = ../../secrets/nuc.yaml;

  networking.hostId = "2054d6cd";
  networking.wireless.enable = true;
  networking.wireless.userControlled.enable = true;

}
