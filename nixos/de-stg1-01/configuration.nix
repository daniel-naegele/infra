# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{
  lib,
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

  sops.defaultSopsFile = ../../secrets/machines/de-stg1-01.yaml;

  services.k3s.extraFlags = [
    "--node-ip=100.64.0.2"
    "--flannel-iface=tun0"
  ];

  services.easytier.instances.overlay.settings = {
    ipv4 = "100.64.0.2";
  };

  networking = {
    hostId = "945ece5e";
    defaultGateway6 = {
      address = "fe80::1";
      interface = "enp5s0";
    };
  };

  boot.initrd.systemd.network.networks."10-lan" = {
    linkConfig.MACAddress = "a8:a1:59:08:2c:bf";
    matchConfig.Name = lib.mkForce "enp5s0";
  };

  system.stateVersion = "25.11";
}
