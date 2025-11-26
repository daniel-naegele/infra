#!/usr/bin/env bash


echo "Please provide the cluster path:"
read -p "" cluster_path

GITHUB_TOKEN=$(sops --decrypt secrets/github-pat.bin)
DECRYPTION_KEY=$(sops --decrypt secrets/cluster_decryption_key.bin)

sops --decrypt secrets/cluster_decryption_key.bin | kubectl -n flux-system create secret generic sops-age \
  --from-file=sops.agekey=/dev/stdin

echo "$GITHUB_TOKEN" | flux bootstrap github \
  --token-auth=false \
  --read-write-key=true \
  --owner=daniel-naegele \
  --repository=infra \
  --branch=main \
  --path="$cluster_path" \
  --personal
