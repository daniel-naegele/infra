{
  config,
  ...
}:
{
  services.k3s = {
    enable = true;
    tokenFile = config.sops.secrets.k3s_token.path;
    extraFlags = [
      "--tls-san=controlplane.men.sh"
      "--disable=local-storage"
    ];
    serverAddr = "https://controlplane.men.sh:6443";
  };

  networking.firewall.interfaces."tailscale0".allowedUDPPorts = [
    8472 # k3s, flannel: required if using multi-node for inter-node networking
  ];
}
