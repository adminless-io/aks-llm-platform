#!/usr/bin/env bash
# Apply the platform layer-by-layer in dependency order.
#   00-bootstrap runs on a LOCAL backend (it creates the state Storage Account),
#   then migrates its own state in; every later layer uses the azurerm backend.
#
# Usage: scripts/apply.sh [layer ...]   (default: all, in order)
# Requires: terraform, az login (+ kubelogin for 40/60 against the private AKS).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TFVARS="${ROOT}/terraform.tfvars"
[ -f "${TFVARS}" ] || { echo "missing ${TFVARS} (copy terraform.tfvars.example)"; exit 1; }

# Pull backend coordinates out of tfvars (created by 00-bootstrap).
val() { grep -E "^${1}\s*=" "${TFVARS}" | head -1 | sed -E 's/.*=\s*"?([^"]*)"?.*/\1/'; }
RG="$(val tfstate_resource_group)"
SA="$(val tfstate_storage_account)"
CT="$(val tfstate_container)"

ORDER=(00-bootstrap 10-network 20-identity 30-aks 40-gitops 50-observability 60-llm-platform)
LAYERS=("${@:-${ORDER[@]}}")
[ "$#" -eq 0 ] && LAYERS=("${ORDER[@]}")

for layer in "${LAYERS[@]}"; do
  dir="${ROOT}/terraform/${layer}"
  echo "================ ${layer} ================"
  if [ "${layer}" = "00-bootstrap" ]; then
    terraform -chdir="${dir}" init -input=false
  else
    terraform -chdir="${dir}" init -input=false \
      -backend-config="resource_group_name=${RG}" \
      -backend-config="storage_account_name=${SA}" \
      -backend-config="container_name=${CT}" \
      -backend-config="key=${layer}.tfstate"
  fi
  terraform -chdir="${dir}" apply -input=false -var-file="${TFVARS}"
done

echo "Done. Re-run any layer's plan to confirm a clean (no-diff) state."
