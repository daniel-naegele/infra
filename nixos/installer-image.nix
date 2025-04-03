{
  system.activatable = false;
  networking.hostName = "nixos-install";
  users.users.root.openssh.authorizedKeys.keyFiles = [ ../secrets/authorized_keys ];
}
