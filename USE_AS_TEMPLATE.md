# Maintainer guide — publishing this as a GitHub template

This repo is designed to be a **GitHub template repository** (the green
**“Use this template”** button). Two halves: (A) one-time setup you do as the
template owner, (B) what consumers get when they instantiate it.

---

## A. Turn the repo into a template (one time)

```sh
# 1. Create the public repo under the org (run from the project root).
gh repo create adminless-io/aks-llm-platform \
  --public --source . --remote origin --push \
  --description "Self-hosted LLM inference on Azure AKS: Terraform + vLLM + KEDA scale-to-zero + GitOps (Argo CD & Flux) + APIM."

# 2. Flag it as a template + add discoverable topics.
gh repo edit adminless-io/aks-llm-platform --template \
  --add-topic azure --add-topic aks --add-topic kubernetes \
  --add-topic llm --add-topic vllm --add-topic llmops \
  --add-topic terraform --add-topic gitops --add-topic argocd \
  --add-topic flux --add-topic keda --add-topic finops \
  --add-topic gpu --add-topic apim --add-topic scale-to-zero

# 3. (Optional) enable Discussions for the issue-template contact link.
gh repo edit adminless-io/aks-llm-platform --enable-discussions
```

Or via UI: **Settings → General → ✅ Template repository**, and **About → ⚙ → Topics**.

> The flag is just a checkbox — it adds the **Use this template** button and lets the
> repo be passed to `gh repo create --template`.

### Files that make it a *good* template (already in this repo)

| File | Role |
|---|---|
| `scripts/init-template.sh` | Interactive init — rewrites placeholders, seeds `terraform.tfvars`, removes template-only files. |
| `.github/workflows/template-cleanup.yml` | Auto-runs once in a generated repo (skipped on the template itself via `is_template`), scrubs placeholders, then deletes itself. |
| `.github/PULL_REQUEST_TEMPLATE.md`, `ISSUE_TEMPLATE/` | Community files. |
| `.github/CODEOWNERS`, `dependabot.yml` | Ownership + dependency hygiene. |
| `LICENSE` | MIT. |
| `terraform.tfvars.example` | The single source of consumer-tunable inputs. |

Placeholders the tooling rewrites: `<ORG>/<REPO>` and `adminless-io/aks-llm-platform`.

---

## B. What a consumer does

```sh
# Either click "Use this template" in the UI, or:
gh repo create my-org/my-llm-platform \
  --template adminless-io/aks-llm-platform --private --clone
cd my-llm-platform

# Initialize (interactive). The auto-cleanup workflow does most of this on first
# push too — the script is the manual / offline path.
scripts/init-template.sh

# Then set the two secrets the script intentionally leaves as 0000… placeholders:
#   subscription_id, tenant_id  in terraform.tfvars
az login && az account set --subscription <sub>
# follow README Quickstart: apply 00 → 10 → 20 → 30 → 40 → 50 → 60
```

That's it — they get a renamed, ready-to-apply copy pointing GitOps at *their* repo.
