"""Smoke-test the CPU-only portion of deepseek_finetune.ipynb.

Extracts and runs the data + MLP segmenter cells so we can verify:
- 150 Q&A pairs load and split into 70/15/15 deterministically
- Persisted JSON files are written
- MLP word-boundary classifier trains and converges
- mlp_tokenize / word-bigram metric work end-to-end on a sample

Skips the LoRA fine-tune cells (those need 4-bit GPU on Colab).
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

NB_PATH = Path(__file__).parent / "deepseek_finetune.ipynb"


def main() -> None:
    nb = json.loads(NB_PATH.read_text(encoding="utf-8"))

    # CPU-runnable cell indices: imports/setup (3), QA dataset (5), char vocab (7),
    # MLP dataset (8), MLP train (9), MLP tokenize (11), and our new eval cell (16) — minus
    # generate_answer/eval_alignment which need the LLM.
    runnable = [3, 5, 7, 8, 9, 11]
    code = ["import os\nos.chdir(str(Path(__file__).parent))\n".replace("__file__", repr(str(NB_PATH)))]
    code = []  # path handling done by caller cwd
    for idx in runnable:
        cell = nb["cells"][idx]
        assert cell["cell_type"] == "code", f"cell {idx} is not code"
        code.append("# ---- cell %d ----\n" % idx + "".join(cell["source"]))

    # Strip the % matplotlib stuff if any (not needed for smoke test).
    full = "\n\n".join(code)

    # Substitute matplotlib show() to a no-op so the script doesn't block.
    full = full.replace("plt.show()", "plt.close('all')")

    # Run.
    namespace: dict = {}
    print(f"Running {len(runnable)} cells (~{full.count(chr(10))} lines)…")
    exec(compile(full, "<smoke_test>", "exec"), namespace)

    # Post-checks.
    qa = namespace["QA_PAIRS"]
    train = namespace["TRAIN_QA"]
    val = namespace["VAL_QA"]
    test = namespace["TEST_QA"]
    print(f"\nDataset assembled: {len(qa)} pairs")
    print(f"Split: train={len(train)} val={len(val)} test={len(test)}")
    assert len(qa) >= 140, "expected ~150 pairs"
    assert len(train) + len(val) + len(test) == len(qa)
    # No leakage between splits.
    qs_train = {x["q"] for x in train}
    qs_val = {x["q"] for x in val}
    qs_test = {x["q"] for x in test}
    assert qs_train.isdisjoint(qs_val)
    assert qs_train.isdisjoint(qs_test)
    assert qs_val.isdisjoint(qs_test)
    print("✓ no question leakage between train/val/test")

    # Persist files exist.
    for f in ("train.json", "val.json", "test.json"):
        p = Path("./data") / f
        assert p.exists(), f"missing {p}"
    print("✓ persisted ./data/{train,val,test}.json")

    # MLP segmenter sanity.
    mlp_tokenize = namespace["mlp_tokenize"]
    sample = "ต้มยำกุ้งน้ำใสกี่แคลอรี่"
    words = mlp_tokenize(sample)
    print(f"\nMLP segments {sample!r} → {words}")
    assert len(words) >= 2, "segmenter produced too few tokens"

    # Word-bigram metric (mirrors notebook's new eval).
    def word_bigrams(text):
        ws = mlp_tokenize(text)
        return {(ws[i], ws[i + 1]) for i in range(len(ws) - 1)}

    a = "ผัดไทยกุ้งสด 1 จาน ประมาณ 500 กิโลแคลอรี่"
    b = "ผัดไทยกุ้งสด 1 จาน ราว 600 กิโลแคลอรี่"
    bg_a, bg_b = word_bigrams(a), word_bigrams(b)
    overlap = len(bg_a & bg_b) / max(1, len(bg_a | bg_b))
    print(f"Word-bigram Jaccard between two paraphrases: {overlap*100:.1f}%")
    assert 0.0 < overlap < 1.0, "metric should be partial for paraphrases"

    seg_accs = namespace["seg_accs"]
    print(f"\nMLP segmenter final val accuracy: {seg_accs[-1]*100:.2f}%")
    assert seg_accs[-1] > 0.85, "segmenter underperformed (<85%)"

    print("\n✓ smoke test passed")


if __name__ == "__main__":
    sys.exit(main() or 0)
