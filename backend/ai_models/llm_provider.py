"""
LLM provider abstraction.

The rest of the codebase should never import `google.generativeai` or the
OpenAI/DeepSeek SDK directly — it should go through `generate()` in this
module, which routes to the right backend based on LLM_PROVIDER.

Supported providers (selected via env `LLM_PROVIDER`, default: `gemini`):

  gemini     — Google Gemini via google-generativeai (existing, default)
  deepseek   — DeepSeek hosted API (OpenAI-compatible; base_url=api.deepseek.com)
  local      — self-hosted DeepSeek-R1-Distill via transformers+torch
               (heavy; only meant for dev boxes / when you've fine-tuned an
                adapter with notebooks/deepseek_finetune.ipynb)

Env vars:

  LLM_PROVIDER          = gemini | deepseek | local     (default: gemini)
  GEMINI_API_KEY        = <key>                         (for gemini)
  GEMINI_MODEL          = gemini-2.5-flash              (optional override)
  DEEPSEEK_API_KEY      = <key>                         (for deepseek)
  DEEPSEEK_MODEL        = deepseek-chat                 (optional override)
  LOCAL_MODEL_PATH      = deepseek-ai/DeepSeek-R1-Distill-Qwen-1.5B
                                                        (HF id or local path)
  LOCAL_ADAPTER_PATH    = <path-to-LoRA-adapter>        (optional, for `local`)

The generate() function is blocking on purpose — the chat router already
runs it in a thread pool with a 30s timeout (see app/routers/chat.py).
"""
from __future__ import annotations

import os
from typing import Optional

# Module-level cache for the local model so we don't reload weights per call.
_local_cache: dict = {}


def _get_provider() -> str:
    return (os.getenv("LLM_PROVIDER") or "gemini").strip().lower()


def _gemini_generate(system: str, user: str, model_name: Optional[str] = None) -> str:
    import google.generativeai as genai

    api_key = os.getenv("GEMINI_API_KEY", "")
    if not api_key:
        raise RuntimeError("GEMINI_API_KEY is not set")
    genai.configure(api_key=api_key)
    model = genai.GenerativeModel(model_name or os.getenv("GEMINI_MODEL", "gemini-2.5-flash"))
    response = model.generate_content([
        {"role": "user", "parts": [system]},
        {"role": "user", "parts": [user]},
    ])
    return getattr(response, "text", "") or ""


def _deepseek_generate(system: str, user: str, model_name: Optional[str] = None) -> str:
    # DeepSeek exposes an OpenAI-compatible chat/completions endpoint, so we
    # reuse the openai SDK rather than hand-rolling an HTTP client. The SDK
    # is small enough that it won't bloat the image and is already a common
    # transitive dep.
    try:
        from openai import OpenAI
    except ImportError as e:
        raise RuntimeError(
            "openai package is required for LLM_PROVIDER=deepseek. "
            "Add `openai>=1.0` to requirements.txt."
        ) from e

    api_key = os.getenv("DEEPSEEK_API_KEY", "")
    if not api_key:
        raise RuntimeError("DEEPSEEK_API_KEY is not set")

    client = OpenAI(
        api_key=api_key,
        base_url=os.getenv("DEEPSEEK_BASE_URL", "https://api.deepseek.com"),
    )
    resp = client.chat.completions.create(
        model=model_name or os.getenv("DEEPSEEK_MODEL", "deepseek-chat"),
        messages=[
            {"role": "system", "content": system},
            {"role": "user", "content": user},
        ],
        temperature=0.7,
        max_tokens=1024,
    )
    return resp.choices[0].message.content or ""


def _local_generate(system: str, user: str, model_name: Optional[str] = None) -> str:
    """
    Run DeepSeek-R1-Distill (or any HF causal-LM) locally via transformers.
    Heavy dependency; not installed by default. Use this for dev testing of
    a fine-tuned adapter produced by notebooks/deepseek_finetune.ipynb.
    """
    try:
        import torch  # noqa: F401
        from transformers import AutoModelForCausalLM, AutoTokenizer
    except ImportError as e:
        raise RuntimeError(
            "transformers + torch are required for LLM_PROVIDER=local. "
            "Install with `pip install torch transformers accelerate peft`."
        ) from e

    base_path = model_name or os.getenv(
        "LOCAL_MODEL_PATH", "deepseek-ai/DeepSeek-R1-Distill-Qwen-1.5B"
    )
    adapter_path = os.getenv("LOCAL_ADAPTER_PATH", "")

    cached = _local_cache.get((base_path, adapter_path))
    if cached is None:
        tokenizer = AutoTokenizer.from_pretrained(base_path, trust_remote_code=True)
        model = AutoModelForCausalLM.from_pretrained(
            base_path, trust_remote_code=True, device_map="auto"
        )
        if adapter_path:
            from peft import PeftModel  # lazy import
            model = PeftModel.from_pretrained(model, adapter_path)
        model.eval()
        cached = (tokenizer, model)
        _local_cache[(base_path, adapter_path)] = cached

    tokenizer, model = cached
    # Use the tokenizer's chat template — DeepSeek-R1 models need it to wrap
    # messages with the correct <|im_start|> / <think> tags.
    messages = [
        {"role": "system", "content": system},
        {"role": "user", "content": user},
    ]
    prompt = tokenizer.apply_chat_template(
        messages, tokenize=False, add_generation_prompt=True
    )
    import torch
    inputs = tokenizer(prompt, return_tensors="pt").to(model.device)
    with torch.no_grad():
        out = model.generate(
            **inputs,
            max_new_tokens=1024,
            do_sample=True,
            temperature=0.7,
            top_p=0.9,
            pad_token_id=tokenizer.eos_token_id,
        )
    # Strip the prompt prefix.
    gen = out[0][inputs["input_ids"].shape[1]:]
    return tokenizer.decode(gen, skip_special_tokens=True).strip()


def generate(system: str, user: str, model_name: Optional[str] = None) -> str:
    """
    Generate a completion for (system, user) messages.

    Returns the model's text. Raises RuntimeError if the selected provider
    is misconfigured (missing key, missing deps) — callers should catch and
    surface a user-friendly error.
    """
    provider = _get_provider()
    if provider == "gemini":
        return _gemini_generate(system, user, model_name)
    if provider == "deepseek":
        return _deepseek_generate(system, user, model_name)
    if provider == "local":
        return _local_generate(system, user, model_name)
    raise RuntimeError(f"Unknown LLM_PROVIDER: {provider!r}")


def is_configured() -> bool:
    """Return True if the currently-selected provider has a usable API key."""
    provider = _get_provider()
    if provider == "gemini":
        return bool(os.getenv("GEMINI_API_KEY"))
    if provider == "deepseek":
        return bool(os.getenv("DEEPSEEK_API_KEY"))
    if provider == "local":
        return bool(os.getenv("LOCAL_MODEL_PATH") or True)  # HF will pull defaults
    return False
