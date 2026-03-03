{
  lib,
  ...
}:
{
  imports = [
    ./server.nix
  ];

  services.k3s = {
    # Enables etcd
    clusterInit = true;
    serverAddr = lib.mkForce "";
    extraFlags = [
      "--tls-san=controlplane.men.sh,de-fsn1-01,100.64.0.1"
      "--write-kubeconfig-group=nixos"
      "--write-kubeconfig-mode=0640"
    ];
  };
}
