{
  modulesPath,
  inputs,
  lib,
  pkgs,
  ...
}:
{
  boot.loader.grub = {
    enable = true;
    timeoutStyle = "hidden";
    configurationLimit = 20;
  };
}
