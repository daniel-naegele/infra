{
  modulesPath,
  lib,
  pkgs,
  sops,
  ...
}:
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    (modulesPath + "/profiles/qemu-guest.nix")
  ];
  boot.loader.grub = {
    # no need to set devices, disko will add all devices that have a EF02 partition to the list already
    # devices = [ ];
    efiSupport = true;
    efiInstallAsRemovable = true;
  };
  boot.kernelModules = [ "ceph" ];
  sops.defaultSopsFile = ./../secrets/secrets.yaml;

  environment.systemPackages = with pkgs; [
    cachix
    git
    htop
    openssh
    vim
    wget
    tailscale
  ];

  users.users.nixos = {
    isSystemUser = true;
    group = "nixos";
    openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAII4FqdxzINQfwBVADBQPKO56ClKP3ToxvGALzjzGOTlD daniel@DN-Laptop"
  ];
  };
  users.groups.nixos = {};

services.openssh = {
  enable = true;
  # require public key authentication for better security
  settings.PasswordAuthentication = false;
  settings.KbdInteractiveAuthentication = false;
  settings.PermitRootLogin = "no";
};

  system.stateVersion = "24.11";
}
