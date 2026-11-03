# Skills audit

Static structural audit of every SKILL.md. Does not execute skills, validate external APIs, or certify licenses or runtime compatibility.

- Skill folders indexed: **247**
- Remaining symlinks: **0**
- Duplicate declared-name groups: **45**
- Identical SKILL.md groups: **45**

## Agent classifications

| Classification | Count |
| --- | ---: |
| Claude-oriented | 3 |
| Model-agnostic | 235 |
| Multi-platform | 8 |
| OpenAI / Codex-oriented | 1 |

Classifications are heuristic with reviewed overrides, not compatibility certifications. See `catalog/overrides.json` and each website detail for evidence. Optional `agents/openai.yaml` does not make a skill Codex-only. Provider mentions describe content, not necessarily dependencies.

## Duplicate declared names

Keep one folder from each group when installing by declared name. Identical instructions do not establish that supporting assets are identical. No duplicates were deleted.

- `0-autoresearch-skill`, `autoresearch`
- `a-evolve`, `evolving-ai-agents`
- `accelerate`, `huggingface-accelerate`
- `audiocraft`, `audiocraft-audio-generation`
- `autogpt`, `autogpt-agents`
- `awq`, `awq-quantization`
- `bigcode-evaluation-harness`, `evaluating-code-models`
- `bitsandbytes`, `quantizing-models-bitsandbytes`
- `blip-2`, `blip-2-vision-language`
- `cosmos-policy`, `evaluating-cosmos-policy`
- `crewai`, `crewai-multi-agent`
- `distributed-llm-pretraining-torchtitan`, `torchtitan`
- `evaluating-llms-harness`, `lm-evaluation-harness`
- `experiment-tracking-swanlab`, `swanlab`
- `fine-tuning-openvla-oft`, `openvla-oft`
- `fine-tuning-serving-openpi`, `openpi`
- `fine-tuning-with-trl`, `trl-fine-tuning`
- `flash-attention`, `optimizing-attention-flash`
- `gguf`, `gguf-quantization`
- `hqq`, `hqq-quantization`
- `implementing-llms-litgpt`, `litgpt`
- `lambda-labs`, `lambda-labs-gpu-cloud`
- `langsmith`, `langsmith-observability`
- `mamba`, `mamba-architecture`
- `megatron-core`, `training-llms-megatron`
- `miles`, `miles-rl-training`
- `modal`, `modal-serverless-gpu`
- `nemo-evaluator`, `nemo-evaluator-sdk`
- `nnsight`, `nnsight-remote-interpretability`
- `openrlhf`, `openrlhf-training`
- `peft`, `peft-fine-tuning`
- `phoenix`, `phoenix-observability`
- `pyvene`, `pyvene-interventions`
- `qdrant`, `qdrant-vector-search`
- `rwkv`, `rwkv-architecture`
- `saelens`, `sparse-autoencoder-training`
- `segment-anything`, `segment-anything-model`
- `serving-llms-vllm`, `vllm`
- `simpo`, `simpo-training`
- `skypilot`, `skypilot-multi-cloud-orchestration`
- `slime`, `slime-rl-training`
- `stable-diffusion`, `stable-diffusion-image-generation`
- `torchforge`, `torchforge-rl-training`
- `transformer-lens`, `transformer-lens-interpretability`
- `verl`, `verl-rl-training`

## Findings to review

The original 23 missing reference links were repaired with labeled local guides and pinned official source snapshots. See [reference provenance](REFERENCES.md). Remaining findings below describe the current files.

Environment paths and relative links may be examples or refer to consumer projects. They are reported, not rewritten blindly. Vendoring removes filesystem symlink dependencies; scripts may still require packages, credentials, external services, or data described in their instructions.

- `lambda-labs`: Environment-specific path (review) — line 285
- `lambda-labs-gpu-cloud`: Environment-specific path (review) — line 285
