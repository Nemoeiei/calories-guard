# DeepSeek LoRA fine-tune — Status (2026-04-25, run completed)

สรุปสถานะ Local LLM fine-tune ของแอป Calories Guard.
**Latest end-to-end run: ✅ 2026-04-25 — 5 epochs / 107.7 min on RTX 3050 Ti 4GB.**
ไฟล์หลัก: [`notebooks/deepseek_finetune.ipynb`](../notebooks/deepseek_finetune.ipynb)
Backend hook: [`backend/ai_models/llm_provider.py`](../backend/ai_models/llm_provider.py)

---

## 1. ทำเสร็จแล้ว (Done)

### Dataset & split
- [x] **ขยาย Q&A dataset** จาก 60 → **150 คู่** (hand-curated, scoped Calories Guard)
  - อาหารไทย/ขนม/เครื่องดื่ม ~75
  - macro/nutrition science ~15
  - exercise calorie burn ~10
  - allergen/dietary restriction ~10
  - app-specific Q&A ~15
  - fast food/desserts ~10
- [x] **70 / 15 / 15 train/val/test split** persistent JSON ที่ `notebooks/data/{train,val,test}.json`
  - Re-run notebook ใช้ split เดิม (ไม่มี leakage)
  - ตรวจสอบแล้วว่า question disjoint ทั้ง 3 ชุด
- [x] Train: **105**, Val: **22**, Test: **23**

### Thai word segmentation (MLP)
- [x] **WordBoundaryMLP** — embedding 24 → MLP hidden 64 → BCE
- [x] Train 10 epochs บน char-window 7 (3 ก่อน + ปัจจุบัน + 3 หลัง)
- [x] Oracle labels จาก `pythainlp.word_tokenize(engine='newmm')`
- [x] **Val accuracy: 96.39%** (ทดสอบที่ Apr 25)

### Eval metrics — MLP-segmenter-everywhere
- [x] **MLP-word unigram Jaccard** — เซ็ตของคำที่ซอยด้วย MLP
- [x] **MLP-word bigram Jaccard** — แทนที่ char-bigram เดิม (ใช้ MLP segmenter ตลอด pipeline)
- [x] **Exact match %**
- [x] Eval บน VAL ทุก epoch + TEST ครั้งเดียวตอนจบ (ป้องกัน leakage)

### LoRA fine-tune pipeline
- [x] Base: `deepseek-ai/DeepSeek-R1-Distill-Qwen-1.5B`
- [x] 4-bit nf4 quant + bf16 compute
- [x] LoRA r=16, alpha=32, dropout=0.05, target = q/k/v/o + gate/up/down_proj
- [x] **VRAM-aware config** — auto-detect GPU
  - GPU < 8 GiB: MAX_LEN=256, batch=1, grad_accum=8, gradient checkpointing **on**
  - GPU ≥ 8 GiB (Colab T4): MAX_LEN=512, batch=2, grad_accum=4
- [x] Training loop 5 epochs + plot loss vs alignment %

### Local execution / verification
- [x] CPU smoke test — dataset + MLP segmenter ผ่าน ([`_smoke_test.py`](../notebooks/_smoke_test.py))
- [x] GPU smoke test — 4-bit load + LoRA forward/backward fits in **2.81 GiB peak** บน RTX 3050 Ti 4GB ([`_gpu_smoke.py`](../notebooks/_gpu_smoke.py))
- [x] Workaround Jupyter kernel crash บน Python 3.13 + Windows zmq → ใช้ flat-script runner ([`_run_full.py`](../notebooks/_run_full.py))
- [x] **Full notebook run end-to-end สำเร็จ** — 5 LoRA epochs จบใน 107.7 นาที บน RTX 3050 Ti 4GB
  - Train loss: 3.61 → 1.99 → 1.54 → 1.30 → 1.15 (monotonic ↓)
  - VAL alignment: epoch-3 best (unigram 13.9%, bigram 8.0%); slight overfit ที่ epoch 5 (11.4% / 4.1%)
  - **TEST set (held-out 23 Q): unigram 16.1%, bigram 8.3%, exact 0%**
  - Adapter saved → [`notebooks/calories_guard_adapter/`](../notebooks/calories_guard_adapter/) (~73 MB safetensors)
  - Meta saved → [`calories_guard_meta.json`](../notebooks/calories_guard_adapter/calories_guard_meta.json)
  - Loss/alignment plot → [`_run_outputs/cell_18_fig_2.png`](../notebooks/_run_outputs/cell_18_fig_2.png)

