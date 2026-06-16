# Open-Weight LLM Selection for Production Inference on 6× H100 (vLLM on AKS)

Research date: 2026-06-15. Models or specs newer than this date are flagged inline.

> **Scope of confidence.** Every Azure VM spec and the FP8/KV-cache benchmark numbers
> below are taken from **primary** sources (Microsoft Learn, the official vLLM blog,
> Microsoft Azure HPC blog, NVIDIA, Anyscale). VRAM-math results are **estimates** computed
> from those primary formulas and are marked `(est.)`. Throughput numbers are **measured**
> unless marked `(est.)`.

---

## 1. The three topologies (primary-source confirmed)

| Topology | Azure VM | Nodes × GPU | GPU | VRAM/GPU | Total VRAM | Intra-node | Inter-node | TP ceiling |
|---|---|---|---|---|---|---|---|---|
| **(a)** | `Standard_NC40ads_H100_v5` | 6 × 1 | H100 NVL (PCIe) | 94 GB | 564 GB | n/a (1 GPU/VM) | **Ethernet only, 40 Gbps, NO IB/RDMA** | **TP=1** per node |
| **(b)** | `Standard_NC80adis_H100_v5` | 3 × 2 | H100 NVL (PCIe) | 94 GB | 564 GB | **NVLink** (2 GPUs) | Ethernet only, 80 Gbps, NO IB/RDMA | **TP=2** per node |
| **(c)** | `Standard_ND96isr_H100_v5` | 1 × 8 | H100 SXM | 80 GB | 640 GB | **NVLink 4.0** | **400 Gb/s Quantum-2 CX7 IB + GPUDirect RDMA, 3.2 Tbps/VM** | **TP=8** (single node) |

Sources: NC40ads/NC80adis specs and the absence of InfiniBand — Microsoft Learn `ncadsh100v5-series` (updated 2026-04-02). ND96isr specs, NVLink 4.0, IB/RDMA, 3.2 Tbps — Microsoft Learn `ndh100v5-series`.

**Decisive architectural facts:**

- **(a) and (b) have NO fast inter-node fabric.** The NCads H100 v5 page lists only `40,000–80,000 Mbps … NetVSC, ConnectX` Ethernet and **no InfiniBand/RDMA row** — confirmed meaningful because the sibling ND page explicitly *does* list InfiniBand. **Cross-node tensor parallelism is not viable** on (a)/(b); each replica is bounded by what fits in one node (94 GB for (a), 188 GB across NVLink for (b)). [Confirmed, 3-0]
- **(c)** is the only topology with the NVLink + IB fabric needed for very large TP=8 (and, with a second node, TP=8×PP=2) deployments. [Confirmed, 3-0]
- **AKS OS constraint:** H100 GPU node pools on AKS **must use the Ubuntu Linux OS SKU** — A100/H100 VM SKUs are not available with Azure Linux as of 2026-05-05. NC-A100 has since gained Azure Linux 3.0 support, but **all three topologies here are H100 and remain Ubuntu-only.** [Confirmed, 2-1; time-sensitive — recheck before deploy]

---

## 2. VRAM math: the formulas (primary-source confirmed)

**Weights:** `params × bytes/param` → BF16/FP16 = 2 B, FP8 = 1 B, INT4 (AWQ/GPTQ) ≈ 0.5 B (+ small scale/zero overhead).

**Per-token KV cache (bytes):** `2 × num_layers × (num_kv_heads × head_dim) × precision_bytes`. [NVIDIA, 3-0]

**Total KV cache:** `batch × seq_len × 2 × num_layers × hidden_size × sizeof(precision)` — scales **linearly** in batch and sequence length. [NVIDIA, 3-0]

> **Critical correction applied throughout this report:** the NVIDIA total-KV formula uses
> `hidden_size`, which is the **dense MHA upper bound** and *overestimates* KV cache for
> modern **GQA/MLA** models (Llama-3, Qwen3, DeepSeek). For VRAM sizing of those models we
> substitute `num_kv_heads × head_dim`, which is far smaller. [Confirmed, 3-0]

**FP8 KV-cache (e4m3) effect on Hopper:** halves KV storage vs BF16 → per-token KV cost down to **~54% of BF16** in best memory-bound decode cases (measured: ITL slope 4.37e-05 → 2.37e-05 ms/tok on Llama-3.1-8B/H100). [vLLM blog, 3-0]

