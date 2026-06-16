# Prompt — Azure LLMOps Platform (AKS + GitOps + LLM serving + Observability + FinOps)

> Paste this into Claude Code (or hand it to an engineer) as a self-contained brief.
> It is written to mirror the Near.U LLMOps/MLOps JD (`jd.md`) and to reuse the
> delivery conventions proven in `miniclip/` (layered Terraform, decision tables,
> cost estimates, pre-commit) and `sap2026/T3-2/` (Kustomize, kind-based e2e in CI,
> `CHANGES.md`/`BONUS.md`, TDD methodology).

---

## Role

You are a **Platform / LLMOps engineer**. Build the infrastructure layer for an AI
consultancy that runs LLM systems 24/7 on **Microsoft Azure**: agents, RAG/knowledge
systems, and automations that must still work six months after go-live. You own the
platform, not the application code.

## Objective

Produce **Terraform** that stands up, from nothing, a reusable **LLM-serving platform on
AKS** with **GitOps (both Argo CD and Flux)**, production-grade **observability**, and
**FinOps** guardrails baked in. The platform must be able to serve a **top-tier
open-weight LLM** (the "top 1" — pick a current leading open model and justify the choice,
e.g. Llama / Qwen / DeepSeek class) on GPU, delivered and reconciled via GitOps — not
`kubectl apply` by hand.

Treat this as a take-home of **senior depth**: depth of reasoning and justified
trade-offs matter more than breadth of features.

---

## What to build

### 1. Terraform, split **by layer** (one root module + state per layer)

Mirror the miniclip standard: numbered directories, each its own root module with its own
state, layers communicating via `terraform_remote_state` outputs. Use an **Azure backend**
(Storage Account + container) for remote state, created in the bootstrap layer.

| Layer | Owns | Reads |
|---|---|---|
| `00-bootstrap` | Backend Storage Account + container, root resource group, providers, naming convention, tag schema (`environment`, `product`, `cost-center`, `owner`) wired into `azurerm` provider defaults | — |
| `10-network` | VNet, subnets (system / user / GPU / pods), NSGs, Private DNS zones, private endpoints | `00` |
| `20-identity` | Workload Identity (OIDC), managed identities, **Key Vault**, RBAC role assignments, federated credentials for GitOps + LLM workloads | `00 / 10` |
| `30-aks` | AKS cluster (private API server), **system** node pool, **CPU** user pool, **GPU** node pool (Spot, scale-to-zero), cluster autoscaler, KEDA, workload identity enabled | `00 / 10 / 20` |
| `40-gitops` | Bootstrap **Argo CD** and **Flux** via Helm; wire app-of-apps (Argo) and `GitRepository`/`Kustomization`/`HelmRelease` (Flux); everything below this line is reconciled from Git | `00 / 30` |
| `50-observability` | Azure Monitor **managed Prometheus** + **managed Grafana**, Container Insights, dashboards, alert rules; cost-metrics exporter (OpenCost/Kubecost) | `00 / 30` |
| `60-llm-platform` | The LLM serving stack (see §3), Azure **API Management** in front of the model endpoint, Azure **AI Content Safety** wiring, optional Azure OpenAI fallback | `00 / 30 / 40 / 50` |
| `modules/*` | Reusable modules (e.g. `aks_node_pool`, `gitops_bootstrap`, `gpu_workload`) | consumed above |

State a clear **apply order** and assert that a second `plan` in any layer is **clean
(no diff)** — the composition must be idempotent.

### 2. GitOps — both Argo CD **and** Flux

- Install **both** controllers via Terraform (Helm provider), then hand off all
  application/platform delivery to Git.
- Pick a deliberate division of responsibility and **justify it** (a common split: Flux
  reconciles platform/infra Helm releases; Argo CD delivers the LLM apps with the
  app-of-apps pattern — or run them side-by-side for comparison). Document why both, and
  what you'd standardize on for a single-tool production setup.
- The LLM stack in `60-llm-platform` must be **declared in Git and reconciled by GitOps**,
  not applied imperatively. Use **Kustomize** (overlays per environment) following the
  T3-2 base/overlay convention.

### 3. LLM serving on AKS ("top 1")

- Serve a leading open-weight model on the **GPU node pool**. Recommended Azure-native
  path: **KAITO** (Kubernetes AI Toolchain Operator) for AKS; otherwise a **vLLM**
  Deployment with an OpenAI-compatible API. Justify the engine choice (throughput,
  batching, quantization, GPU SKU fit).
- Front the model with **Azure API Management** (auth, rate-limiting, token-based
  throttling, multi-tenant routing across client deployments).
- Wire **Azure AI Content Safety** as an input/output guardrail.
- Support **prompt versioning** and a hook for **evaluation pipelines** (quality scoring,
  hallucination detection, latency tracking) — at minimum scaffold where MLflow / W&B /
  LangSmith integration plugs in. Implementation can be stubbed; the platform seams must exist.
- Autoscale serving with **KEDA** (e.g. on queue depth / concurrency), and let the GPU pool
  **scale to zero** when idle.

