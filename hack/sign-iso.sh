#!/usr/bin/env bash
# Build and sign a NixOS ISO with Secure Boot keys
# Usage: ./hack/sign-iso.sh <machine>
#
# Arguments:
#   machine - Machine name for key selection (e.g., de-man1-01)
#
# Output:
#   result/signed-nixos.iso
#
# Environment:
#   SOPS_AGE_KEY_FILE - Path to age key file (default: ~/.config/sops/age/keys.txt)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

MACHINE="${1:?Usage: $0 <machine>}"
OUTPUT_DIR="$REPO_ROOT/result"
ISO_OUT="$OUTPUT_DIR/signed-nixos.iso"

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

if [[ ! -f "$DB_CERT" ]]; then
  echo "Error: Certificate not found at $DB_CERT"
  exit 1
fi

export SOPS_AGE_KEY_FILE="${SOPS_AGE_KEY_FILE:-$HOME/.config/sops/age/keys.txt}"
if [[ ! -f "$SOPS_AGE_KEY_FILE" ]]; then
  echo "Error: Age key file not found at $SOPS_AGE_KEY_FILE"
  echo "Set SOPS_AGE_KEY_FILE to your age key location"
  exit 1
fi

mkdir -p "$OUTPUT_DIR"

echo "Building ISO..."
nix build "$REPO_ROOT#packages.x86_64-linux.iso" -o "$OUTPUT_DIR/iso-unsigned"

ISO_IN=$(find "$OUTPUT_DIR/iso-unsigned" -name "*.iso" | head -1)
if [[ -z "$ISO_IN" ]]; then
  echo "Error: No ISO found in build output"
  exit 1
fi

WORK=$(mktemp -d)
trap "rm -rf $WORK" EXIT

echo "Decrypting signing key..."
sops -d "$DB_KEY_ENC" > "$WORK/db.key"

echo "Extracting ISO..."
7z x -o"$WORK/iso" "$ISO_IN" -y >/dev/null

echo "Signing EFI binaries..."
find "$WORK/iso" \( -name "*.efi" -o -name "*.EFI" \) | while read -r efi; do
  echo "  Signing $(basename "$efi")"
  sbsign --key "$WORK/db.key" --cert "$DB_CERT" --output "$efi.signed" "$efi"
  mv "$efi.signed" "$efi"
done

echo "Rebuilding ISO..."
xorriso -as mkisofs \
  -o "$ISO_OUT" \
  -R -J -joliet-long \
  -b isolinux/isolinux.bin \
  -c isolinux/boot.cat \
  -no-emul-boot -boot-load-size 4 -boot-info-table \
  -eltorito-alt-boot \
  -e boot/efi.img \
  -no-emul-boot -isohybrid-gpt-basdat \
  "$WORK/iso" 2>/dev/null

# Cleanup unsigned build symlink
rm -f "$OUTPUT_DIR/iso-unsigned"

echo ""
echo "Signed ISO written to: $ISO_OUT"
