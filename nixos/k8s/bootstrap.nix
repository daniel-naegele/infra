{
  lib,
  ...
}:
{
  imports = [
    ./server.nix
  ];

  services.k3s = {
    clusterInit = true;
    serverAddr = lib.mkForce "";
  };
}
