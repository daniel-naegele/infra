#!/usr/bin/env bash

# Create a temporary directory
temp=$(mktemp -d)

# Function to cleanup temporary directory on exit
cleanup() {
   rm -rf "$temp"
}
trap cleanup EXIT

# Create the directory where sshd expects to find the host keys
install -d -m755 "$temp/etc/ssh"

# Generate machine key
ssh-keygen -t ed25519 -f "$temp/etc/ssh/ssh_host_ed25519_key" -N ""
# Generate pubic key and convert to age
ssh-keygen -f "$temp/etc/ssh/ssh_host_ed25519_key" -y | nix run nixpkgs#ssh-to-age --

# Set the correct permissions so sshd will accept the key
chmod 600 "$temp/etc/ssh/ssh_host_ed25519_key"

echo "Please confirm that you updated the SOPS configuration to include this key and updated the keys themselves."
read -p "Type 'yes' to continue: " confirmation
if [ "$confirmation" != "yes" ]; then
  echo "Installation aborted."
  exit 1
fi

echo "Please define the flake input"
read -p "" flake_input

echo "Please define the target host"
read -p "" target_host

# Set the correct permissions so sshd will accept the key
chmod 600 "$temp/etc/ssh/ssh_host_ed25519_key"
# if /var/lib/sbctl already exists
if [ -d /var/lib/sbctl ]; then
  sudo mv /var/lib/sbctl /var/lib/sbctl.bak
fi

sudo sbctl create-keys
install -d -m755 "$temp/persist/var/lib/sbctl"
sudo mv /var/lib/sbctl "${temp}/persist/var/lib/sbctl"
cp -r "${temp}/persist/var" $temp

chmod 600 "$temp/var"
chmod 600 "$temp/persist/var"

# if you made a backup of sbctl before
if [ -d /var/lib/sbctl.bak ]; then
  sudo mv /var/lib/sbctl.bak /var/lib/sbctl
fi

# Install NixOS to the host system with our secrets
nix run github:nix-community/nixos-anywhere -- --extra-files "$temp" --flake flake_input --target-host target_host --debug
