{
  pkgs,
  config,
  ...
}:

let
  meshId = "mesh0"; # Unique mesh network ID
  bootstrapServers = [ "udp://de-fsn1-01.men.sh:11010" ]; # Self-hosted discovery server
in
{
  sops.secrets.easytier_secret = {
    format = "binary";
    # can be also set per secret
    sopsFile = ../secrets/shared/easytier.key;
  };

  services.easytier = {
    enable = true;
    #allowSystemForward = true;
    instances.overlay = {
      environmentFiles = [
        config.sops.secrets.easytier_secret.path
      ];

      settings = {
        network_name = meshId;

        # One or more bootstrap / discovery nodes
        peers = bootstrapServers;
      };
    };
  };

  networking.firewall.allowedTCPPorts = [ 11010 ];
  networking.firewall.allowedUDPPorts = [ 11010 ];
  networking.firewall.allowedUDPPortRanges = [
    {
      from = 32768;
      to = 60999;
    }
  ];

  # Allow traffic on the EasyTier TUN interface
  networking.firewall.trustedInterfaces = [ "tun0" ];

  # Explicitly allow all traffic from/to the EasyTier network
  # networking.firewall.extraCommands = ''
  #   iptables -A nixos-fw -i tun0 -j nixos-fw-accept
  #   iptables -A nixos-fw -o tun0 -j nixos-fw-accept
  # '';
}
