# notebooks/

Local LLM fine-tune workspace for Calories Guard.

## Files

| File | Purpose |
|---|---|
| `deepseek_finetune.ipynb` | Main notebook — dataset, MLP segmenter, LoRA training, eval, save. |
| `data/{train,val,test}.json` | Persistent 70/15/15 split (re-runs reuse the same split — no leakage). |
| `_run_outputs/` | PNG figures saved by the flat-script runner. |
| `_run_full.log` | Stdout from the most recent end-to-end local run. |
| `calories_guard_adapter/` | LoRA adapter weights produced by cell 20 (gitignored — use git-LFS or release artifact for sharing). |

### Helper scripts (Python, not notebook cells)

| Script | What it does |
|---|---|
| `_smoke_test.py` | CPU smoke test — dataset assembly + MLP segmenter (no GPU needed). |
| `_gpu_smoke.py` | Loads DeepSeek 1.5B in 4-bit + LoRA + 1 forward/backward + 1 generate. Verifies the full notebook will fit on the GPU before committing to a 100-min run. |
| `_run_full.py` | Flat-script runner — executes every code cell of the .ipynb in one Python process. Bypass for the Jupyter kernel crash on Python 3.13 + Windows + zmq. |
| `_inject_outputs.py` | After a successful run, injects the captured stdout + PNG figures back into the .ipynb so the notebook is self-documenting on GitHub. |
| `_update_notebook.py` | One-shot rewrite of dataset / split / eval cells. |
| `_patch_vram_aware.py` | One-shot rewrite of the training cells with the VRAM-aware config. |

## Run on Colab (T4 / L4 / A100)

1. Open `deepseek_finetune.ipynb` in Colab.
2. Uncomment the `pip install` block at the top of cell 2 — Colab base images don't have `peft`, `bitsandbytes`, or current `transformers`.
3. Runtime → Change runtime type → GPU → T4 (or better).
4. Run all. The VRAM-aware config detects ≥ 8 GiB and switches to `MAX_LEN=512`, `batch=2`, `grad_accum=4`, no gradient checkpointing.

## Run locally (CUDA)

Requirements: Python 3.11–3.13, NVIDIA GPU with ≥ 4 GiB VRAM, CUDA-enabled PyTorch.

```bash
# Make sure torch is the CUDA build, not CPU-only:
python -c "import torch; print(torch.__version__, torch.cuda.is_available())"
# Expect: 2.6.0+cu124 True   (or any cu12x build)

# If CPU-only, reinstall:
pip uninstall -y torch
pip install torch --index-url https://download.pytorch.org/whl/cu124

pip install transformers peft bitsandbytes accelerate datasets pythainlp matplotlib
```

### Why a flat-script runner instead of Jupyter?

`jupyter nbconvert --execute` and `jupyter notebook` crash with `DeadKernelError` on
Python 3.13 + Windows due to a zmq/Proactor incompatibility. `_run_full.py` walks
the notebook's `cells` list and `exec`s each code cell in one persistent
namespace, captures stdout per cell, and saves any matplotlib figures to
`_run_outputs/`. Use it like this:

```bash
cd notebooks
python _run_full.py 2>&1 | tee _run_full.log
python _inject_outputs.py   # (optional) replay outputs into the .ipynb
```

## VRAM-aware config

The notebook auto-detects total GPU memory and picks the right knobs:

| Knob | < 8 GiB (e.g. RTX 3050 4 GB) | ≥ 8 GiB (Colab T4) |
|---|---|---|
| `MAX_LEN` | 256 | 512 |
| `BATCH_SIZE` | 1 | 2 |
| `GRAD_ACCUM_STEPS` | 8 | 4 |
| Gradient checkpointing | on | off |

5 LoRA epochs on 105 train samples take ≈ 12 min on T4 / ≈ 110 min on RTX 3050 Ti 4 GB.

## Latest run

2026-04-25 on RTX 3050 Ti 4 GB — see [`docs/AI_LLM_FINETUNE_STATUS.md`](../docs/AI_LLM_FINETUNE_STATUS.md) for metrics, observations, and the TODO list.
