{
  modulesPath,
  lib,
  pkgs,
  sops,
  ...
}:
{
  imports = [
    <sops-nix/modules/sops>
    (modulesPath + "/installer/scan/not-detected.nix")
    (modulesPath + "/profiles/qemu-guest.nix")
    ./disk-config.nix
  ];
  boot.loader.grub = {
    # no need to set devices, disko will add all devices that have a EF02 partition to the list already
    # devices = [ ];
    efiSupport = true;
    efiInstallAsRemovable = true;
  };
  boot.kernelModules = [ "ceph" ];
  services.openssh.enable = true;
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

  users.users.nixos.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAII4FqdxzINQfwBVADBQPKO56ClKP3ToxvGALzjzGOTlD daniel@DN-Laptop"
  ];

  networking.useDHCP = lib.mkDefault true;

  system.stateVersion = "24.05";
}
