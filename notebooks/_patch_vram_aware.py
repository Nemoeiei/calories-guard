"""Patch the notebook so training args auto-scale to available VRAM.

- 4 GiB GPU (e.g. RTX 3050 4GB): batch=1, max_len=256, grad_accum=8, gradient_checkpointing on.
- ≥8 GiB GPU (Colab T4 etc.): original batch=2, max_len=512, grad_accum=4.

The plot/code logic stays identical — only the resource knobs adapt.
"""
from __future__ import annotations

import json
from pathlib import Path

NB = Path(__file__).parent / "deepseek_finetune.ipynb"

# Cell 14 (data prep + MAX_LEN) — replace.
NEW_CELL_14 = '''SYSTEM_PROMPT = 'คุณเป็นผู้ช่วยด้านโภชนาการและสุขภาพในแอป Calories Guard ตอบกระชับ เป็นภาษาไทย ให้ตัวเลขที่เชื่อถือได้เมื่อเป็นไปได้.'

def format_chat(q, a=None):
    msgs = [
        {'role': 'system', 'content': SYSTEM_PROMPT},
        {'role': 'user', 'content': q},
    ]
    if a is not None:
        msgs.append({'role': 'assistant', 'content': a})
    return tokenizer.apply_chat_template(msgs, tokenize=False, add_generation_prompt=(a is None))

# VRAM-aware training config so the notebook runs on small (4 GiB) and large (16 GiB+) GPUs alike.
if torch.cuda.is_available():
    _vram_gib = torch.cuda.get_device_properties(0).total_memory / 1024**3
else:
    _vram_gib = 0.0
SMALL_GPU = _vram_gib < 8.0
MAX_LEN          = 256 if SMALL_GPU else 512
BATCH_SIZE       = 1 if SMALL_GPU else 2
GRAD_ACCUM_STEPS = 8 if SMALL_GPU else 4
USE_GRAD_CKPT    = SMALL_GPU
print(f'GPU VRAM ~{_vram_gib:.1f} GiB → MAX_LEN={MAX_LEN}, batch={BATCH_SIZE}, accum={GRAD_ACCUM_STEPS}, grad_ckpt={USE_GRAD_CKPT}')

if USE_GRAD_CKPT:
    model.gradient_checkpointing_enable()
    model.enable_input_require_grads()

def to_features(pair):
    text = format_chat(pair['q'], pair['a']) + tokenizer.eos_token
    out = tokenizer(text, truncation=True, max_length=MAX_LEN, padding='max_length')
    out['labels'] = out['input_ids'].copy()
    return out

train_ds = Dataset.from_list([to_features(x) for x in TRAIN_QA])
val_ds = Dataset.from_list([to_features(x) for x in VAL_QA])
print(train_ds)'''

# Cell 17 (training loop) — use the new knobs.
NEW_CELL_17 = '''EPOCHS = 5

train_losses, val_unigram, val_bigram, val_em = [], [], [], []

# Record the pre-training baseline so the plot shows "straight line" improvement from epoch 0.
u0, b0, e0 = eval_alignment(VAL_QA)
val_unigram.append(u0); val_bigram.append(b0); val_em.append(e0)

for epoch in range(EPOCHS):
    args = TrainingArguments(
        output_dir='./out',
        num_train_epochs=1,
        per_device_train_batch_size=BATCH_SIZE,
        gradient_accumulation_steps=GRAD_ACCUM_STEPS,
        learning_rate=2e-4,
        logging_steps=5,
        save_strategy='no',
        bf16=(DEVICE == 'cuda'),
        report_to=[],
        remove_unused_columns=False,
        gradient_checkpointing=USE_GRAD_CKPT,
    )
    trainer = Trainer(
        model=model,
        args=args,
        train_dataset=train_ds,
        data_collator=DataCollatorForLanguageModeling(tokenizer, mlm=False),
    )
    result = trainer.train()
    train_losses.append(result.training_loss)
    u, b, e = eval_alignment(VAL_QA)
    val_unigram.append(u); val_bigram.append(b); val_em.append(e)
    print(f'Epoch {epoch+1}: loss={result.training_loss:.4f}  unigram%={u*100:.1f}  word-bigram%={b*100:.1f}  exact%={e*100:.1f}')'''


def split_lines(src: str) -> list[str]:
    return src.splitlines(keepends=True)


def main() -> None:
    nb = json.loads(NB.read_text(encoding="utf-8"))
    nb["cells"][14]["source"] = split_lines(NEW_CELL_14)
    nb["cells"][17]["source"] = split_lines(NEW_CELL_17)
    NB.write_text(json.dumps(nb, ensure_ascii=False, indent=1) + "\n", encoding="utf-8")
    print("Patched cells 14 (data/VRAM autoconfig) and 17 (training loop).")


if __name__ == "__main__":
    main()
