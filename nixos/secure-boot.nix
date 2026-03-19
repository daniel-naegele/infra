{
  config,
  lib,
  hostname,
  ...
}:
let
  machineSecretsDir = ../secrets/machines + "/${hostname}";
in
{
  # Only db.key is needed on the machine for lanzaboote to sign generations
  # PK/KEK are only needed for modifying the Secure Boot key hierarchy (rare, done offline)
  sops.secrets."secureboot-db-key" = {
    sopsFile = machineSecretsDir + "/secureboot-db.key";
    format = "binary";
    path = "/var/lib/sbctl/keys/db/db.key";
    mode = "0600";
  };

  # db.pem is needed alongside db.key for signing
  system.activationScripts.secureboot-certs = lib.stringAfter [ "etc" ] ''
    mkdir -p /var/lib/sbctl/keys/db
    cp ${machineSecretsDir + "/secureboot-db.pem"} /var/lib/sbctl/keys/db/db.pem
    chmod 644 /var/lib/sbctl/keys/db/db.pem
  '';

  boot.lanzaboote = {
    enable = true;
    pkiBundle = "/var/lib/sbctl";
  };

  boot.loader = {
    systemd-boot.enable = lib.mkForce false;
  };
}
