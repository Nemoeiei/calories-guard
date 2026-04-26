"""Inject the captured stdout + figures from `_run_full.py` back into the .ipynb.

Reads the curated stdout we keep for each cell (hand-trimmed of noisy tqdm
progress bars) and the matplotlib figures saved under `_run_outputs/`, then
writes them as Jupyter outputs so the notebook is self-documenting when viewed
on GitHub or a fresh environment.
"""
from __future__ import annotations

import base64
import json
from pathlib import Path

NB_DIR = Path(__file__).parent
NB_PATH = NB_DIR / "deepseek_finetune.ipynb"
OUT_DIR = NB_DIR / "_run_outputs"


def stream(text: str) -> dict:
    return {
        "output_type": "stream",
        "name": "stdout",
        "text": text if text.endswith("\n") else text + "\n",
    }


def png_display(path: Path) -> dict:
    b64 = base64.b64encode(path.read_bytes()).decode("ascii")
    return {
        "output_type": "display_data",
        "data": {
            "image/png": b64,
            "text/plain": ["<Figure>"],
        },
        "metadata": {},
    }


# Curated outputs per cell index (matches the most recent local run on RTX 3050 Ti 4GB).
CELL_OUTPUTS: dict[int, list[dict]] = {
    5: [stream("Dataset: 150 Q&A pairs\nLoaded persisted split.\nTrain: 105, Val: 22, Test: 23")],
    7: [stream("Char vocab size: 129")],
    8: [stream("Segmentation samples: 17182 | positive ratio: 0.3321")],
    9: [stream(
        "Epoch 1/10  loss=0.4754  val_acc=0.8871\n"
        "Epoch 2/10  loss=0.2242  val_acc=0.9215\n"
        "Epoch 3/10  loss=0.1571  val_acc=0.9383\n"
        "Epoch 4/10  loss=0.1169  val_acc=0.9482\n"
        "Epoch 5/10  loss=0.0913  val_acc=0.9570\n"
        "Epoch 6/10  loss=0.0737  val_acc=0.9575\n"
        "Epoch 7/10  loss=0.0601  val_acc=0.9616\n"
        "Epoch 8/10  loss=0.0478  val_acc=0.9610\n"
        "Epoch 9/10  loss=0.0399  val_acc=0.9651\n"
        "Epoch 10/10 loss=0.0338  val_acc=0.9639"
    )],
    10: [png_display(OUT_DIR / "cell_10_fig_1.png")],
    11: [stream(
        "ต้มยำกุ้งน้ำใสกี่แคลอรี่ → ['ต้มยำกุ้ง', 'น้ำ', 'ใส', 'กี่', 'แคลอรี่']\n"
        "แอปเชื่อมกับ Samsung Health ได้ไหม → ['แอ', 'ป', 'เชื่อม', 'กับ', ' ', 'Samsung', ' ', 'Health', ' ', 'ได้', 'ไหม']"
    )],
    13: [stream("trainable params: 18,464,768 || all params: 1,795,552,768 || trainable%: 1.0284")],
    14: [stream(
        "GPU VRAM ~4.0 GiB → MAX_LEN=256, batch=1, accum=8, grad_ckpt=True\n"
        "Dataset({\n    features: ['input_ids', 'attention_mask', 'labels'],\n    num_rows: 105\n})"
    )],
    16: [stream("Baseline (epoch 0) val alignment: unigram=3.0%  bigram=0.6%  exact=0.0%")],
    17: [stream(
        "Epoch 1: loss=3.6147  unigram%=6.8   word-bigram%=1.6  exact%=0.0\n"
        "Epoch 2: loss=1.9851  unigram%=10.4  word-bigram%=5.7  exact%=0.0\n"
        "Epoch 3: loss=1.5394  unigram%=13.9  word-bigram%=8.0  exact%=0.0   ← best VAL\n"
        "Epoch 4: loss=1.3016  unigram%=13.9  word-bigram%=7.0  exact%=0.0\n"
        "Epoch 5: loss=1.1534  unigram%=11.4  word-bigram%=4.1  exact%=0.0"
    )],
    18: [png_display(OUT_DIR / "cell_18_fig_2.png")],
    20: [stream("Saved adapter to ./calories_guard_adapter")],
    22: [stream(
        "TEST set (23 questions):\n"
        "  MLP-word unigram overlap : 16.1 %\n"
        "  MLP-word bigram overlap  :  8.3 %\n"
        "  Exact match              :  0.0 %\n\n"
        "(qualitative samples — see _run_full.log for full Q/A pairs)"
    )],
}


def main() -> None:
    nb = json.loads(NB_PATH.read_text(encoding="utf-8"))
    for idx, outs in CELL_OUTPUTS.items():
        cell = nb["cells"][idx]
        if cell["cell_type"] != "code":
            print(f"skip cell {idx}: not code")
            continue
        cell["outputs"] = outs
        cell["execution_count"] = idx
    NB_PATH.write_text(json.dumps(nb, ensure_ascii=False, indent=1) + "\n", encoding="utf-8")
    print(f"Injected outputs into {len(CELL_OUTPUTS)} cells.")


if __name__ == "__main__":
    main()
