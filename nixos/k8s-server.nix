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
    token = config.secrets.k3s_token;
    clusterInit = true;
  };
}
