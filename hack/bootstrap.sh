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

echo "Please define machine hostname (e.g. de-fsn1-01)"
read -p "" machine_hostname

echo "Please define the target host (e.g. root@my-ip)"
read -p "" target_host

echo "Please define the SSH port (default: 22)"
read -p "" ssh_port
ssh_port=${ssh_port:-22}

# Set the correct permissions so sshd will accept the key
chmod 600 "$temp/etc/ssh/ssh_host_ed25519_key"

# provide FDE key and output raw
sops -d "secrets/$machine_hostname.yaml" | yq '.fde_pass' -r > /tmp/disk-1.key

# Install NixOS to the host system with our secrets
nix run github:nix-community/nixos-anywhere -- \
  --disk-encryption-keys /tmp/disk-1.key /tmp/disk-1.key \
  --extra-files "$temp" \
  --flake ".#$machine_hostname" \
  --target-host "$target_host" \
  --ssh-port "$ssh_port" \
  --debug

rm /tmp/disk-1.key
