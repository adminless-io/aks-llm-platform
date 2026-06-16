#!/usr/bin/env bash
# init-template.sh — one-shot initializer after "Use this template".
# Replaces placeholders across the repo, seeds terraform.tfvars, and (optionally)
# removes the template-only files so your fresh repo starts clean.
#
#   Usage:  scripts/init-template.sh
#           scripts/init-template.sh --no-prompt   # use env vars / defaults
#
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

say()  { printf '\033[1;36m▸ %s\033[0m\n' "$*"; }
ask()  { local p="$1" d="$2" v; if [[ "${NO_PROMPT:-}" == "1" ]]; then echo "$d"; else read -rp "$p [$d]: " v; echo "${v:-$d}"; fi; }

[[ "${1:-}" == "--no-prompt" ]] && NO_PROMPT=1

# Best-effort defaults from the git remote (org/repo).
ORG_REPO="$(git config --get remote.origin.url 2>/dev/null | sed -E 's#.*github.com[:/]##; s/\.git$//')" || true
DEF_ORG="${ORG_REPO%%/*}";  [[ "$DEF_ORG"  == "$ORG_REPO" ]] && DEF_ORG="adminless-io"
DEF_REPO="${ORG_REPO##*/}"; [[ -z "$DEF_REPO" || "$DEF_REPO" == "$ORG_REPO" ]] && DEF_REPO="aks-llm-platform"

say "Initializing from this template — answer a few questions (Enter = default)."
GH_ORG="$(ask 'GitHub org/owner'        "$DEF_ORG")"
GH_REPO="$(ask 'Repository name'        "$DEF_REPO")"
NAME_PREFIX="$(ask 'Azure resource name_prefix (lowercase, <=11 chars)' 'llmops')"
LOCATION="$(ask 'Azure region'          'westeurope')"
ENV="$(ask 'Environment (dev/stg/prod)' 'dev')"
ALERT_EMAIL="$(ask 'Ops alert email'    'platform-oncall@example.com')"
COST_CENTER="$(ask 'cost_center tag'    'platform')"
OWNER="$(ask 'owner tag'               "$GH_ORG")"

GITOPS_URL="https://github.com/${GH_ORG}/${GH_REPO}.git"
STATE_RG="${NAME_PREFIX}-tfstate-rg"
STATE_SA="$(echo "${NAME_PREFIX}tfstate${ENV}01" | tr -cd 'a-z0-9' | cut -c1-24)"

# --- 1. README placeholders (badges / writeup links / clone URL) ----------
if [[ -f README.md ]]; then
  say "Patching README.md (<ORG>/<REPO> → ${GH_ORG}/${GH_REPO})"
  sed -i.bak -E "s#<ORG>/<REPO>#${GH_ORG}/${GH_REPO}#g; s#adminless-io/aks-llm-platform#${GH_ORG}/${GH_REPO}#g" README.md && rm -f README.md.bak
fi

# --- 2. terraform.tfvars (git-ignored) ------------------------------------
if [[ -f terraform.tfvars.example && ! -f terraform.tfvars ]]; then
  say "Seeding terraform.tfvars"
  cp terraform.tfvars.example terraform.tfvars
  sed -i.bak -E \
    -e "s#^location *=.*#location        = \"${LOCATION}\"#" \
    -e "s#^env *=.*#env             = \"${ENV}\"#" \
    -e "s#^name_prefix *=.*#name_prefix = \"${NAME_PREFIX}\"#" \
    -e "s#^alert_email *=.*#alert_email          = \"${ALERT_EMAIL}\"#" \
    -e "s#cost_center = .*#cost_center = \"${COST_CENTER}\"#" \
    -e "s#owner       = .*#owner       = \"${OWNER}\"#" \
    -e "s#^tfstate_resource_group *=.*#tfstate_resource_group  = \"${STATE_RG}\"#" \
    -e "s#^tfstate_storage_account *=.*#tfstate_storage_account = \"${STATE_SA}\"#" \
    -e "s#^gitops_repo_url *=.*#gitops_repo_url      = \"${GITOPS_URL}\"#" \
    terraform.tfvars && rm -f terraform.tfvars.bak
  echo "  → set: location, env, name_prefix, alert_email, tags, state backend, gitops_repo_url"
  echo "  → STILL TODO by you: subscription_id, tenant_id (kept as 0000… placeholders)"
fi

# --- 3. drop template-only files ------------------------------------------
say "Removing template-only files"
rm -f .github/workflows/template-cleanup.yml
echo "  (init-template.sh kept — delete it manually once you're happy.)"

cat <<EOF

$(say "Done.")
Next:
  1. Edit terraform.tfvars → set subscription_id + tenant_id (and review tags/budget).
  2. az login && az account set --subscription <sub>
  3. Follow the Quickstart in README.md (apply order 00 → 60).

Tip: 'name_prefix' feeds global-unique names (storage account). Keep it short + lowercase.
EOF
