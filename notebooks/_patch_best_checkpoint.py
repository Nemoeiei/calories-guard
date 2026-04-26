"""Patch cell 17 to save best-VAL-unigram checkpoint, and cell 20 to prefer it.

Rationale: in the 2026-04-25 run, VAL unigram peaked at epoch 3 (13.9%) but
the final epoch 5 was 11.4% — clear overfit. Saving last is wrong; save best.
"""
from __future__ import annotations

import json
from pathlib import Path

NB = Path(__file__).parent / "deepseek_finetune.ipynb"

NEW_CELL_17 = '''EPOCHS = 5
BEST_DIR = './calories_guard_adapter_best'

train_losses, val_unigram, val_bigram, val_em = [], [], [], []
best_unigram = -1.0
best_epoch = 0

# Pre-training baseline (epoch 0) so the plot starts from "no fine-tune".
u0, b0, e0 = eval_alignment(VAL_QA)
val_unigram.append(u0); val_bigram.append(b0); val_em.append(e0)
print(f'Baseline   : unigram%={u0*100:.1f}  word-bigram%={b0*100:.1f}  exact%={e0*100:.1f}')

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
    marker = ''
    if u > best_unigram:
        best_unigram = u
        best_epoch = epoch + 1
        model.save_pretrained(BEST_DIR)
        tokenizer.save_pretrained(BEST_DIR)
        marker = '  ← new best, saved'
    print(f'Epoch {epoch+1:>2}: loss={result.training_loss:.4f}  unigram%={u*100:.1f}  word-bigram%={b*100:.1f}  exact%={e*100:.1f}{marker}')

print(f'\\nBest VAL unigram = {best_unigram*100:.1f}% at epoch {best_epoch} (saved to {BEST_DIR})')'''

NEW_CELL_20 = '''import shutil

ADAPTER_DIR = './calories_guard_adapter'
BEST_DIR = './calories_guard_adapter_best'

# Prefer the best-VAL checkpoint over the last-epoch one to avoid overfit.
if Path(BEST_DIR).exists():
    if Path(ADAPTER_DIR).exists():
        shutil.rmtree(ADAPTER_DIR)
    shutil.copytree(BEST_DIR, ADAPTER_DIR)
    print(f'Promoted {BEST_DIR} → {ADAPTER_DIR} (best VAL unigram, epoch {best_epoch})')
else:
    model.save_pretrained(ADAPTER_DIR)
    tokenizer.save_pretrained(ADAPTER_DIR)
    print(f'Saved current model to {ADAPTER_DIR}')

meta = {
    'base_model': BASE_MODEL,
    'dataset_size': len(QA_PAIRS),
    'split': {'train': len(TRAIN_QA), 'val': len(VAL_QA), 'test': len(TEST_QA)},
    'epochs': EPOCHS,
    'best_epoch': best_epoch,
    'final_train_loss': train_losses[-1],
    'val_best': {'unigram': float(best_unigram)},
    'val_final': {
        'unigram': float(val_unigram[-1]),
        'bigram': float(val_bigram[-1]),
        'exact': float(val_em[-1]),
    },
}
with open(Path(ADAPTER_DIR) / 'calories_guard_meta.json', 'w', encoding='utf-8') as f:
    json.dump(meta, f, ensure_ascii=False, indent=2)
print('meta:', meta)'''


def split_lines(src: str) -> list[str]:
    return src.splitlines(keepends=True)


def main() -> None:
    nb = json.loads(NB.read_text(encoding="utf-8"))
    nb["cells"][17]["source"] = split_lines(NEW_CELL_17)
    nb["cells"][20]["source"] = split_lines(NEW_CELL_20)
    # Clear stale outputs on the cells we just rewrote.
    for idx in (17, 20):
        nb["cells"][idx]["outputs"] = []
        nb["cells"][idx]["execution_count"] = None
    NB.write_text(json.dumps(nb, ensure_ascii=False, indent=1) + "\n", encoding="utf-8")
    print("Patched cell 17 (best-checkpoint tracking) and cell 20 (promote best).")


if __name__ == "__main__":
    main()
