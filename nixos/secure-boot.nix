{
  lib,
  ...
}:
{
  boot.lanzaboote = {
    enable = true;
    pkiBundle = "/var/lib/sbctl";
  };

  boot.loader = {
    systemd-boot.enable = lib.mkForce false;
  };
}
