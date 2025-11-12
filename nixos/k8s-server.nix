{
  config,
  lib,
  pkgs,
  ...
}:
{
  services.k3s = {
    enable = true;
    role = "server";
    tokenFile = config.sops.secrets.k3s_token.path;
    clusterInit = true;
    extraFlags = [
      "--tls-san=controlplane.men.sh"
      #  "--vpn-auth-file=$PATH_TO_FILE"
      #  "--node-external-ip=<TailscaleIPOfServerNode>"
    ];
    #serverAddr = "https://controlplane.men.sh:6443";
  };

  networking.firewall.allowedTCPPorts = [
    6443 # k3s: required so that pods can reach the API server (running on port 6443 by default)
    #2379 # k3s, etcd clients: required if using a "High Availability Embedded etcd" configuration
    #2380 # k3s, etcd peers: required if using a "High Availability Embedded etcd" configuration
  ];

  networking.firewall.allowedUDPPorts = [
    # 8472 # k3s, flannel: required if using multi-node for inter-node networking
  ];
}