### Quality observation
- Model **เริ่มเรียนรู้ pattern ตอบ** (loss ลงสม่ำเสมอ + alignment % สูงกว่า baseline 5×)
- แต่ qualitative output ยังมี **repetition/hallucination** หนักในคำตอบที่ไม่อยู่ในชุด train (เช่น "อะโวคาโดครึ่งลูก" → ตอบ generic loop)
- **สาเหตุหลัก: dataset 150 คู่เล็กเกินไป** สำหรับ 1.5B model — เพิ่มเป็น 500+ น่าจะลด degenerate output
- Best epoch (3) ดีกว่า final (5) ใน VAL → แนะนำเพิ่ม **early stopping** หรือ save best checkpoint แทน last

### Tooling files
- [`notebooks/_update_notebook.py`](../notebooks/_update_notebook.py) — rewrites dataset/eval cells
- [`notebooks/_patch_vram_aware.py`](../notebooks/_patch_vram_aware.py) — patches training cells for small-GPU mode
- [`notebooks/_smoke_test.py`](../notebooks/_smoke_test.py) — CPU verification of dataset + MLP
- [`notebooks/_gpu_smoke.py`](../notebooks/_gpu_smoke.py) — verifies 4-bit + LoRA fits before full run
- [`notebooks/_run_full.py`](../notebooks/_run_full.py) — flat-script executor (bypasses kernel)

---

## 2. งานที่ต้องทำต่อ (TODO)

### Short term (รอบถัดไป)
- [x] **ตรวจผลลัพธ์ full run** — TEST 16.1% / 8.3% / 0% (vs baseline ~3% / 0.6% / 0%) ✓
- [x] **เก็บ meta** — `calories_guard_meta.json` มี train/val/test final + LoRA config ครบ ✓
- [x] **Inject outputs กลับ notebook** — ใส่กราฟ + per-epoch log ลง .ipynb แล้ว ([`_inject_outputs.py`](../notebooks/_inject_outputs.py)) ✓
- [x] **Best-checkpoint แทน last** — patch แล้วใน cell 17 ([`_patch_best_checkpoint.py`](../notebooks/_patch_best_checkpoint.py)): track VAL unigram, save_pretrained ทุกครั้งที่ดีขึ้น, cell 20 promote best → `calories_guard_adapter/`. รอบรันถัดไปจะใช้กลไกนี้อัตโนมัติ ✓
- [x] **Notebooks README** — [`notebooks/README.md`](../notebooks/README.md) อธิบาย Colab vs local + helper scripts ✓
- [x] **Gitignore artifacts** — `calories_guard_adapter/`, `_run_outputs/`, `_run_full.log` ไม่ถูก commit ✓
- [ ] **Commit + push adapter** — 73 MB safetensors ต้องใช้ git LFS หรือ release artifact (ยังไม่ทำ — รอตัดสินใจ storage)

### Quality / dataset
- [ ] **ขยายเป็น ~500 คู่** — ตอนนี้ 150 อาจ overfit; เพิ่ม diversity:
  - อาหารภาคเหนือ/ใต้/อีสาน (ข้าวซอย, แกงไตปลา, ขนมจีน) ขยายอีก
  - คำถามเด็ก/ผู้สูงอายุ/ตั้งครรภ์ — TDEE/macro adjustments
  - corner cases ของ allergy mapping
- [ ] **Synthesize negative cases** — Q ที่อยู่นอก scope (เช่น "วันนี้อากาศยังไง") + A ที่เลี่ยงตอบ
- [ ] **Few-shot eval** — ลองให้ baseline (ไม่ fine-tune) มี few-shot examples ใน prompt เพื่อเทียบ uplift จริง ๆ

