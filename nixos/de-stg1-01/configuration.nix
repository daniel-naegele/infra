# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{
  ...
}:
{
  imports = [
    # Include the results of the hardware scan.
    ./disk-config.nix
    ./hardware-configuration.nix
    ../configuration.nix
    ../k8s/agent.nix
    ../secure-boot.nix
  ];

  sops.defaultSopsFile = ../../secrets/de-stg1-01.yaml;

  networking = {
    hostId = "f4f9b7d5";
    defaultGateway6 = {
      address = "fe80::1";
      interface = "enp1s0";
    };
  };

  system.stateVersion = "25.05";
}
