"""Smoke-test the `local` LLM provider with the LoRA adapter.

Wires LLM_PROVIDER=local + the adapter at notebooks/calories_guard_adapter
and runs three Calories Guard prompts end-to-end through the same
`generate()` function used by the chat / recipe-fill routers.

Run from repo root:
    python -m backend.scripts.test_local_llm

Requires: torch (CUDA), transformers, peft, bitsandbytes.
"""
from __future__ import annotations

import os
import sys
import time
from pathlib import Path

# Wire the env BEFORE importing the provider so it picks up our settings.
REPO_ROOT = Path(__file__).resolve().parents[2]
ADAPTER = REPO_ROOT / "notebooks" / "calories_guard_adapter"

if not ADAPTER.exists():
    print(f"adapter not found at {ADAPTER} — train it first via _run_full.py")
    sys.exit(1)

os.environ["LLM_PROVIDER"] = "local"
os.environ["LOCAL_MODEL_PATH"] = "deepseek-ai/DeepSeek-R1-Distill-Qwen-1.5B"
os.environ["LOCAL_ADAPTER_PATH"] = str(ADAPTER)
os.environ["LOCAL_LOAD_IN_4BIT"] = "1"

# Make `backend` importable as a package when run via `python backend/scripts/...`.
sys.path.insert(0, str(REPO_ROOT))

from backend.ai_models.llm_provider import generate  # noqa: E402

SYSTEM = (
    "คุณเป็นผู้ช่วยด้านโภชนาการและสุขภาพในแอป Calories Guard "
    "ตอบกระชับ เป็นภาษาไทย ให้ตัวเลขที่เชื่อถือได้เมื่อเป็นไปได้."
)

PROMPTS = [
    "ส้มตำไทย 1 จานกี่แคล",
    "วิ่ง 30 นาทีเผาผลาญกี่แคล",
    "BMI 24 ถือว่าอ้วนไหม",
]


def main() -> None:
    print(f"adapter: {ADAPTER}")
    print("warming up model (first call loads weights)…")
    t0 = time.time()
    first = generate(SYSTEM, PROMPTS[0])
    print(f"  ↳ cold call {time.time()-t0:.1f}s  ({len(first)} chars)\n")
    print(f"Q: {PROMPTS[0]}\nA: {first}\n")

    for q in PROMPTS[1:]:
        t = time.time()
        a = generate(SYSTEM, q)
        print(f"Q: {q}\nA: {a}\n  ({time.time()-t:.1f}s)\n")


if __name__ == "__main__":
    main()
