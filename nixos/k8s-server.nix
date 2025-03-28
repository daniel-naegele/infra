{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [ <sops-nix/modules/sops> ];

  services.k3s = {
    enable = true;
    role = "server";
    token = sops.secrets.k3s_token;
    clusterInit = true;
  };
}
