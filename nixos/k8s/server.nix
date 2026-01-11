{
  pkgs,
  config,
  lib,
  ...
}:
{
  imports = [
    ./base.nix
  ];

  sops.secrets.public_ip_erfurt = {
    format = "binary";
    sopsFile = ../secrets/shared/public-ip-erfurt.key;
  };

  services.k3s = {
    role = "server";
  };

  networking.firewall.allowedTCPPorts = [
    6443 # k3s: required so that pods can reach the API server (running on port 6443 by default)
  ];

  networking.firewall.interfaces."tailscale0".allowedTCPPorts = [
    2379 # k3s, etcd clients: required if using a "High Availability Embedded etcd" configuration
    2380 # k3s, etcd peers: required if using a "High Availability Embedded etcd" configuration
  ];

  networking.wireguard.interfaces.controlplane-public = {
    ips = [ "84.19.175.168/32" ]; # provider-assigned
    privateKeyFile = config.sops.secrets.public_ip_erfurt.path;
    peers = [
      {
        publicKey = "oipxxacPM/rfBT2KeRj8p9zoELD8EE1Jh51ZSK5AsCQ=";
        allowedIPs = [
          "84.19.175.168/32"
        ];
        endpoint = "vpn93.prd.erfurt.ovpn.com:9930";
        persistentKeepalive = 25;
      }
    ];
  };

  systemd.services."wg-quick@controlplane-public" = {
    wantedBy = lib.mkForce [ ];
    unitConfig = {
      BindsTo = [ "goonector-watchdog.service" ];
      After = [ "goonector-watchdog.service" ];
    };
  };

  networking.firewall.nftables.extraRules = ''
    table inet filter {
      chain input {
        type filter hook input priority 0;
        iif "controlplane-public" tcp dport 6443 accept
        iif "controlplane-public" drop
      }
      chain output {
        type filter hook output priority 0;
        oif "controlplane-public" tcp sport 6443 accept
        oif "controlplane-public" drop
      }
    }
  '';

  systemd.tmpfiles.rules = [
    "d /run/goonector 0755 root root -"
  ];

  systemd.services.goonector-watchdog = {
    description = "Fence WireGuard if goonector heartbeat disappears";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "simple";
      Restart = "always";
      RestartSec = 2;
      ExecStart = pkgs.writeShellScript "goonector-watchdog" ''
        set -euo pipefail

        HEARTBEAT=/run/goonector/leader

        while true; do
          if [ ! -f "$HEARTBEAT" ]; then
            echo "No heartbeat; stopping wg-public"
            systemctl stop wg-quick@wg-public.service || true
          fi
          sleep 3
        done
      '';
    };
  };

}
