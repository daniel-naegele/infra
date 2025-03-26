{
  config,
  lib,
  pkgs,
  ...
}:

{
  boot.kernelModules = [ "rbd" ];
}
