#!/usr/bin/env bash
# Build and sign a NixOS kexec UKI for nixos-anywhere with Secure Boot keys
# Usage: ./hack/sign-kexec.sh <machine>
#
# Arguments:
#   machine - Machine name for key selection (e.g., de-man1-01)
#
# Output:
#   result/nixos-kexec.efi
#
# Environment:
#   SOPS_AGE_KEY_FILE - Path to age key file (default: ~/.config/sops/age/keys.txt)

set -euo pipefail

# Check for required tools (available in nix develop shell)
for cmd in sbsign sops; do
  if ! command -v "$cmd" &>/dev/null; then
    echo "Error: '$cmd' not found. Run this script from 'nix develop' shell."
    exit 1
  fi
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

MACHINE="${1:?Usage: $0 <machine>}"
OUTPUT_DIR="$REPO_ROOT/result"

# Validate machine
if [[ ! -d "$REPO_ROOT/secrets/machines/$MACHINE" ]]; then
  echo "Error: Unknown machine '$MACHINE'"
  echo "Available machines:"
  ls -1 "$REPO_ROOT/secrets/machines/" | grep -v '\.yaml$' || true
  exit 1
fi

DB_KEY_ENC="$REPO_ROOT/secrets/machines/$MACHINE/secureboot-db.key"
DB_CERT="$REPO_ROOT/secrets/machines/$MACHINE/secureboot-db.pem"

if [[ ! -f "$DB_KEY_ENC" ]]; then
  echo "Error: Signing key not found at $DB_KEY_ENC"
  exit 1
fi

export SOPS_AGE_KEY_FILE="${SOPS_AGE_KEY_FILE:-$HOME/.config/sops/age/keys.txt}"
if [[ ! -f "$SOPS_AGE_KEY_FILE" ]]; then
  echo "Error: Age key file not found at $SOPS_AGE_KEY_FILE"
  echo "Set SOPS_AGE_KEY_FILE to your age key location"
  exit 1
fi

mkdir -p "$OUTPUT_DIR"

echo "Building kexec image..."
nix build "$REPO_ROOT#packages.x86_64-linux.kexec" -o "$OUTPUT_DIR/kexec-unsigned"

WORK=$(mktemp -d)
trap "rm -rf $WORK" EXIT

echo "Decrypting signing key..."
sops -d "$DB_KEY_ENC" > "$WORK/db.key"

echo "Signing UKI..."
sbsign --key "$WORK/db.key" --cert "$DB_CERT" \
  --output "$OUTPUT_DIR/nixos-kexec.efi" \
  "$OUTPUT_DIR/kexec-unsigned/nixos-kexec.efi"

# Cleanup unsigned build symlink
rm -f "$OUTPUT_DIR/kexec-unsigned"

echo ""
echo "Signed UKI written to: $OUTPUT_DIR/nixos-kexec.efi"
echo ""
echo "To use with nixos-anywhere:"
echo "  nixos-anywhere --kexec $OUTPUT_DIR/nixos-kexec.efi --flake .#$MACHINE <target>"