**Tensor parallelism:** TP=2 **roughly halves per-device weight memory**, freeing room for KV cache / larger batches (NVLink keeps AllReduce cheap; on PCIe-only it is costly). [NVIDIA, 3-0]

**Anchor breakdown (measured, vLLM, Llama-3 8B @ 8192 ctx):** weights 14.96 GiB, framework 0.06 GiB, peak activations 1.23 GiB, KV cache 3.53 GiB. Use this as the "weights + overhead + activations + KV" template. [Anyscale, 3-0]

---

## 3. Fit table — model × topology × precision × VRAM × fits?

VRAM = weights + ~1–2 GB framework/activation overhead. KV cache budget is what remains in the GPU/node after weights. `(est.)` = computed from formulas above; weight figures for 8B/70B/671B are corroborated by primary sources.

| Model | Arch | Params (active) | Ctx | License | Precision | Weights (est.) | Single H100 94GB (a, TP=1) | Node 188GB (b, TP=2) | 8×SXM 640GB (c) |
|---|---|---|---|---|---|---|---|---|---|
| **Llama-3.1-8B** | dense | 8B | 128K | Llama Community | BF16 | ~15 GB (meas.) | ✅ huge KV room | ✅ | ✅ |
| | | | | | FP8 | ~8 GB | ✅ | ✅ | ✅ |
| **Qwen3-30B-A3B** | MoE | 30B (3B act.) | 256K | Apache-2.0 | BF16 | ~60 GB | ✅ KV-tight | ✅ ample | ✅ |
| | | | | | FP8 | ~30 GB | ✅ ample KV | ✅ | ✅ |
| **Qwen3-32B** | dense | 32B | 128K | Apache-2.0 | BF16 | ~64 GB | ✅ KV-tight | ✅ | ✅ |
| | | | | | FP8 | ~32 GB | ✅ | ✅ | ✅ |
| **Llama-3.3-70B** | dense | 70B | 128K | Llama Community | BF16 | ~140 GB (meas.) | ❌ (>94) | ✅ TP=2 (tight KV) | ✅ TP=2/4 |
| | | | | | FP8 | ~70 GB | ✅ KV-tight | ✅ ample | ✅ |
| | | | | | AWQ/GPTQ-INT4 | ~35–40 GB | ✅ good KV room | ✅ | ✅ |
| **Qwen3-235B-A22B** | MoE | 235B (22B act.) | 256K | Apache-2.0 | BF16 | ~470 GB | ❌ | ❌ (>188) | ✅ TP=8 |
| | | | | | FP8 | ~235 GB | ❌ | ❌ | ✅ TP=8 |
| | | | | | INT4 | ~120 GB | ❌ | ❌ (>188, MoE shard) | ✅ TP=8 |
| **DeepSeek-V3/R1** | MoE | 671B (37B act.) | 128K | DeepSeek (MIT-style, commercial OK) | FP8 | ~671–685 GB | ❌ | ❌ | ❌ at FP8 — needs **16 GPU / 2 nodes (TP=8×PP=2)** |
| | | | | | AWQ/GPTQ-INT4 | ~335 GB | ❌ | ❌ | ✅ single 8×SXM (tight) |
| **Llama-3.1-405B** | dense | 405B | 128K | Llama Community | FP8 | ~405 GB | ❌ | ❌ | ✅ TP=8 (KV-tight) |
| | | | | | INT4 | ~200–210 GB | ❌ | ❌ | ✅ TP=8 |

Notes: ✅ = weights + working KV fit; "KV-tight" = fits but limits concurrency/context. DeepSeek-V3.2-Exp exists on HF (newer variant, same ~671B class) — flagged as newer than typical stable selection.

---

## 4. Largest quality model per tier

