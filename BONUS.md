# Bonus answers

## 1 — How do you keep the platform working in six months? (drift, upgrades, eval gates)

The JD's core anxiety is "still works after go-live." Defenses, layer by layer:

1. **GitOps is the anti-drift engine.** Argo CD (`selfHeal: true`) and Flux continuously
   reconcile cluster state to Git. A hand-edit on the cluster is reverted; a change is only
   real once it's a commit. Terraform owns the Azure substrate; a scheduled `plan` in CI
   surfaces infra drift the same way.
2. **Everything is pinned.** Helm chart versions, Kubernetes version, and (in prod) the
   serving image **by digest** and the model **by revision**. Renovate/dependabot proposes
   bumps as PRs — upgrades are reviewed diffs, not silent `latest` drift.
3. **Eval regression gate.** The platform exposes the seam (MLflow on Azure ML / LangSmith;
   the private-link zone is pre-created). A model or prompt change runs an automated eval
   suite — quality score, hallucination rate, latency — and **must clear a threshold before
   promotion**. This is the LLM analogue of a test gate; it's what stops a "better" prompt
   silently regressing answer quality. Prompts are versioned in Git like code.
4. **Observability with teeth.** `GPUIdleButProvisioned` catches a broken scale-to-zero
   (silent cost creep); `LLMLatencyHigh`/`GPUSaturated` catch capacity drift; the Azure
   budget catches spend drift. Alerts route to one Action Group.
5. **Supply-chain durability.** ACR pull-through cache + image pinned by digest means an
   upstream registry outage or a deleted tag doesn't break a scale-out six months later.

## 2 — How do you keep GPU cost bounded under bursty 24/7 traffic without dropping requests?

The tension: GPUs are the cost, but cold-starting one on a request spike drops latency (or
requests). The design resolves it on three tiers:

1. **Scale-to-zero floor, warm-on-demand.** GPU pool `min_count = 0` + KEDA
   `minReplicaCount: 0`: idle = zero GPU spend. KEDA scales on `vllm_num_requests_running`,
   the autoscaler adds Spot nodes.
2. **Absorb the cold-start gap with a fallback.** A cold A100 is minutes to ready. APIM
   fails the overflow/cold window over to **Azure OpenAI** (pay-go, no GPU floor) so
   requests are served while the GPU pool warms — bounded cost, no drops.
3. **Bounded burst, fair sharing.** Cluster autoscaler `max_count` caps GPU spend; APIM
   `llm-token-limit` meters tokens per tenant so one client can't exhaust the fleet;
   `spot_max_price = -1` avoids price-based eviction mid-request. For steady high load,
   raise the warm floor (prod overlay `minReplicaCount: 1`) — trading a fixed GPU cost for
   zero cold starts. Prod can add a small **on-demand** GPU node for the floor + **Spot**
   for burst (the standard cost/reliability split).

Net: idle→\$0 GPU, spikes→served by fallback then warm GPUs, sustained load→bounded by
`max_count` and metered per tenant.

## 3 — How do you test that HA / autoscaling / GitOps rollback actually work?

The e2e checks are the **executable spec** (TDD): each requirement starts as a failing
assertion, the manifests change until it's green.

### Runs today (kind, CI on push) — `test/run-test.sh`
All overlays build; the base applies; the Service gets endpoints (selector correct); a
**zero-downtime rolling update** does 0 failed requests; the **PDB** exists. kind validates
*logic* — not GPU, Spot, managed Prometheus/Grafana, or APIM.

### Prod-like gate (real AKS, on merge to `main`)
A dedicated validation subscription configured like prod (same K8s version, Cilium, real
LB, GPU SKU). The promotion flow:

`PR → kind e2e (push) → merge → deploy to validation AKS → HA/chaos/load gates → promote (GitOps)`

Gates that need real cloud behaviour:
- **Autoscaling:** drive load with k6 → assert KEDA scales replicas, the GPU node is added,
  and after idle the pool returns to **zero** (assert node count + cost).
- **Spot eviction:** simulate eviction (delete the GPU node / Azure Chaos Studio) under
  load → assert APIM fails over to Azure OpenAI with no 5xx, then recovers onto a new node.
- **Zone failure:** cordon a zone's nodes under load → service stays up (topology spread +
  PDB).
- **GitOps rollback:** push a bad image digest → Argo syncs, health check fails → `git
  revert` → Argo reconciles back. Assert the bad version never serves traffic (rollback is
  a Git operation, and it's tested as one).
- **Guardrail:** send unsafe content → assert Content Safety blocks it and the event is
  logged.

The point: HA and rollback claims are only believed once a test *forces* the failure and
the platform is observed surviving it.
