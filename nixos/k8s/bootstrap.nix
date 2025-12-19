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
  };
}
