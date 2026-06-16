# CHANGES — what was built and why

## What this delivers

A from-zero, layered-Terraform **LLM platform on AKS** with GitOps (Argo CD + Flux),
managed observability, and FinOps guardrails — implementing the brief in
[PROMPT.md](PROMPT.md) against the Near.U JD.

### Terraform (7 layers, each its own state)
- **00-bootstrap** — remote-state Storage Account (ZRS, versioned) + platform RGs +
  naming/tag schema. Runs on a local backend then migrates its own state in.
- **10-network** — VNet `10.42.0.0/16`, system/user/gpu/apim/pe subnets, per-pool NSGs
  (deny Internet inbound), private DNS zones for ACR/KV/Blob/AML.
- **20-identity** — RBAC Key Vault + Premium ACR (both private-endpoint'd, public access
  off), three user-assigned identities (workload / external-secrets / gitops), least-priv
  KV+ACR role assignments. Names made globally-unique via a deterministic subscription
  hash (no random provider → stable plans).
- **30-aks** — private AKS, Azure CNI Overlay + Cilium, Workload Identity/OIDC, KEDA+VPA,
  system + CPU + **GPU Spot scale-to-zero** pools, OIDC federation of the 20 identities,
  kubelet AcrPull, and the Log Analytics + Azure Monitor workspaces AKS needs at creation.
- **40-gitops** — Argo CD + Flux via Helm; Argo app-of-apps root + Flux GitRepository/
  Kustomization pointing at `gitops/`.
- **50-observability** — managed Grafana (AMW datasource), Prometheus recording/alert
  rule groups (GPU/latency/idle), ops Action Group, AKS diagnostics → LAW, Azure budget.
- **60-llm-platform** — APIM (LLM API + token-limit/rate-limit/tenant policy), AI Content
  Safety, optional Azure OpenAI fallback + deployment, KV secrets for the above.

### GitOps tree (`gitops/`)
- `apps/llm` — Kustomize base + dev/prod overlays: vLLM Deployment (zero-downtime
  rollout, probes, restricted PodSecurity, Workload Identity), Service, KEDA ScaledObject
  (min 0), PDB. Prod overlay pins image by digest and raises the warm floor.
- `argocd/apps` — app-of-apps child Applications.
- `infrastructure/` — Flux HelmReleases: External Secrets, OpenCost, DCGM exporter.

### Tooling & tests
- pre-commit (tf fmt/validate/tflint/docs, checkov, yamllint, shellcheck, detect-secrets),
  two GitHub Actions workflows, kind e2e (`test/`), and `scripts/apply.sh|destroy.sh`.

## Verified locally
- `terraform validate` passes on **all 7 layers** (`-backend=false`).
- `terraform fmt -recursive` clean.
- `kubectl kustomize` builds clean for base + dev + prod + argocd-apps + kind test overlay.
- `shellcheck` clean on all scripts (default severity).
- Not run here (needs a subscription / GPU quota / kind runtime): `terraform apply`, live
  GitOps reconciliation, the kind e2e job. The e2e is wired to run in CI.

## Issues spotted beyond the stated scope
- **Private cluster vs. Terraform connectivity.** Bootstrapping Argo/Flux (`40`) and
  writing KV secrets (`60`) against a *private* API server / private Key Vault requires an
  in-VNet runner + `kubelogin`. Documented as the one manual-placement caveat rather than
  weakening the security posture.
- **Workload-identity client-id in manifests.** Kustomize can't read Terraform outputs, so
  SA `client-id` annotations are placeholders patched per overlay (or via an Argo CMP).
  Honest seam, noted in the manifests.
- **GPU image cold start.** Model weights on `emptyDir` re-download on reschedule — prod
  should use a Blob/Azure Files PVC or bake weights into the image (see BONUS).

## Trade-offs
- **Two GitOps controllers** cost operational overhead; justified by platform/product
  separation, with a documented path to consolidate.
- **Spot GPU** can be evicted on capacity — mitigated by the Azure OpenAI fallback and
  `spot_max_price = -1` (no price-based eviction).
- **Developer-tier APIM** has no SLA/VNet — fine for the deliverable; Premium (or Std v2 +
  PE) is the prod step-up and the biggest single cost increase (see README estimate).
- **azurerm has no provider default_tags** — replicated via `local.tags` merged per
  resource; slightly more boilerplate than the miniclip AWS `default_tags` approach.

## What I'd do next in a real rollout
- API Server VNet Integration (or a managed CI agent pool in-VNet) so GitOps bootstrap
  isn't a manual in-VNet step.
- Private endpoints + `Deny` network ACLs on Content Safety / Azure OpenAI.
- Eval pipeline wired to the seam: MLflow on Azure ML (private link zone already created)
  or LangSmith, with a regression gate in CI before promotion.
- ApplicationSet per environment/cluster instead of hand-edited overlay paths.
- Model weights on a CSI PVC + a pull-through ACR cache + image-prewarm DaemonSet.
