# Research prompt — Which open-weight LLMs to serve on a 6× H100 AKS cluster

> Feed this to the `deep-research` skill (or an analyst). Scope is **production
> inference serving** for the `azure-llmops` platform (vLLM on AKS), not training.

## Context

- **Hardware:** 6× NVIDIA H100. Azure has no 6-GPU SKU, so the fleet is one of:
  - `Standard_NC40ads_H100_v5` × 6 — 6 nodes × 1× H100 **NVL 94 GB**, **no fast
    inter-node interconnect** (each GPU effectively standalone).
  - `Standard_NC80adis_H100_v5` × 3 — 3 nodes × 2× H100 NVL 94 GB, **NVLink within
    node** (tensor-parallel=2 per node).
  - `Standard_ND96isr_H100_v5` — 8× H100 **SXM 80 GB**, NVLink + InfiniBand (the only
    topology for TP/PP across many GPUs); note this is 8, not 6.
- **Serving stack:** vLLM (OpenAI-compatible), KEDA autoscaling, behind APIM. Azure
  OpenAI exists as a managed fallback.
- **Use cases (AI consultancy):** 24/7 agents, RAG/knowledge systems, automations, some
  coding assistance. Multi-tenant. Latency and cost-per-token matter.
- **Date:** mid-2026 — prefer current model versions; flag anything released after the
  research date.

## Questions to answer

1. **Which open-weight models are realistically servable** on each of the three
   topologies above? Map each candidate to: parameter count, architecture (dense/MoE),
   context window, license (commercial use?), and **VRAM footprint** at FP16/BF16, FP8,
   and AWQ/GPTQ-INT4 — with the arithmetic (weights + KV cache for a stated context/
   concurrency).
2. **What fits where:**
   - Largest quality model that fits on **1× H100 94 GB** (the NC40ads case, TP=1) —
     incl. quantized 70B-class.
   - What needs **TP=2** (NC80adis) and what genuinely needs **8× SXM + NVLink/IB**
     (e.g. DeepSeek-V3/R1-class 600B+ MoE, Llama-405B).
3. **Throughput / latency** expectations on H100 with vLLM (tokens/s, concurrency) per
   tier, and how FP8 on Hopper changes it.
4. **Multi-model vs one big model:** is it better to run 6 independent replicas of a
   strong mid-size model, 3× TP=2 of a 70B, or pool for one frontier model? Trade-offs
   for a multi-tenant consultancy.
5. **MIG partitioning** on H100: when does slicing a GPU into smaller instances beat a
   whole-GPU replica (small models, embeddings, rerankers)?
6. **Concrete recommendation** for this platform: a primary serving model + a coding
   model + an embeddings/reranker, each mapped to a topology and quantization, with the
   reasoning. Note the matching `gpu_node_vm_size` / `tensor-parallel-size`.

## Deliverable

A cited Markdown report saved to `research/model-selection-6xH100.md`:
- A **fit table** (model × topology × precision × VRAM × fits?).
- Per-tier recommendations with VRAM math shown.
- A short "what to set in tfvars / vLLM args" mapping back to the platform.
- Sources for every model spec, VRAM, and throughput claim; flag estimates vs measured.
