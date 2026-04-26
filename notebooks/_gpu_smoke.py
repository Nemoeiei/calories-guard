"""Probe GPU/4-bit feasibility on RTX 3050 Ti 4GB before running full LoRA notebook.

Steps:
1. Load DeepSeek-R1-Distill-Qwen-1.5B in 4-bit
2. Apply LoRA
3. Forward + backward on one tiny example
4. Generate one short answer
5. Print VRAM peak

If this passes, the full notebook is feasible. If it OOMs, use Colab.
"""
from __future__ import annotations

import torch
print(f"torch={torch.__version__}  cuda={torch.cuda.is_available()}")

from transformers import AutoTokenizer, AutoModelForCausalLM, BitsAndBytesConfig
from peft import LoraConfig, get_peft_model, prepare_model_for_kbit_training, TaskType

BASE = "deepseek-ai/DeepSeek-R1-Distill-Qwen-1.5B"

bnb = BitsAndBytesConfig(
    load_in_4bit=True,
    bnb_4bit_quant_type="nf4",
    bnb_4bit_compute_dtype=torch.bfloat16,
    bnb_4bit_use_double_quant=True,
)

print("Loading tokenizer…")
tok = AutoTokenizer.from_pretrained(BASE, trust_remote_code=True)
if tok.pad_token is None:
    tok.pad_token = tok.eos_token

print("Loading model (4-bit)…")
model = AutoModelForCausalLM.from_pretrained(
    BASE,
    quantization_config=bnb,
    device_map="auto",
    trust_remote_code=True,
    torch_dtype=torch.bfloat16,
)
model.config.use_cache = False
model = prepare_model_for_kbit_training(model)

lora = LoraConfig(
    task_type=TaskType.CAUSAL_LM,
    r=8,
    lora_alpha=16,
    lora_dropout=0.05,
    bias="none",
    target_modules=["q_proj", "k_proj", "v_proj", "o_proj"],
)
model = get_peft_model(model, lora)
model.print_trainable_parameters()

print(f"VRAM after load: {torch.cuda.memory_allocated()/1024**3:.2f} GiB")

# Tiny training step.
text = (
    "<|user|>ส้มตำไทย 1 จานกี่แคล<|assistant|>ส้มตำไทย 1 จาน "
    "(250 กรัม) ประมาณ 130-170 กิโลแคลอรี่."
)
ids = tok(text, return_tensors="pt", truncation=True, max_length=128).to(model.device)
labels = ids["input_ids"].clone()
print("Running forward + backward…")
out = model(**ids, labels=labels)
out.loss.backward()
print(f"Loss = {out.loss.item():.4f}")
print(f"VRAM peak: {torch.cuda.max_memory_allocated()/1024**3:.2f} GiB / 4.00 GiB")

# Generate.
print("\nGenerating sample…")
model.eval()
prompt_ids = tok("ต้มยำกุ้งน้ำใสกี่แคล\n", return_tensors="pt").to(model.device)
with torch.no_grad():
    gen = model.generate(**prompt_ids, max_new_tokens=40, do_sample=False, pad_token_id=tok.eos_token_id)
print(tok.decode(gen[0], skip_special_tokens=True))

print("\n✓ GPU smoke test passed — full notebook should run")
