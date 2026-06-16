#!/usr/bin/env bash
# Destroy in REVERSE dependency order. 00-bootstrap is destroyed last and will
# refuse if it still holds the migrated state of other layers — destroy those
# first. The remote-state Storage Account + RGs go with 00-bootstrap.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TFVARS="${ROOT}/terraform.tfvars"

val() { grep -E "^${1}\s*=" "${TFVARS}" | head -1 | sed -E 's/.*=\s*"?([^"]*)"?.*/\1/'; }
RG="$(val tfstate_resource_group)"
SA="$(val tfstate_storage_account)"
CT="$(val tfstate_container)"

ORDER=(60-llm-platform 50-observability 40-gitops 30-aks 20-identity 10-network 00-bootstrap)

for layer in "${ORDER[@]}"; do
  dir="${ROOT}/terraform/${layer}"
  echo "================ destroy ${layer} ================"
  if [ "${layer}" = "00-bootstrap" ]; then
    terraform -chdir="${dir}" init -input=false
  else
    terraform -chdir="${dir}" init -input=false \
      -backend-config="resource_group_name=${RG}" \
      -backend-config="storage_account_name=${SA}" \
      -backend-config="container_name=${CT}" \
      -backend-config="key=${layer}.tfstate"
  fi
  terraform -chdir="${dir}" destroy -input=false -var-file="${TFVARS}"
done