- **Single H100 94 GB (TP=1, topology a):** the practical quality ceiling is a **~32B-class dense model (Qwen3-32B) or a 30B MoE (Qwen3-30B-A3B) at BF16**, or a **70B-class model at AWQ/GPTQ-INT4** (~35–40 GB weights, leaving ~50 GB for KV). FP8 70B (~70 GB) also fits but with constrained KV/concurrency. So a quantized 70B *does* fit one 94 GB card. [70B weight 140 GB BF16 confirmed 2-1; Qwen3 lineup confirmed 3-0]
- **Needs TP=2 (topology b, 188 GB NVLink):** **Llama-3.3-70B at BF16** (~140 GB) — Anyscale *recommends* TP=4 for headroom, but 140 GB physically fits 2×94 GB with constrained KV; TP=2 on NVLink is the right home for full-precision 70B. [Confirmed 2-1]
- **Genuinely needs 8× SXM + NVLink/IB (topology c):** **Qwen3-235B-A22B**, **Llama-3.1-405B**, and **DeepSeek-V3/R1 671B**. DeepSeek-R1 at **native FP8 does NOT fit a single 8×H100 node** (~671–685 GB > 640 GB) and requires **16 H100 / 2 nodes (TP=8×PP=2)** — confirmed by Microsoft's own NDv5 benchmark. It fits a single 8×SXM node only via **AWQ/GPTQ-INT4** (~335 GB). [Confirmed 3-0, multiple primary]

---

## 5. Throughput / latency expectations on H100 (measured)

- **Llama-3.1-8B, FP16, single H100 80 GB (ND-H100-v5), chat profile:** generation **~6067 tok/s**, prompt **~2667 tok/s**, KV-cache hit ~75%, zero waiting requests. [Microsoft Azure HPC, 3-0 — measured]
- **FP8 KV-cache on Hopper (Llama-3.1-8B under load):** **+14.9% output throughput, +13.0% faster total runtime, −14.8% median ITL** vs BF16; KV per-token cost down to ~54% of BF16 in best decode cases. [vLLM blog, 3-0 — measured]
- **DeepSeek-R1 FP8, 8×H100 TP=8×PP=2 (16 GPU):** documented ~821 tok/s output. [Confirmed 3-0]

> Caveat: the +15%/−15% FP8 figures are single-config measurements (concurrency 8, ~20k in / 2k out), not a universal speedup. FP8 *weight* quantization roughly doubling throughput was a marketing claim that was **refuted** in verification — do not assume 2× from FP8 alone.

---

## 6. Multi-model vs one big model (multi-tenant consultancy)

For a 24/7 multi-tenant consultancy on a **fixed 6-GPU budget with no inter-node IB** in (a)/(b), **a fleet of right-sized models beats one giant model:**

- The giant-model option (DeepSeek-R1 / 405B / 235B) is **only servable on topology (c)**, and R1 at FP8 needs *two* such nodes — outside the 6× budget. Committing all GPUs to one model also creates a single point of failure and forces every cheap request (RAG, classification, embeddings) through an expensive model.
- A **multi-model fleet** maps cleanly onto independent 94 GB GPUs (topology a) or NVLink pairs (topology b): a primary chat/agent model, a dedicated coding model, and small embedding/rerank models, each scaled with whole-GPU replicas. This maximizes utilization, isolates tenants, and lets latency-sensitive vs throughput-sensitive workloads run on separate replicas.
- Use **Azure OpenAI as the managed fallback / burst + frontier tier** (e.g., when a request genuinely needs 405B/R1-class quality) rather than buying topology (c) outright.

---

## 7. When MIG beats whole-GPU replicas

H100 MIG partitioning wins for **small, memory-light models where a whole 94 GB GPU is wasteful**: **embeddings, rerankers, and ≤3–4B classifiers**. A 7-slice MIG layout turns one H100 into several isolated instances, each comfortably holding a sub-2 GB embedding/reranker with its own SM/VRAM partition — better tenant isolation and far higher GPU efficiency than running one tiny model per whole card. Use **whole-GPU (or NVLink-pair) replicas** for the 8B–70B serving/coding models, which need the full memory bandwidth and KV budget. (MIG mechanism is standard Hopper capability; no single primary benchmark surfaced in verification — treat slice counts as planning guidance, validate empirically.)

---

## 8. Concrete recommendation

