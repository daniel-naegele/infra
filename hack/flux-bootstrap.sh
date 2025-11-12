#!/usr/bin/env bash


echo "Please provide the cluster path:"
read -p "" cluster_path

GITHUB_TOKEN=$(sops --decrypt secrets/github-pat.bin)

echo "$GITHUB_TOKEN" | flux bootstrap github \
  --token-auth=false \
  --read-write-key=true \
  --owner=daniel-naegele \
  --repository=infra \
  --branch=main \
  --path="$cluster_path" \
  --personal
