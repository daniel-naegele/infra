#!/usr/bin/env bash
echo "This script will all SOPS keys in the given directory non-interactively."
read -p "Type 'yes' to continue: " confirmation
if [ "$confirmation" != "yes" ]; then
  echo "Installation aborted."
  exit 1
fi

set -u  # error on unset variables (but not -e, we want to continue on failures)

DIR="${1:-}"

if [[ -z "$DIR" || ! -d "$DIR" ]]; then
  echo "Usage: $0 <directory>"
  exit 1
fi

UPDATED=0
SKIPPED=0
FAILED=0

echo "Updating SOPS keys in directory: $DIR"
echo

while IFS= read -r -d '' file; do
  # Check if the file looks like a SOPS file
  if ! sops --config /dev/null -d "$file" >/dev/null 2>&1; then
    echo "SKIP  : $file (not a SOPS file)"
    ((SKIPPED++))
    continue
  fi

  if sops updatekeys "$file" -y >/dev/null 2>&1; then
    echo "OK    : $file"
    ((UPDATED++))
  else
    echo "FAIL  : $file"
    ((FAILED++))
  fi
done < <(find "$DIR" -type f -print0)

echo
echo "Summary:"
echo "  Updated : $UPDATED"
echo "  Skipped : $SKIPPED"
echo "  Failed  : $FAILED"
