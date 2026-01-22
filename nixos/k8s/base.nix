{
  config,
  lib,
  pkgs,
  ...
}:
let
  kubeletSysctlConf = pkgs.writeText "10-unsafe-sysctls.conf" ''
    apiVersion: kubelet.config.k8s.io/v1beta1
    kind: KubeletConfiguration
    allowedUnsafeSysctls:
      - net.ipv4.conf.all.src_valid_mark
      - net.ipv4.ip_forward
      - net.ipv6.conf.all.forwarding
  '';
in
{
  sops.secrets.k3s_token = {
    format = "binary";
    # can be also set per secret
    sopsFile = ../../secrets/shared/k3s.key;
  };

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

  systemd.tmpfiles.rules = [
    "d /var/lib/rancher/k3s/agent/etc/kubelet.conf.d 0755 root root -"
    "r /var/lib/rancher/k3s/agent/etc/kubelet.conf.d/10-unsafe-sysctls.conf"
    "L /var/lib/rancher/k3s/agent/etc/kubelet.conf.d/10-unsafe-sysctls.conf - - - - ${kubeletSysctlConf}"
  ];

  systemd.services.k3s.after = [ "systemd-tmpfiles-setup.service" ];
  systemd.services.k3s.wantedBy = [ "multi-user.target" ];
}
