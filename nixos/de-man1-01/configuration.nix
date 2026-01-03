# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{
  lib,
  ...
}:
{
  imports = [
    ./disk-config.nix
    ./hardware-configuration.nix
    ../configuration.nix
    #    ../k8s/bootstrap.nix
    ../secure-boot.nix
  ];

  sops.defaultSopsFile = ../../secrets/machines/de-man1-01.yaml;

  networking = {
    hostId = "2054d6cd";
    defaultGateway6 = {
      address = "fe80::1";
      interface = "enp0s25";
    };

    wireless.enable = true;
    wireless.userControlled.enable = true;
  };

  boot.initrd.systemd.network.networks."10-lan" = {
    linkConfig.MACAddress = "b8:ae:ed:75:ea:57";
    matchConfig.Name = lib.mkForce "enp0s25";
  };

  system.stateVersion = "25.11";
}