### 4. Observability (production-grade)

- Azure Monitor **managed Prometheus** + **managed Grafana**, Container Insights for logs.
- Dashboards + alerts for: **GPU utilization & memory**, **tokens/sec throughput**,
  **request latency p50/p95/p99**, queue depth, error rate, pod/node/zone health,
  **drift & output-quality** signal hooks, and **cost/token**.
- Alert routing (Action Groups → email/Slack). Set thresholds deliberately low at first so
  a reviewer can verify wiring on day 1, then expose them as variables.

### 5. FinOps (cost is a first-class requirement)

- **Spot** GPU node pool + cluster autoscaler **scale-to-zero**; right-sized requests/limits;
  `ResourceQuota` / `LimitRange` per namespace.
- **OpenCost or Kubecost** for in-cluster cost allocation by namespace/label/tenant.
- **Azure Cost Management budgets + alerts** in Terraform; consistent **cost-allocation
  tagging** enforced via provider default tags + Azure Policy.
- GPU efficiency: time-slicing / MPS or fractional GPU where it fits; document the trade-off.
- Provide a **monthly cost estimate table** (like miniclip's) for steady state, with the
  GPU SKU dominating, and a cheaper variant (smaller SKU / aggressive scale-to-zero).

---

## Conventions to follow (from the reference repos)

- **Pre-commit** wired and documented: terraform `fmt`/`validate`/`tflint`/`terraform-docs`,
  `checkov` (soft-fail), `yamllint`, shellcheck, **detect-secrets** with a baseline. No
  secrets in Git — use Key Vault + Workload Identity; if any local secret files exist, gate
  them behind `.gitignore` / encryption and say so.
- **Naming + tagging** standard defined once and inherited (don't repeat per resource).
- **Testing / TDD** in the T3-2 spirit: the e2e checks are the executable spec. Provide a
  **kind-based** smoke suite for the GitOps + Kustomize logic (controllers reconcile, app
  becomes healthy, rollout is zero-downtime) runnable in CI on push, and document the
  **prod-like validation** path (real AKS + GPU, chaos/HA/load gates on merge to `main`).
  Note explicitly what kind **cannot** validate (GPU, cloud LB, real NSG/CNI enforcement).
- **CI**: GitHub Actions (or Azure DevOps pipelines, per JD) for lint + e2e.

## Documentation deliverables

1. **`README.md`** — architecture (Mermaid diagram), layer table, apply order, how GitOps
   takes over, how to reach the model endpoint.
2. **Decision-justification table** — every non-obvious choice with its rationale (Argo +
   Flux split, KAITO vs vLLM, Spot GPU, private API server, managed vs self-hosted
   Prometheus, OpenCost vs Kubecost, etc.).
3. **Monthly cost estimate** + a cheaper variant.
4. **`CHANGES.md`** — what you built and why, issues spotted beyond scope, trade-offs.
5. **`BONUS.md`** — answer:
   - How do you guarantee the platform "still works in six months" (drift, dependency/model
     upgrades, eval regression gates)?
   - How do you keep GPU cost bounded under bursty 24/7 traffic without dropping requests?
   - How do you test that HA + autoscaling + GitOps rollback actually work?

## Constraints & non-goals

- **Azure only.** Stack per JD: Azure, AKS, Azure DevOps/Terraform, Helm/Kustomize, Azure
  OpenAI, RAG, vector DBs (Weaviate/Milvus/Pinecone), Prometheus/Grafana, API Management,
  AI Content Safety.
- Application/business logic, full RAG ingestion, and real eval datasets are **out of
  scope** — scaffold the seams, don't build the app.
- Everything must `terraform plan` cleanly and be idempotent. Where a step is genuinely
  manual (e.g. SNS-style confirmations, DNS validation, GPU quota requests), call it out
  explicitly as a documented follow-up rather than hiding it.

## Acceptance criteria

- [ ] `terraform apply` across the layers, in documented order, brings up a private AKS
      cluster with system/CPU/GPU(Spot, scale-to-zero) pools.
- [ ] Argo CD **and** Flux are installed and reconciling from Git; the LLM stack lands via
      GitOps, not imperative apply.
- [ ] A top-tier open LLM serves an OpenAI-compatible endpoint behind API Management with
      Content Safety guardrails.
- [ ] Managed Prometheus/Grafana dashboards show GPU, token-throughput, latency, and
      cost/token; alerts route to an Action Group.
- [ ] FinOps controls present: Spot + scale-to-zero, OpenCost/Kubecost, Azure budget alerts,
      enforced tagging; monthly cost estimate documented.
- [ ] Pre-commit, secrets scanning, and a kind-based e2e (CI on push) all pass.
- [ ] README + decision table + cost estimate + CHANGES + BONUS are complete and honest
      about trade-offs and follow-ups.

---

**Begin** by proposing the layer breakdown and the Argo-vs-Flux division of
responsibility, then implement layer by layer (`00` → `60`), keeping each layer's `plan`
clean before moving on.
