# Research prompt — On what compute do OpenAI (Codex), GitHub Copilot, and Anthropic deploy?

> Feed to the `deep-research` skill. Goal: a cited, current (early/mid-2026) picture of the
> cloud + accelerator infrastructure behind these products, with proofs and figures.

## Questions

1. **OpenAI (Codex / GPT / ChatGPT):** which clouds (Azure exclusivity status as of 2026,
   plus Oracle/OCI, CoreWeave, any Google TPU deal), which accelerators (A100→H100→H200→
   GB200/Blackwell), cluster sizes, and the **Stargate** project (partners, scale, $, sites).
   Custom silicon (Broadcom). Where does the **Codex** agent specifically run.
2. **GitHub Copilot:** hosting (Azure), and its **multi-model** routing — does it serve
   OpenAI, Anthropic Claude, and Google Gemini? On whose infrastructure does each run?
3. **Anthropic (Claude):** multi-cloud split — **AWS** (Trainium2/Inferentia, project
   **Rainier** scale) and **Google Cloud** (TPU v5/v6), plus any NVIDIA GPU use. Investment
   ties (Amazon ~$8B, Google). Training vs inference hardware.
4. **Comparison:** rough accelerator counts / cluster scale per org, and the trend toward
   **custom silicon** (Trainium, TPU, OpenAI-Broadcom chip) vs NVIDIA dependence.

## Deliverable

Cited Markdown report saved to `research/frontier-infra-report.md`:
- A per-company section (clouds, accelerators, scale, custom silicon).
- A comparison table (org × cloud(s) × accelerator(s) × approx scale).
- A short "implications for a self-hosted Azure LLM platform" note tying back to this repo
  (why we self-host open weights on a few H100 + use Azure OpenAI for frontier).
- Sources for every claim; flag disclosed/official vs reported/rumored vs estimated, and
  flag anything dated after the research date.
