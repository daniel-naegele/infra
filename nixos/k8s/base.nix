{
  config,
  lib,
  ...
}:
{
  services.k3s = {
    enable = true;
    tokenFile = config.sops.secrets.k3s_token.path;

    serverAddr = "https://controlplane.men.sh:6443";
  };

  networking.firewall.interfaces."tailscale0".allowedUDPPorts = [
    8472 # k3s, flannel: required if using multi-node for inter-node networking
  ];

  systemd.services.containerd.serviceConfig = {
    LimitNOFILE = lib.mkForce null;
  };
}
