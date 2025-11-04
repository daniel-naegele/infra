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
    ./initrd-tailscale.nix
  ];

  boot.kernelParams = [ "ip=dhcp" ];
  boot.kernelModules = [
    "rbd"
    "e1000e"
    "iwlwifi"
    "nft-expr-counter"
  ];
  boot.supportedFilesystems = [ "zfs" ];
  boot.zfs.requestEncryptionCredentials = true;

  boot.loader = {
    systemd-boot.enable = lib.mkForce false;
    efi.canTouchEfiVariables = true;
  };

  boot.lanzaboote = {
    enable = true;
    pkiBundle = "/var/lib/sbctl";
  };

  sops.secrets = {
    tailscale_preauth = {
      mode = "0600";
    };
    init_host_key = {
      mode = "0600";
    };
  };

  boot.initrd = {
    availableKernelModules = [ "igc" ];
    kernelModules = [
      "e1000e"
      "iwlwifi"
      "tpm_crb"
    ];
    secrets = {
      "/etc/secrets/ssh_host_ed_25519_key" = /run/secrets/init_host_key;
      "/etc/secrets/ts_auth_key" = /run/secrets/tailscale_preauth;
    };

    systemd = {
      initrdBin = with pkgs; [
        iptables
        iproute2
        tailscale
        gnutar
      ];
      enable = true;
      emergencyAccess = "$6$Q9squq6JffqBotsn$G2oqvxWg2PS6tJFzplu/ycjmFzNRwF.uX5EPQJI12wQhs75lFYSpGbf/EG6L7CdOtfvHUiBMX.t4y0vXYTlbT.";

      network = {
        enable = true;
        networks."10-lan" = {
          enable = true;
          matchConfig = {
            Name = "eth0"; # Matches the network interface by name
          };
          networkConfig = {
            DHCP = "yes";
          };
        };
        networks."20-wifi" = {
          enable = true;
          matchConfig = {
            Name = "wlan0"; # Matches the network interface by name
          };
          networkConfig = {
            DHCP = "yes";
          };
        };
      };

      tpm2.enable = true;
      /*
        services.unlock = {
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
        };
      */

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
        hostKeys = [ /run/secrets/init_host_key ];
        # public ssh key used for login
        authorizedKeyFiles = [
          ../secrets/authorized_keys
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
