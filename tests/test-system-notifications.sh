#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
task_tf_data=$(mktemp -d)
trap 'rm -rf -- "$task_tf_data"' EXIT
export TF_DATA_DIR="$task_tf_data"
export TF_IN_AUTOMATION=true

terraform -chdir="$ROOT/terraform/system-notifications" fmt -check -recursive
terraform -chdir="$ROOT/terraform/system-notifications" init -backend=false -input=false -lockfile=readonly
terraform -chdir="$ROOT/terraform/system-notifications" validate -no-color
terraform -chdir="$ROOT/terraform/system-notifications" test -no-color

if rg -n '^output[[:space:]]' "$ROOT/terraform/system-notifications" --glob '*.tf'; then
  echo "FAIL: system notifications must not expose destination outputs" >&2
  exit 1
fi