### Production hookup
- [x] **Backend integration smoke test** — [`backend/scripts/test_local_llm.py`](../backend/scripts/test_local_llm.py) ยิง `generate()` ผ่าน `LLM_PROVIDER=local` + `LOCAL_LOAD_IN_4BIT=1` + adapter ที่เพิ่งเทรน → ทำงาน end-to-end ✓
- [x] **4-bit quant ใน backend provider** — เพิ่ม `BitsAndBytesConfig(nf4+bf16)` ใน `_local_generate` (ตรงกับ notebook) → fits 4 GiB GPU
- [x] **Inference config ปรับใหม่** — `max_new_tokens=256` (เดิม 1024) + `repetition_penalty=1.3` → latency ลดจาก 180-210s/call เหลือ 32-45s/call บน RTX 3050 Ti, ไม่มี infinite loop
- [ ] **Latency benchmark vs Gemini** — RTX 3050 Ti 4-bit p50 ~40s/call (256 tokens), Gemini API p50 ~1-2s. Local ยังไม่เหมาะ production realtime — เหมาะ batch / fallback
- [ ] **Quality gating** — output ยัง degenerate ระดับใช้งานไม่ได้ (random vocab, off-topic) → **ต้อง expand dataset → 500+ คู่ก่อน** ค่อย integrate กับ `/chat`, `/recipes/{id}/llm_fill`
- [ ] **VRAM benchmark** — confirm production server (Railway/cloud) มี GPU ไหม; ถ้าไม่มี ต้อง quantize เป็น GGUF + llama.cpp
- [ ] **Fallback policy** — ถ้า local provider ตอบช้า/พัง, fall back Gemini อัตโนมัติ (มี `LLM_PROVIDER` แต่ยังไม่มี runtime fallback)

### Documentation
- [ ] **เขียน README** สั้น ๆ ใน `notebooks/` อธิบาย:
  - วิธี run บน Colab (uncomment cell 2 pip install)
  - วิธี run local (ต้องมี CUDA torch)
  - vram-aware config ทำอะไร
- [ ] **Update [`SYSTEM_ARCHITECTURE.md`](SYSTEM_ARCHITECTURE.md)** — เพิ่ม diagram local LLM path
- [ ] **Update [`STATUS.md`](STATUS.md)** ส่วน AI ให้ชี้มาไฟล์นี้

### Stretch
- [ ] **Replace MLP segmenter with full sequence model** — BiLSTM/Transformer-based แม่นกว่า MLP สำหรับ Thai (PyThaiNLP `attacut` หรือ `deepcut` ใช้ vector ละเอียดกว่า)
- [ ] **MLP segmenter เข้ารวมกับ tokenizer LLM จริง** — ใช้ MLP boundary เป็น hint ให้ subword tokenizer (ตอนนี้ MLP ใช้แค่ใน eval metric)
- [ ] **DPO / preference fine-tune** — หลังมี user feedback (จากที่ผู้ใช้แก้ค่าแคล) ใช้เป็น preference signal

---

## 3. ค่า config สำคัญ

| Knob | Value (small GPU) | Value (Colab T4) |
|---|---|---|
| Base model | `deepseek-ai/DeepSeek-R1-Distill-Qwen-1.5B` | same |
| Quantization | 4-bit nf4 + bf16 compute | same |
| LoRA rank / alpha | 16 / 32 | 16 / 32 |
| Target modules | q,k,v,o,gate,up,down_proj | same |
| MAX_LEN | 256 | 512 |
| Batch size | 1 | 2 |
| Grad accumulation | 8 | 4 |
| Gradient checkpointing | on | off |
| Epochs | 5 | 5 |
| LR | 2e-4 | 2e-4 |

## 4. การ deploy (จาก notebook → backend)

```bash
# หลัง notebook สำเร็จ และมี ./calories_guard_adapter/ แล้ว:
# 1. zip + upload ไปยัง storage (Supabase storage, S3, หรือ HF Hub)
# 2. ใน production server (Railway/cloud GPU instance) ตั้ง env:
export LLM_PROVIDER=local
export LOCAL_MODEL_PATH=deepseek-ai/DeepSeek-R1-Distill-Qwen-1.5B
export LOCAL_ADAPTER_PATH=/app/adapters/calories_guard_adapter
# 3. backend ai_models/llm_provider.py จะ load อัตโนมัติ
```

หมายเหตุ: Railway free tier ไม่มี GPU — เพื่อให้ใช้งานจริงต้องย้ายไป cloud GPU (RunPod / Lambda / Colab Enterprise) หรือ quantize เป็น GGUF + ใช้ CPU inference (~5-15 token/s บน 1.5B 4-bit).
