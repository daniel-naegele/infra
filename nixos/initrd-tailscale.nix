{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.tailscale;
in
{
  boot.initrd = {
    secrets = {
      "/etc/ts/auth_key" = config.sops.secrets.tailscale_preauth.path;
    };
    systemd.packages = [ cfg.package ];
    availableKernelModules = [
      "tun"
      "nft_chain_nat"
    ];

    systemd.services.tailscaled-initrd = {
      unitConfig = {
        DefaultDependencies = "no";
      };
      wantedBy = [ "initrd.target" ];
      before = [
        "cryptsetup-pre.target"
      ];
      serviceConfig = {
        Environment = [
          "PORT=${toString cfg.port}"
          ''"FLAGS=--tun ${lib.escapeShellArg cfg.interfaceName}"''
        ];
        RuntimeDirectory = "tailscale-initrd";
        Type = "notify";
        ExecStart = ''
          ${pkgs.tailscale}/bin/tailscaled \
            --state=mem:ts \
            --socket /run/tailscale-initrd/tailscaled.sock
        '';
      };
    };

    systemd.network.networks."50-tailscale" = {
      matchConfig = {
        Name = cfg.interfaceName;
      };
      linkConfig = {
        Unmanaged = true;
        ActivationPolicy = "manual";
      };
    };

    systemd.extraBin.ping = "${pkgs.iputils}/bin/ping";

    /*
      systemd.additionalUpstreamUnits = ["systemd-resolved.service"];
      systemd.users.systemd-resolve = {};
      systemd.groups.systemd-resolve = {};
      systemd.contents."/etc/systemd/resolved.conf".source = config.environment.etc."systemd/resolved.conf".source;
      systemd.storePaths = ["${config.boot.initrd.systemd.package}/lib/systemd/systemd-resolved"];
      systemd.services.systemd-resolved = {
        wantedBy = ["initrd.target"];
        serviceConfig.ExecStartPre = "-+/bin/ln -s /run/systemd/resolve/resolv.conf /etc/resolv.conf";
        };
    */

    # Create a oneshot to autoconnect on rebuild/switch
    systemd.services.tailscale-autoconnect = {
      description = "Automatic connection to Tailscale";
      unitConfig = {
        DefaultDependencies = "no";
      };
      before = [
        "cryptsetup-pre.target"
      ];
      after = [
        "network-pre.target"
        "tailscaled-initrd.service"
      ];
      wants = [
        "network-pre.target"
        "tailscaled-initrd.service"
        "cryptsetup-pre.target"
      ];
      wantedBy = [ "initrd.target" ];

      serviceConfig = {
        Type = "oneshot";
        Restart = "on-failure";
      };

      # have the job run this shell script
      script = with pkgs; ''
        # wait for tailscaled to settle
        sleep 5

        # otherwise authenticate with tailscale using the key from secrets
        ${tailscale}/bin/tailscale \
        --socket /run/tailscale-initrd/tailscaled.sock up \
        --auth-key file:/etc/ts/auth_key \
        --login-server https://ts.men.sh \
        --hostname initrd-${config.networking.hostName}
      '';
    };
  };
}
