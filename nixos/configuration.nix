{
  modulesPath,
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    (modulesPath + "/profiles/qemu-guest.nix")
    #./initrd-tailscale.nix
  ];

  boot.kernelParams = [ "ip=dhcp" ];
  boot.kernelModules = [ "ceph" "r8169" "cdc_ether" ];
  boot.supportedFilesystems = [ "zfs" ];
  boot.zfs.requestEncryptionCredentials = true;

  boot.loader =  {
    grub = {
      enable = true;
      zfsSupport = true;
      efiSupport = true;
      efiInstallAsRemovable = true;
      mirroredBoots = [
        { devices = [ "nodev"]; path = "/boot"; }
      ];
    };
  };

  boot.initrd = {
    availableKernelModules = [ "igc" ];
    kernelModules = [ "r8169" "cdc_ether" "tpm_crb" ];

    systemd = {
      enable = true;
      emergencyAccess = "$6$Q9squq6JffqBotsn$G2oqvxWg2PS6tJFzplu/ycjmFzNRwF.uX5EPQJI12wQhs75lFYSpGbf/EG6L7CdOtfvHUiBMX.t4y0vXYTlbT.";

      network = {
        enable = true;
        networks.enp0s25 = {
          enable = true;
          name = "enp0s25";
          DHCP = "yes";
        };
      };

      tpm2.enable = true;
      /* services.unlock = {
        unitConfig = {
          Type = "simple";
        };
        path = with pkgs; [
          clevis
          curl
        ];
        wantedBy = [ "initrd.target" ];
        script = ''
          zpool import -a;
          echo $(curl -s "http://clevis.local/the-encrypted-keyfile" | clevis decrypt) | zfs load-key -a && killall zfs
        '';
        };*/

    };

    network = {
      enable = true;
      ssh = {
         enable = true;
         # To prevent ssh clients from freaking out because a different host key is used,
         # a different port for ssh is useful (assuming the same host has also a regular sshd running)
         port = 2222;
         # hostKeys paths must be unquoted strings, otherwise you'll run into issues with boot.initrd.secrets
         # the keys are copied to initrd from the path specified; multiple keys can be set
         # you can generate any number of host keys using
         # `ssh-keygen -t ed25519 -N "" -f /path/to/ssh_host_ed25519_key`
         hostKeys = [ ../id ];
         # public ssh key used for login
         authorizedKeys = [
           "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAII4FqdxzINQfwBVADBQPKO56ClKP3ToxvGALzjzGOTlD daniel@DN-Laptop"
         ];
       };
    };

  };

  programs.zsh.enable = true;

  environment.systemPackages = with pkgs; [
    btop
    cachix
    clevis
    git
    htop
    openssh
    vim
    wget
    sbctl
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
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAII4FqdxzINQfwBVADBQPKO56ClKP3ToxvGALzjzGOTlD daniel@DN-Laptop"
    ];
  };

  users.groups.k8s =  {};
  users.groups.nixos = {};

  services.openssh = {

    enable = true;
    # require public key authentication for better security
    settings.PasswordAuthentication = false;
    settings.KbdInteractiveAuthentication = false;
    settings.PermitRootLogin = "no";
  };

  services.zfs.autoScrub.enable = true;

  sops.secrets.k3s_token = {
    format = "yaml";
    # can be also set per secret
    sopsFile = ../secrets/k3s.yaml;
  };

  system.stateVersion = "24.11";
}
