{
  modulesPath,
  inputs,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    (modulesPath + "/profiles/qemu-guest.nix")
    ./initrd.nix
  ];

  boot.kernelParams = [ "ip=dhcp" ];
  boot.kernelModules = [
    "rbd"
    "nbd"
    "e1000e"
    "iwlwifi"
    "nft-expr-counter"
  ];
  boot.supportedFilesystems = [ "zfs" ];
  boot.zfs.requestEncryptionCredentials = true;

  boot.loader = {
    systemd-boot.enable = false;
    efi.canTouchEfiVariables = true;
  };

  sops.secrets = {
    tailscale_preauth = {
      mode = "0600";
    };
    init_host_key = {
      mode = "0600";
    };
  };

  networking.enableIPv6 = true;

  programs.zsh.enable = true;

  environment.systemPackages = with pkgs; [
    btop
    cachix
    clevis
    git
    htop
    iproute2
    openssh
    vim
    wget
    inputs.unstable.legacyPackages.${pkgs.system}.sbctl
    tailscale
  ];

  security.sudo.wheelNeedsPassword = false;
  users.users.k8s = {
    isSystemUser = true;
    group = "k8s";
  };

  users.users.nixos = {
    shell = pkgs.zsh;
    isNormalUser = true;
    group = "nixos";
    extraGroups = [
      "wheel"
      "sudo"
    ];
    openssh.authorizedKeys.keyFiles = [ ../secrets/authorized_keys ];
  };
  nix.settings.trusted-users = [ "nixos" ];

  users.groups.k8s = { };
  users.groups.nixos = { };

  services.openssh = {

    enable = true;
    # require public key authentication for better security
    settings.PasswordAuthentication = false;
    settings.KbdInteractiveAuthentication = false;
    settings.PermitRootLogin = "no";
  };

  services.zfs.autoScrub.enable = true;

  sops.secrets.k3s_token = {
    format = "binary";
    # can be also set per secret
    sopsFile = ../secrets/k3s.bin;
  };

  system.stateVersion = "24.11";
}
