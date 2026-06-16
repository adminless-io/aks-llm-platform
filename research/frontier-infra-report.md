# Frontier LLM Compute Infrastructure: OpenAI, GitHub Copilot, and Anthropic (early/mid-2026)

*Research date: 2026-06-16. Source-flagging convention: **[disclosed/official]** = first-party press release or product documentation; **[reported]** = reputable third-party press; **[estimated]** = derived/approximate figure. Forward-looking figures (planned capacity, future chip generations) are flagged inline. Items dated after the research date are flagged explicitly; none of the load-bearing claims in this report are post-dated beyond 2026-06-16.*

---

## Executive summary

As of mid-2026, the three coding-AI ecosystems sit on three distinct infrastructure footprints. **OpenAI** has decisively broken out of Azure exclusivity: its compute is now anchored by the **Stargate** datacenter program (nearly 7 GW planned and over $400B committed over three years as of the Sept 2025 expansion, on track toward an original $500B / 10 GW goal), heavily built on **Oracle/OCI** capacity and NVIDIA **GB200/Blackwell** racks, plus a **Broadcom** collaboration to deploy 10 GW of OpenAI-designed custom accelerators. **GitHub Copilot** is a multi-model router: it serves OpenAI GPT models (on OpenAI + GitHub's Azure), Anthropic Claude models (on AWS, Anthropic, and GCP), and Google Gemini (on GCP), with each provider's models running on that provider's own infrastructure. **Anthropic** runs Claude across three accelerator platforms — **AWS Trainium** (Project Rainier, ~500,000 Trainium2 chips, scaling past 1M; AWS is the primary training/cloud partner with up to 5 GW of new capacity), **Google Cloud TPUs** (up to 1M TPUs, >1 GW online in 2026, multi-GW next-gen TPU via Google+Broadcom from 2027), and **NVIDIA GPUs**. The clear industry trend is a parallel push into custom silicon (AWS Trainium, Google TPU, OpenAI-Broadcom accelerators) layered on top of continued NVIDIA dependence.

---

## 1. OpenAI

### Clouds
- Azure is no longer the exclusive cloud. OpenAI's largest near-term capacity comes through the **Stargate** program, with **Oracle Cloud Infrastructure (OCI)** as a flagship delivery partner and **CoreWeave** in the mix. **[disclosed/official]**
- **Oracle/OCI:** A July 2025 agreement covers **up to 4.5 GW** of additional Stargate capacity, a partnership exceeding **$300B over five years**; Oracle began delivering the first NVIDIA GB200 racks in June 2025 and OpenAI started early training/inference workloads on them. **[disclosed/official]** *(The $300B dollar figure was first publicly reported Sept 2025; the underlying agreement is dated July 2025.)*

### Accelerators
- Current frontier hardware is NVIDIA **GB200 / Blackwell** racks (the Abilene, TX flagship campus on OCI has been reported at ~450,000 GB200 GPUs). **[disclosed/official]** for GB200 delivery; **[reported]** for the Abilene GPU count.

### Cluster sizes / Stargate scale
- **Stargate (Sept 2025 expansion):** nearly **7 GW** of planned capacity and over **$400B** in investment over three years, with five new sites added on top of the Abilene flagship and the CoreWeave projects. **[disclosed/official — forward-looking planned figure]**
- **Stargate (original, Jan 2025):** a **$500B / 10 GW** commitment, targeted to be secured by end of 2025. **[disclosed/official — forward-looking planned figure]**

### Custom silicon (Broadcom)
- OpenAI and **Broadcom** announced a strategic collaboration to deploy **10 GW** of custom, **OpenAI-designed** AI accelerators. OpenAI designs the accelerators and systems; Broadcom co-develops and deploys them (built on Broadcom's Ethernet stack). **[disclosed/official]**
  - Nuance: TSMC is the actual fabricator (3nm process per multiple reports); Broadcom provides ASIC development, networking, and deployment, not fabrication. **[reported]**
  - **Post-research-date caveat (flagged):** subsequent reporting (May 2026, The Information/Sherwood) noted an ~$18B financing snag for phase one (codenamed Project Nexus, ~1.3 GW). This qualifies execution/financing risk but does not contradict the announced collaboration. **[reported, post-dated]**

### Where Codex runs
- Not separately disclosed at the infrastructure level in the verified sources. Via GitHub surfaces, the **Codex** third-party coding agent routes to OpenAI models (GPT-5.2-Codex, GPT-5.3-Codex, GPT-5.4), which are hosted on OpenAI's own infrastructure and GitHub's Azure infrastructure (see §2). **[disclosed/official for routing; OpenAI's direct Codex backend cloud not independently confirmed — open question]**

---

## 2. GitHub Copilot

GitHub Copilot is a multi-model router. Each provider's models run on that provider's infrastructure (plus GitHub's Azure for OpenAI models). All per the official GitHub Enterprise Cloud model-hosting documentation. **[disclosed/official]**

- **OpenAI GPT models** (GPT-5 mini, GPT-5.3-Codex, GPT-5.4 family, GPT-5.5): hosted by **OpenAI and GitHub's Azure infrastructure**, under a **zero data retention** agreement with OpenAI. **[disclosed/official]**
- **Anthropic Claude models** (Haiku 4.5, Sonnet 4.5/4.6, Opus 4.5–4.8, Fable 5): hosted across **Amazon Web Services, Anthropic PBC, and Google Cloud Platform**. **[disclosed/official]**
- **Google Gemini models** (Gemini 2.5 Pro, 3 Flash, 3.1 Pro, 3.5 Flash): hosted on **Google Cloud Platform**. **[disclosed/official]**

### Third-party coding agents on github.com (April 2026)
- GitHub.com offers model selection for two third-party coding agents — **Claude** (Anthropic models) and **Codex** (OpenAI models). **[disclosed/official]**
- The **Claude** agent routes to Anthropic models (Sonnet 4.6, Opus 4.6, Sonnet 4.5, Opus 4.5); the **Codex** agent routes to OpenAI models (GPT-5.2-Codex, GPT-5.3-Codex, GPT-5.4). **[disclosed/official]**

---

## 3. Anthropic

Anthropic is multi-cloud, running Claude across **three accelerator platforms: AWS Trainium, Google TPUs, and NVIDIA GPUs** — matching workloads to the best-suited chips. **[disclosed/official]**

### AWS (primary cloud + training partner)
- **Amazon remains Anthropic's primary cloud and training partner** for mission-critical workloads, even as Anthropic expands TPU capacity with Google. The commitment spans current and future Trainium generations (**Trainium2, Trainium3, Trainium4**, plus future generations). **[disclosed/official]**
- **Project Rainier:** one of the world's largest AI compute clusters, built with **nearly half a million (~500,000) AWS Trainium2 chips**, used by Anthropic to train and deploy Claude; described as **70% larger than any prior AWS AI computing platform** and providing **more than 5×** the compute Anthropic used to train its previous models. **[disclosed/official; vendor self-comparison for the "70%" and "5×" figures]**
- Anthropic **currently uses over 1 million Trainium2 chips** to train and serve Claude (the >1M milestone, originally projected "by end of year," has been reached per the April 2026 disclosure). **[disclosed/official]**
- **Amazon–Anthropic expansion (April 2026):** up to **5 GW** of new compute capacity for training and deploying Claude; Amazon investing **up to ~$25B more** ($5B now + up to $20B), Anthropic committing **$100B+** to AWS over ten years. **[disclosed/official]**

### Google Cloud (TPUs)
- Under the expanded Oct 2025 deal, Anthropic gets access to **up to 1 million Google Cloud TPU chips**, **worth tens of billions of dollars**, with **well over a gigawatt** of capacity coming online in **2026**. **[disclosed/official]**
- **Google + Broadcom (April 2026):** an agreement for **multiple gigawatts of next-generation TPU capacity** expected to come online **starting in 2027** (Broadcom co-designs Google's TPUs; ~3.5 GW / ~$35B scale reported). **[disclosed/official for the deal; scale figures reported]**

### NVIDIA GPUs
- NVIDIA GPUs are one of the three platforms Claude runs on, though at smaller relative scale than the Trainium (Rainier) and Google TPU buildouts. **[disclosed/official for use; relative scale estimated]**

### Investment ties
- **Amazon:** ~$8B prior; up to ~$25B more announced April 2026. **[disclosed/official]**
- **Google:** TPU deal worth tens of billions; equity/investment ties not quantified in verified sources here. **[disclosed/official for deal value; equity stake = open question]**

---

## 4. Comparison

| Org | Clouds | Accelerators | Approx. scale / commitment | Custom silicon |
|---|---|---|---|---|
| **OpenAI** | Oracle/OCI (flagship), CoreWeave; Azure (still a partner, no longer exclusive) | NVIDIA GB200/Blackwell (Abilene ~450k GB200, reported); custom OpenAI-designed accelerators (from H2 2026) | Stargate: ~7 GW planned / $400B+ (Sept 2025); $500B / 10 GW original goal; Oracle up to 4.5 GW / $300B+ | **OpenAI-designed + Broadcom: 10 GW** (TSMC fabs, Broadcom Ethernet/deploy) |
| **GitHub Copilot** | Azure (for OpenAI + GitHub-hosted); routes to AWS/GCP/Anthropic for those providers' models | Inherits each provider's accelerators | N/A (router, not a trainer) | None of its own; rides providers' silicon |
| **Anthropic** | AWS (primary), Google Cloud; NVIDIA GPUs | AWS Trainium2/3/4; Google TPU (v5/v6 gen, next-gen from 2027); NVIDIA GPUs | Rainier ~500k Trainium2 → 1M+; up to 5 GW new AWS; up to 1M Google TPUs / >1 GW in 2026; multi-GW next-gen TPU from 2027 | Uses **AWS Trainium** + **Google TPU** (Broadcom-co-designed); does not design its own |

### Industry trend
Every frontier player is hedging against NVIDIA dependence with custom silicon while still consuming large volumes of NVIDIA GPUs: **AWS Trainium**, **Google TPU**, and the new **OpenAI–Broadcom** accelerator each represent vertically integrated, model-informed silicon. OpenAI's GB200 buildout and Anthropic's continued NVIDIA GPU use show NVIDIA remains structurally important even as custom-ASIC capacity scales into the multi-GW range.

---

## Implications for a self-hosted Azure LLM platform

- **Azure is no longer the gravitational center of frontier compute.** OpenAI's marginal capacity growth is on Oracle/OCI and custom Broadcom silicon, not Azure. A self-hosted Azure LLM platform should not assume privileged access to the newest OpenAI hardware or capacity; plan for multi-cloud or model-router patterns (the GitHub Copilot model is the reference architecture: route per-model to the provider/cloud that hosts it).
- **Custom silicon is now first-class for inference economics.** If cost-per-token matters, the relevant comparators (Trainium, TPU) are not available on Azure; an Azure-bound platform is effectively committing to NVIDIA GPU pricing/availability. Budget and capacity-planning should reflect NVIDIA supply constraints.
- **Multi-model routing + zero-data-retention contracts are the emerging norm.** GitHub Copilot's documented pattern (collective hosting across OpenAI/AWS/GCP with ZDR agreements) is a practical template for a compliant self-hosted router on Azure that calls out to multiple model providers.
- **Time-sensitivity / financing risk.** Several of the largest commitments (Stargate $400B+/7 GW, OpenAI-Broadcom 10 GW, Anthropic 5 GW AWS / multi-GW TPU) are forward-looking and subject to financing and buildout risk (e.g., the post-research-date Project Nexus financing snag). Treat headline GW/$ figures as planned, not realized, capacity.

---

## Sources

**Primary / disclosed-official**
- OpenAI — Five new Stargate sites: https://openai.com/index/five-new-stargate-sites/
- OpenAI — Stargate 4.5 GW Oracle partnership (referenced via the five-sites release)
- OpenAI × Broadcom strategic collaboration: https://openai.com/index/openai-and-broadcom-announce-strategic-collaboration/ (mirrored on investors.broadcom.com)
- GitHub Copilot model hosting docs: https://docs.github.com/en/enterprise-cloud@latest/copilot/reference/ai-models/model-hosting
- GitHub changelog — model selection for Claude and Codex agents: https://github.blog/changelog/2026-04-14-model-selection-for-claude-and-codex-agents-on-github-com/
- Anthropic × Amazon compute: https://www.anthropic.com/news/anthropic-amazon-compute
- AWS — Project Rainier: https://www.aboutamazon.com/news/aws/aws-project-rainier-ai-trainium-chips-compute-cluster
- Amazon — additional $5B investment in Anthropic: https://www.aboutamazon.com/news/company-news/amazon-invests-additional-5-billion-anthropic-ai
- Google Cloud — Anthropic to expand use of Google Cloud TPUs: https://www.googlecloudpresscorner.com/2025-10-23-Anthropic-to-Expand-Use-of-Google-Cloud-TPUs-and-Services
- Anthropic × Google × Broadcom partnership: https://www.anthropic.com/news/google-broadcom-partnership-compute

**Reported (third-party press, corroborating)**
- CNBC (Google–Anthropic TPU deal; Amazon $25B Anthropic deal, Apr 2026)
- DataCenterDynamics (Project Rainier ~500k Trainium2; 1M+ TPUs; Abilene GB200 counts)
- Bloomberg, Reuters, Data Center Frontier, Constellation Research, Technology Magazine, Data Centre Magazine (Stargate, Rainier corroboration)

**Reported — post-research-date (flagged)**
- The Information / Sherwood (May 2026) — OpenAI-Broadcom Project Nexus ~$18B phase-one financing snag

---

## Caveats
- Headline gigawatt and dollar figures (Stargate 7 GW/$400B+, $500B/10 GW; OpenAI-Broadcom 10 GW; Anthropic 5 GW AWS, 1M TPUs/>1 GW, multi-GW from 2027) are **planned/forward-looking corporate commitments**, not built/realized capacity.
- "70% larger," "5× compute," and "world's largest cluster" for Project Rainier are **vendor self-comparisons**, accurately attributed but not independently benchmarked.
- Per-model hosting in GitHub Copilot docs is stated **collectively** (e.g., "AWS, Anthropic PBC, and GCP" for all Claude models) rather than mapping each individual model to a specific cloud.
- The OpenAI-Broadcom Project Nexus financing item post-dates the research window (May 2026) and reflects execution risk only.
