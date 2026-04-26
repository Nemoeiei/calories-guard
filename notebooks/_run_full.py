"""Execute all code cells of deepseek_finetune.ipynb in one Python process.

Bypasses Jupyter kernel (broken on Python 3.13 + Windows zmq). Captures stdout
and saves matplotlib figures so we can inject outputs back into the notebook
after a successful run.
"""
from __future__ import annotations

import io
import json
import os
import sys
import time
import traceback
from contextlib import redirect_stdout
from pathlib import Path

import matplotlib

matplotlib.use("Agg")  # headless plotting; we'll save figs.
import matplotlib.pyplot as plt

NB_DIR = Path(__file__).parent
NB_PATH = NB_DIR / "deepseek_finetune.ipynb"
OUT_DIR = NB_DIR / "_run_outputs"
OUT_DIR.mkdir(exist_ok=True)

# Make sure relative paths inside the notebook resolve.
os.chdir(NB_DIR)


def main() -> None:
    nb = json.loads(NB_PATH.read_text(encoding="utf-8"))
    cells = nb["cells"]

    namespace: dict = {"__name__": "__main__"}
    started = time.time()
    fig_counter = 0

    for idx, cell in enumerate(cells):
        if cell["cell_type"] != "code":
            continue
        src = "".join(cell["source"])
        # Skip the (commented) pip-install cell.
        if "!pip install" in src and not any(line.strip() and not line.strip().startswith("#") for line in src.splitlines() if "!pip" not in line):
            print(f"[cell {idx}] skipped (pip install)")
            continue
        # Comment-out shell magics that would break under exec().
        src = "\n".join(("# " + line) if line.lstrip().startswith("!") else line for line in src.splitlines())

        print(f"\n[cell {idx}] running ({len(src)} chars)…")
        sys.stdout.flush()

        # Capture stdout per cell so we can replay it.
        buf = io.StringIO()
        try:
            with redirect_stdout(buf):
                exec(compile(src, f"<cell_{idx}>", "exec"), namespace)
        except Exception:
            print(buf.getvalue(), end="")
            traceback.print_exc()
            print(f"\n[cell {idx}] FAILED at {time.time() - started:.0f}s")
            sys.exit(1)

        out = buf.getvalue()
        print(out, end="")
        # Save any figures produced by this cell.
        for fnum in plt.get_fignums():
            fig_counter += 1
            fpath = OUT_DIR / f"cell_{idx}_fig_{fig_counter}.png"
            plt.figure(fnum).savefig(fpath, dpi=110, bbox_inches="tight")
            print(f"  → saved figure to {fpath.name}")
            plt.close(fnum)

    elapsed = time.time() - started
    print(f"\n=== ALL CELLS DONE in {elapsed:.0f}s ({elapsed/60:.1f} min) ===")


if __name__ == "__main__":
    main()
