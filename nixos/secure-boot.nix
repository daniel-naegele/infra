{
  lib,
  ...
}:
{
  boot.lanzaboote = {
    enable = true;
    pkiBundle = "/var/lib/sbctl";
    autoGenerateKeys.enable = true;
    autoEnrollKeys = {
      enable = true;
      # Automatically reboot to enroll the keys in the firmware
      autoReboot = true;
    };
  };

  boot.loader = {
    systemd-boot.enable = lib.mkForce false;
  };
}
