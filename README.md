# Infra
This repo contains all definitions (NixOS, Flux, etc.) for my personal services.

## Building Signed Installation Media

All commands require the dev shell: `nix develop`

Output is written to `result/`.

### Signed ISO

```bash
./hack/sign-iso.sh de-man1-01
# Output: result/signed-nixos.iso
```

### Signed kexec (for nixos-anywhere)

```bash
./hack/sign-kexec.sh de-man1-01
# Output: result/nixos-kexec.efi

# Use with nixos-anywhere
nixos-anywhere --kexec result/nixos-kexec.efi --flake .#de-man1-01 root@target
```

### Requirements

- Age key at `~/.config/sops/age/keys.txt` (or set `SOPS_AGE_KEY_FILE`)
- Machine must have its Secure Boot keys in `secrets/machines/<machine>/`
