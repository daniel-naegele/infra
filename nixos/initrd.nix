{
  pkgs,
  ...
}:
{
  imports = [
    ./initrd-tailscale.nix
  ];

  boot.initrd = {
    availableKernelModules = [ "igc" ];
    kernelModules = [
      "igb"
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
}