| Role | Model | Precision | Topology | gpu_node_vm_size | tensor-parallel-size | Rationale |
|---|---|---|---|---|---|---|
| **Primary serving / agents / RAG** | **Llama-3.3-70B** | **FP8** (weights + FP8 KV-cache) | (b) NVLink pair, or (a) single card if KV-tight acceptable | `Standard_NC80adis_H100_v5` | **2** | ~70 GB weights fit; TP=2 over NVLink gives ample KV for 24/7 concurrency; FP8 KV-cache adds ~+15% throughput. Use INT4 on (a) single card for cheaper replicas. |
| **Coding** | **Qwen3-32B** (dense; Apache-2.0) | **FP8** | (a) single H100 | `Standard_NC40ads_H100_v5` | **1** | ~32 GB weights on 94 GB leaves large KV for long code contexts; Apache-2.0 is clean commercially; TP=1 = simplest replica scaling. |
| **Embeddings + reranker** | small embedding model + cross-encoder reranker | FP16 | (a)/(b) **MIG slices** | `Standard_NC40ads_H100_v5` (MIG-partitioned) | **1** per slice | Sub-2 GB each; MIG packs several per card for efficiency + tenant isolation. |
| **Frontier fallback** | Azure OpenAI (managed) | — | managed | — | — | For 405B/R1-class quality bursts without owning topology (c). |

### What to set in tfvars / vLLM args

**Primary (Llama-3.3-70B FP8 on NVLink pair, topology b):**
```hcl
# tfvars
gpu_node_vm_size       = "Standard_NC80adis_H100_v5"   # 2× H100 NVL 94GB, NVLink
gpu_node_os_sku        = "Ubuntu"                       # H100 not available on Azure Linux
tensor_parallel_size   = 2
```
```bash
# vLLM
vllm serve meta-llama/Llama-3.3-70B-Instruct \
  --tensor-parallel-size 2 \
  --quantization fp8 \
  --kv-cache-dtype fp8_e4m3 \
  --max-model-len 32768
```

**Coding (Qwen3-32B FP8, single card, topology a):**
```hcl
gpu_node_vm_size       = "Standard_NC40ads_H100_v5"   # 1× H100 NVL 94GB
gpu_node_os_sku        = "Ubuntu"
tensor_parallel_size   = 1
```
```bash
vllm serve Qwen/Qwen3-32B \
  --tensor-parallel-size 1 \
  --quantization fp8 \
  --kv-cache-dtype fp8_e4m3 \
  --max-model-len 65536
```

**Embeddings/reranker:** deploy on MIG-partitioned `Standard_NC40ads_H100_v5`, one vLLM (or TEI) instance per MIG slice, `tensor-parallel-size 1`.

**Reserve topology (c) `Standard_ND96isr_H100_v5` (8×SXM 80GB, NVLink+IB)** only if you must self-host a frontier model: Qwen3-235B-A22B or Llama-3.1-405B at FP8 with `--tensor-parallel-size 8`, or DeepSeek-R1 via AWQ-INT4 single-node (TP=8) / FP8 across two nodes (TP=8, PP=2).

---

## Sources

- Microsoft Learn — `ncadsh100v5-series` (NC40ads/NC80adis specs, no InfiniBand). Primary.
- Microsoft Learn — `ndh100v5-series` (ND96isr 8×H100 80GB, NVLink 4.0, 400 Gb/s CX7 IB, 3.2 Tbps). Primary.
- Microsoft Learn — `aks/use-nvidia-gpu` (H100 Ubuntu-only on AKS, updated 2026-05-05). Primary.
- vLLM blog — `2026-04-22-fp8-kvcache` (FP8 KV-cache halving, 54%, +14.9%/+13.0%/−14.8%). Primary, measured.
- Microsoft Azure HPC blog — Llama-3.1-8B vLLM benchmark (H100 chat ~6067 gen tok/s). Primary, measured.
- Microsoft Azure HPC blog — DeepSeek-R1 vLLM on ND-H100-v5 (16 H100 / 2 nodes for FP8). Primary, measured.
- NVIDIA — "Mastering LLM Techniques: Inference Optimization" (KV-cache formulas, TP weight halving). Primary.
- Anyscale — `llm/serving/gpu-guidance` (8B memory breakdown; 70B 140 GB/TP=4; R1 720 GB/16 GPU TP=8 PP=2). Primary.
- DeepSeek-V3 Technical Report (arXiv:2412.19437) + Raschka architecture comparison (671B MoE, 37B active, MLA). Primary + blog.
- Qwen3 official blog (lineup: dense 0.6–32B + MoE 30B-A3B/235B-A22B, Apache-2.0). Primary.

**Refuted during verification (not used):** Spheron "FP8 doubles throughput / DeepSeek V3 1342 GB FP16 / Llama-70B FP16 needs 8×H100" claims and the "DeepSeek V3.2 = 685B / 640 GB FP8 fits 8×H100" claim.
