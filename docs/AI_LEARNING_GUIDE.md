# AI Learning Guide — สำหรับเริ่มต้นจาก 0

เอกสารนี้สอน AI / Machine Learning / LLM ตั้งแต่พื้นฐาน โดย**ทุกหัวข้อจะโยงกลับเข้ามาที่งานที่เราทำใน Calories Guard** (`notebooks/deepseek_finetune.ipynb` + `backend/ai_models/llm_provider.py`)
อ่านเรียงลำดับแล้วจะเข้าใจว่าโค้ดที่เราเขียน "ทำอะไร / ทำไม / ปรับอะไรได้บ้าง"

---

## 0. คำนิยามที่ต้องรู้ก่อน (terminology cheatsheet)

| คำ | ความหมายแบบสั้น | ในโปรเจกต์เรา |
|---|---|---|
| **AI** | ระบบที่ทำสิ่งที่ดูเหมือน "ฉลาด" — ครอบคลุมตั้งแต่กฎ if/else ไปจนถึง LLM | ทั้งโปรเจกต์ |
| **Machine Learning (ML)** | สอนคอมจาก**ตัวอย่าง**แทนกฎที่เขียนเอง | MLP segmenter + LoRA fine-tune |
| **Deep Learning (DL)** | ML ด้วย neural network หลายชั้น | DeepSeek (transformer 28 layers), MLP segmenter |
| **Neural Network (NN)** | ฟังก์ชันที่ประกอบด้วย "เซลล์เทียม" หลายชั้น เรียนค่าน้ำหนักจากข้อมูล | ตัวอย่าง MLP คือ NN ขนาดเล็กสุด |
| **LLM** (Large Language Model) | NN ขนาดใหญ่ที่ฝึกบนข้อความปริมาณมหาศาลให้ทำนายคำถัดไปได้ | DeepSeek-R1-Distill-Qwen-1.5B |
| **Token** | หน่วยที่ LLM "เห็น" — ไม่ใช่ตัวอักษร แต่ก็ไม่ใช่คำเป๊ะ ๆ | tokenizer ของ DeepSeek |
| **Pre-training** | สอน LLM "ภาษา" จาก internet ขนาด TB ใช้ GPU farm หลายร้อยตัว | เราไม่ได้ทำเอง — ใช้ของ DeepSeek |
| **Fine-tuning** | เอา LLM ที่ pre-train แล้วมาสอน "งานเฉพาะทาง" ของเรา | ที่เราทำในโปรเจกต์ |
| **LoRA** | เทคนิค fine-tune แบบประหยัด — เรียนแค่น้ำหนัก "เพิ่ม" ไม่ต้องอัปเดตทั้งโมเดล | เราใช้ rank=16, alpha=32 |
| **Quantization** | บีบโมเดลจาก 32-bit float ลงเป็น 4-bit เพื่อใส่ใน GPU เล็กได้ | nf4 + bf16 compute |
| **Inference** | ตอน "ใช้งาน" โมเดล (สร้าง output) ตรงข้ามกับ training | `_local_generate()` ใน `llm_provider.py` |

---

## 1. AI / ML / DL / LLM ต่างกันยังไง — แบบใหญ่สุดไปเล็กสุด

```
AI                                    ← ใหญ่สุด (รวมทุกอย่าง)
└── Machine Learning                   ← เรียนจากข้อมูล (ไม่ใช่กฎ if/else)
    └── Deep Learning                  ← ใช้ neural network ลึก ๆ
        └── Transformer                ← architecture เฉพาะ
            └── LLM                    ← Transformer ที่ใหญ่มาก ๆ + train ด้วย text
```

### Programming analogy

```python
# AI แบบกฎ (rule-based, ไม่ใช่ ML):
def is_thai_word(s):
    return any(0x0E00 <= ord(c) <= 0x0E7F for c in s)

# Machine Learning:
# ไม่เขียนกฎเอง แต่ "โยน" ตัวอย่าง 17,000 คำให้คอมหา pattern เอง
# ผลลัพธ์คือ "น้ำหนัก (weights)" ตัวเลขจำนวนมหาศาลที่บอกว่าควรเอนไปทางไหน
```

**ในโปรเจกต์เรามี ML 2 ตัว:**
- `WordBoundaryMLP` — เรียน "ตำแหน่งตัด" ของคำไทย (เล็ก, 10 epoch บน CPU/GPU เล็ก)
- `DeepSeek + LoRA` — เรียน "วิธีตอบคำถามด้านโภชนาการเป็นภาษาไทย"

---

## 2. Neural Network 101 — เริ่มจาก MLP ของเรา

`WordBoundaryMLP` (ดู cell 9 ใน notebook) คือ NN เล็กสุดที่ดีต่อการเข้าใจ:

```
input  : char window 7 ตัว → integer ids
         ↓ Embedding (24-dim)        ← แปลง id → vector
         ↓ Linear (168 → 64)          ← layer 1
         ↓ ReLU                       ← activation (เพิ่ม "ไม่เป็นเส้นตรง")
         ↓ Linear (64 → 1)            ← layer 2
         ↓ Sigmoid                    ← บีบเป็น 0-1
output : ความน่าจะเป็นที่ "ตำแหน่งนี้คือจุดตัดคำ"
```

### แต่ละชิ้นทำอะไร?

- **Embedding**: เปลี่ยน "id ของตัวอักษร" → vector หลายมิติ. คล้าย one-hot แต่ "เรียนได้" ตัวที่ความหมายใกล้กันจะอยู่ใกล้กันใน vector space
- **Linear (= matmul + bias)**: `output = Wx + b` เป็นแกนหลักของ NN ทุกอย่าง
- **ReLU**: `max(0, x)` — ถ้าไม่มี activation NN จะกลายเป็นแค่ linear regression ลึก ๆ ไร้ประโยชน์
- **Sigmoid**: บีบเลขใด ๆ เป็น 0-1 ใช้กับงาน binary classification

### Training คืออะไร?

```python
for epoch in range(10):           # ดูข้อมูลทั้งชุด 10 รอบ
    for batch in dataloader:
        pred = model(batch.x)     # forward — ทำนาย
        loss = bce(pred, batch.y) # คำนวณ "ผิดเท่าไหร่"
        loss.backward()           # backward — หาว่าน้ำหนักไหนทำให้ผิด
        optimizer.step()          # ปรับน้ำหนัก ลด loss
```

**Loss** = ตัวเลขเดียวที่บอกว่า "ตอนนี้โง่แค่ไหน" — เป้าหมายของ training คือทำให้มันต่ำ

ในโปรเจกต์เรา loss ของ MLP ลดจาก 0.4754 (epoch 1) → 0.0338 (epoch 10), val accuracy ขึ้นจาก 88.7% → 96.4%

---

## 3. Transformer & LLM — ทำไม DeepSeek "ตอบคำถาม" ได้

### LLM ทำสิ่งเดียว: "ทำนาย token ถัดไป"

```
input  : "ส้มตำไทย 1 จาน"
LLM    : คำนวณความน่าจะเป็นของ "token ถัดไป" จาก vocab ทั้งหมด ~150,000 ตัว
         {กี่: 0.42, มี: 0.18, ราคา: 0.05, ...}
output : สุ่ม (sample) จาก distribution → "กี่"

repeat → "ส้มตำไทย 1 จานกี่" → "แคล" → "อรี่" → ... → EOS
```

ที่ผ่าน "ความเข้าใจ" ออกมาเป็นเพราะ pre-training บน text หลาย TB สอนให้ความน่าจะเป็นเรียนรู้ pattern ของภาษา + ความรู้ที่อยู่ในข้อความ

### Architecture (สั้น ๆ)

DeepSeek-R1-Distill-Qwen-1.5B = Transformer 28 layers, 1.78 พันล้าน parameters
หัวใจคือ **Self-Attention** — แต่ละ token "ดู" token อื่น ๆ ทั้ง sequence แล้วถ่วงน้ำหนักว่าตัวไหนเกี่ยวข้องที่สุด

**ไม่ต้องเข้าใจ math ตอนนี้** — แค่จำว่า:
1. Transformer = LEGO block ที่ stack ซ้อนกันได้
2. ยิ่งใหญ่ + ข้อมูลยิ่งเยอะ → ยิ่งฉลาด (จนถึงจุดหนึ่ง)
3. Attention คือ "ทำไมมันรู้ว่าคำไหนเชื่อมกัน"

### Pre-train vs Fine-tune (สำคัญมาก!)

```
Pre-training (เราไม่ได้ทำ):
  Data: หลาย TB (Wikipedia, GitHub, ฯลฯ)
  GPU: 1000+ A100, ~$10M, ~3 เดือน
  ผลลัพธ์: DeepSeek-R1-Distill-Qwen-1.5B (open weights)

Fine-tuning (เราทำในโปรเจกต์นี้):
  Data: 150 Q&A pairs (รวม 105 train + 22 val + 23 test)
  GPU: RTX 3050 Ti 4GB (GPU laptop ตัวเดียว)
  เวลา: 107 นาที
  ผลลัพธ์: LoRA adapter 73 MB (ใส่บนโมเดลเดิมเพื่อ "ปรับ" ให้ตอบสไตล์เรา)
```

**Insight สำคัญ**: pre-training ให้ "ภาษา + ความรู้ทั่วไป", fine-tuning สอน "สไตล์ + ความรู้เฉพาะทางของเรา"

---

## 4. ทำไมต้อง LoRA — และมันทำอะไร

### ปัญหา: full fine-tuning แพงมาก

โมเดล 1.5B parameters × 4 bytes (fp32) × 4 (gradients + optimizer state) = ~24 GB VRAM
→ GPU laptop 4 GB ไม่มีทางทำได้

### LoRA (Low-Rank Adaptation, 2021)

แทนที่จะ update น้ำหนัก **W** (ใหญ่ d×d) เราใส่ adapter เล็ก ๆ ทับลงไป:

```
W_new = W (frozen, ของเดิม)  +  A·B  (เรียนใหม่ตัวนี้)
        ขนาด d×d                  ขนาด d×r และ r×d, r=16
```

**r (rank)** เล็กมาก (16 vs d=2048 ของ Qwen) → น้ำหนักที่ต้องเรียน **ลดลง 100×**

### ผลลัพธ์ในโปรเจกต์เรา

จาก [`adapter_config.json`](../notebooks/calories_guard_adapter/adapter_config.json):
- เรียนแค่ 18,464,768 ของ 1,795,552,768 parameters = **1.03%**
- Adapter file 73 MB (vs full model ~3 GB)
- VRAM peak ตอนเทรน: **2.81 GiB / 4.00 GiB** ← เพราะ LoRA + 4-bit quant

### LoRA hyperparameter ที่เราใช้

```python
LoraConfig(
    r=16,                    # rank — ใหญ่ขึ้น = capacity เพิ่ม + ใช้ memory เพิ่ม
    lora_alpha=32,           # scaling factor (มัก = 2×r)
    lora_dropout=0.05,       # dropout 5% ลด overfit
    target_modules=[
        "q_proj","k_proj","v_proj","o_proj",  # attention
        "gate_proj","up_proj","down_proj",     # MLP
    ],
)
```

---

## 5. Quantization — ทำไมโมเดลใส่ลง GPU 4 GB ได้

### ปัญหา float vs ความแม่น

```
fp32 (32-bit)  : 1.5B params × 4 bytes = 6 GB
fp16 (16-bit)  : 1.5B × 2 = 3 GB
int8 (8-bit)   : 1.5B × 1 = 1.5 GB
nf4 (4-bit)    : 1.5B × 0.5 = 750 MB ← เราใช้
```

### nf4 = NormalFloat 4-bit

ปกติ 4 bit จะเก็บได้แค่ 16 ค่า แต่ nf4 เลือก 16 ค่านั้นให้**กระจายตามการแจกแจงปกติ (normal distribution)** ที่ค่าน้ำหนัก NN มักจะอยู่ → แม่นกว่า uniform 4-bit มาก

### bf16 compute dtype

ตอน "คำนวณ" (matmul) เรา dequantize 4-bit → bf16 (16-bit) แล้วค่อยคูณ → bf16 ทำได้ใน hardware GPU โดยตรง

### โค้ดที่เราใช้ ([llm_provider.py:115](../backend/ai_models/llm_provider.py:115))

```python
BitsAndBytesConfig(
    load_in_4bit=True,
    bnb_4bit_quant_type="nf4",
    bnb_4bit_compute_dtype=torch.bfloat16,
    bnb_4bit_use_double_quant=True,   # quantize ตัว quant constant อีกที (ลด ~0.4 bit/param)
)
```

---

## 6. Dataset & Splits — ทำไมต้องแยก train/val/test

### ปัญหา: model ต้อง "generalize" ไม่ใช่จำแบบฝึกหัด

ถ้าให้ model ดูข้อสอบก่อน แล้วเอาข้อสอบเดิมมาวัด → ได้ 100% เปล่า ๆ ไม่มีความหมาย

### 3-way split ([cell 5](../notebooks/deepseek_finetune.ipynb))

```
Total: 150 pairs
├── Train  (70%) → 105 pairs   ← model เห็น, อัปเดตน้ำหนักจากข้อมูลชุดนี้
├── Val    (15%) →  22 pairs   ← วัดทุก epoch ระหว่างเทรน → ตัดสินใจ early-stop
└── Test   (15%) →  23 pairs   ← วัดครั้งเดียวตอนจบ ห้ามมา tune
```

**Leakage** = data จาก val/test หลุดเข้า train โดยบังเอิญ → metric สวยปลอม

ในโปรเจกต์เราเก็บ split ไว้เป็น JSON ([`notebooks/data/`](../notebooks/data/)) → re-run notebook ใช้ split เดิมเสมอ ไม่ shuffle ใหม่

### Overfitting (สำคัญที่สุด)

| สัญญาณ | หมายความว่าอะไร | แก้ยังไง |
|---|---|---|
| Train loss ลด, Val loss คงที่/ขึ้น | จำแบบฝึกหัดได้ แต่ไม่ generalize | early stopping, ลด epoch, dropout, more data |
| Train loss ลด, Val loss ลดด้วย | กำลังดี | เทรนต่อได้ |
| Train loss ไม่ลง | underfit / model เล็กเกิน / lr ผิด | model ใหญ่ขึ้น, lr สูงขึ้น |

ในโปรเจกต์เราเห็น **overfit ชัดที่ epoch 4-5**: VAL unigram peak ที่ epoch 3 (13.9%) แล้วลดเหลือ 11.4% ที่ epoch 5 → จึงเพิ่ม "best-checkpoint save" ใน [`_patch_best_checkpoint.py`](../notebooks/_patch_best_checkpoint.py)

---

## 7. Training Loop — ตัวเลขแต่ละตัวหมายความว่าอะไร

### โค้ดที่เราใช้ (cell 17 หลัง patch)

```python
EPOCHS = 5

for epoch in range(EPOCHS):
    args = TrainingArguments(
        per_device_train_batch_size=1,        # ดู 1 ตัวอย่างต่อรอบ
        gradient_accumulation_steps=8,         # สะสม 8 รอบค่อย step (เสมือน batch=8)
        learning_rate=2e-4,                    # ก้าวยาวแค่ไหนต่อ step
        bf16=True,                             # คำนวณด้วย bf16 (เร็ว + ประหยัด memory)
        gradient_checkpointing=True,           # แลก compute เพื่อ memory
    )
    trainer = Trainer(model=model, args=args, train_dataset=train_ds, ...)
    trainer.train()
    eval_alignment(VAL_QA)   # check progress ทุก epoch
```

### Hyperparameter cheat sheet

| Knob | เพิ่มแล้วเกิดอะไร | ลดแล้วเกิดอะไร |
|---|---|---|
| **learning_rate** | เรียนเร็ว แต่อาจ diverge / ขึ้น ๆ ลง ๆ | เรียนช้า อาจติดอยู่ใน local min |
| **batch_size** | gradient เสถียรกว่า ใช้ memory เยอะ | gradient noisy ได้ generalization บางที |
| **grad_accum_steps** | เสมือน batch ใหญ่ขึ้นโดยไม่ใช้ memory | — |
| **epochs** | เรียนหนักขึ้น เสี่ยง overfit | เสี่ยง underfit |
| **dropout** | regularization แรงขึ้น | regularization อ่อนลง |

### Gradient checkpointing (memory hack)

ปกติ NN ต้องเก็บ activation ของทุก layer เพื่อทำ backward → memory เยอะ
**Gradient checkpointing**: ทิ้ง activation, ตอน backward คำนวณใหม่ → ประหยัด memory ~30% แต่เทรนช้าลง ~20%

ในเรา 4 GB GPU → เปิด `USE_GRAD_CKPT=True`, Colab T4 16 GB → ปิด (เร็วกว่า)

---

## 8. Evaluation — รู้ได้ยังไงว่า model "ดีขึ้น"

### Loss vs Quality metrics

- **Loss (cross-entropy)** = "ทำนาย token ถัดไปเก่งแค่ไหน" — ลดเสมอตอนเทรน
- **Quality metrics** = วัด output จริง ๆ ว่าตรงคำตอบที่อยากได้แค่ไหน

ใน LLM, loss ที่ต่ำลงไม่ได้แปลว่า output ดีขึ้นเสมอ — ต้องวัดด้วย metric แยกอีกชั้น

### Metric ที่เราใช้ (cell 16 + 22)

ปัญหา: ภาษาไทยไม่มี space → split ตามตัวอักษรไม่ work

วิธีของเรา:
1. ใช้ `WordBoundaryMLP` ที่เทรนเองตัด **คำไทย** ออกมา
2. คำนวณ Jaccard similarity ระหว่าง expected กับ generated:

```
Jaccard(A, B) = |A ∩ B| / |A ∪ B|

unigram : เซตของ "คำเดี่ยว" ที่ปรากฏ
bigram  : เซตของ "คู่คำติดกัน" (จับ word order หลวม ๆ)
exact   : ตรงเป๊ะทั้งประโยคหรือเปล่า (มักจะ 0%)
```

### ผลของเรา (TEST 23 ข้อ, 2026-04-25)

```
Baseline (DeepSeek ดิบ ๆ ไม่ fine-tune):
  unigram   ~3.0%
  bigram    ~0.6%
  exact     0.0%

After 5 epoch LoRA fine-tune:
  unigram   16.1%   ← สูงขึ้น 5×  ✓
  bigram     8.3%   ← สูงขึ้น 14× ✓
  exact      0.0%   ← ยากมากกับ 150 pairs
```

ตัวเลข 16% ไม่ใช่ "ดี" แต่ **ทิศทางถูก** — model เรียนรู้สไตล์ตอบจริง

---

## 9. Inference — ตอน "ใช้งาน" จริง

### Generation ทำงานยังไง

```python
output_tokens = []
context = encode(prompt)
for step in range(max_new_tokens):
    logits = model(context)               # คำนวณ score ของทุก token
    probs = softmax(logits / temperature) # แปลงเป็น probability
    probs = top_p_filter(probs, top_p=0.9) # กรองเฉพาะ token ที่ความน่าจะเป็นรวม 90%
    next_token = sample(probs)            # สุ่ม
    if next_token == EOS:
        break
    output_tokens.append(next_token)
    context = context + [next_token]
```

### Inference parameter cheat sheet

| Param | ค่า | ผล |
|---|---|---|
| **temperature** | 0.0 = greedy (เลือก argmax เสมอ → deterministic) | ต่ำ = consistent, สูง = สร้างสรรค์/มั่ว |
| | 0.7 = default ของเรา | balance |
| | 1.5+ | random มาก |
| **top_p** (nucleus) | 0.9 | คัด token ที่รวมความน่าจะเป็น 90% (ตัด tail) |
| **top_k** | 50 | คัดเฉพาะ top 50 (เราไม่ใช้ — top_p ดีกว่า) |
| **repetition_penalty** | 1.0 | ไม่มีการลงโทษซ้ำ (default) |
| | 1.3 (เราใช้) | ลด score ของ token ที่ซ้ำลง 30% — ป้องกัน loop |
| **max_new_tokens** | 256 (เรา) | จำกัดความยาว output |
| **eos_token_id** | tokenizer.eos | บอก model ว่าหยุดได้ |

### ทำไมเราต้องปรับใหม่ตอน integration test

ก่อนแก้: `max_new_tokens=1024, repetition_penalty=1.0`
→ Latency 180-210s/call + output **infinite loop** ("ต้องติดต่อ ต้องติดต่อ ต้องติดต่อ...")

หลังแก้: `max_new_tokens=256, repetition_penalty=1.3`
→ Latency 32-45s/call + ไม่ loop (แต่ quality ยังต่ำเพราะ dataset เล็ก)

---

## 10. Tour ของไฟล์ในโปรเจกต์

### Notebook side (`notebooks/`)

| ไฟล์ | หน้าที่ |
|---|---|
| [`deepseek_finetune.ipynb`](../notebooks/deepseek_finetune.ipynb) | Main notebook — 23 cells: dataset, MLP, LoRA train, eval, save |
| [`data/{train,val,test}.json`](../notebooks/data/) | Persistent split — ไม่ shuffle ใหม่ระหว่าง re-run |
| [`_smoke_test.py`](../notebooks/_smoke_test.py) | CPU smoke test ก่อนรันจริง — ไม่ต้อง GPU |
| [`_gpu_smoke.py`](../notebooks/_gpu_smoke.py) | GPU smoke — โหลด 4-bit + LoRA + 1 forward/backward → confirm fits |
| [`_run_full.py`](../notebooks/_run_full.py) | Flat-script runner (bypass Jupyter kernel ที่พังบน Win + Py 3.13) |
| [`_inject_outputs.py`](../notebooks/_inject_outputs.py) | ใส่ stdout + figures กลับเข้า .ipynb หลังรันเสร็จ |
| [`_patch_vram_aware.py`](../notebooks/_patch_vram_aware.py) | Patch cells ให้ auto-detect VRAM → เลือก config |
| [`_patch_best_checkpoint.py`](../notebooks/_patch_best_checkpoint.py) | Patch cell 17 ให้ save best-VAL checkpoint แทน last |
| `calories_guard_adapter/` | Output: LoRA weights 73 MB (gitignored — share via LFS) |

### Backend side (`backend/`)

| ไฟล์ | หน้าที่ |
|---|---|
| [`ai_models/llm_provider.py`](../backend/ai_models/llm_provider.py) | abstraction `generate()` — route ไปยัง gemini / deepseek / local ตาม env |
| [`scripts/test_local_llm.py`](../backend/scripts/test_local_llm.py) | Integration smoke test — ยิง 3 prompt ผ่าน adapter จริง |

### Docs

| ไฟล์ | หน้าที่ |
|---|---|
| [`AI_LLM_FINETUNE_STATUS.md`](AI_LLM_FINETUNE_STATUS.md) | สถานะปัจจุบัน + TODO list |
| `AI_LEARNING_GUIDE.md` (ไฟล์นี้) | คู่มือเรียน AI สำหรับเริ่มต้น |

---

## 11. แผนเรียนต่อ — ให้ลำดับฟรีและจ่าย

### ระดับ 1 — Foundation (1-2 เดือน)

**ฟรี:**
- [3Blue1Brown — Neural Networks](https://www.youtube.com/playlist?list=PLZHQObOWTQDNU6R1_67000Dx_ZCJB-3pi) (visual ที่สุด ใน YouTube)
- [Andrej Karpathy — Neural Networks: Zero to Hero](https://www.youtube.com/playlist?list=PLAqhIrjkxbuWI23v9cThsA9GvCAUhRvKZ) — สร้าง GPT จากศูนย์ใน Python (best for devs)
- [fast.ai — Practical Deep Learning](https://course.fast.ai/) — top-down, hands-on จริง

**สิ่งที่จะได้:** เข้าใจ NN, backprop, embedding, attention, GPT architecture

### ระดับ 2 — LLM specifics (1-2 เดือน)

- [HuggingFace NLP Course](https://huggingface.co/learn/nlp-course) — ใช้ tools ที่เราใช้จริง (transformers, datasets, tokenizers)
- [LoRA paper](https://arxiv.org/abs/2106.09685) — อ่านได้แล้วถ้าผ่านระดับ 1
- [QLoRA paper](https://arxiv.org/abs/2305.14314) — เทคนิค 4-bit + LoRA ที่เราใช้
- [HuggingFace PEFT docs](https://huggingface.co/docs/peft) — library ที่เราใช้

### ระดับ 3 — Production / Deployment

- [llama.cpp](https://github.com/ggerganov/llama.cpp) — GGUF quant + CPU inference (ทางเดียวให้ Railway/cloud non-GPU ใช้ได้)
- [vLLM](https://github.com/vllm-project/vllm) — production LLM serving (sampling, batching, KV-cache)
- [DPO paper](https://arxiv.org/abs/2305.18290) — preference fine-tune หลังมี user feedback

### ระดับ 4 — Research

- [Attention Is All You Need (Transformer paper, 2017)](https://arxiv.org/abs/1706.03762)
- Anthropic / OpenAI blog posts บน scaling laws
- Daily on [arxiv-sanity](https://arxiv-sanity-lite.com/)

### Tool / lib ที่ควรลอง

```bash
# Inference / serving
pip install transformers          # core: load + run โมเดลใด ๆ บน HF
pip install peft                  # LoRA / QLoRA / adapter wrappers
pip install bitsandbytes          # 4-bit / 8-bit quant
pip install accelerate            # multi-GPU / device_map
pip install datasets              # HF dataset hub + ETL
pip install vllm                  # production-grade inference
pip install llama-cpp-python      # CPU inference (GGUF)

# Training
pip install trl                   # RLHF / DPO / SFTTrainer
pip install unsloth               # 2× faster LoRA fine-tune (ลองหลังคุ้น HF)

# Evaluation
pip install lm-eval               # standard LLM benchmarks
```

---

## 12. คำถามที่คน level 0 ถามบ่อย

**Q: ทำไมต้อง GPU?**
A: NN เป็น matrix multiplication ขนาดใหญ่ — GPU มี core หลายพัน ทำ parallel ได้ ส่วน CPU ทำ sequential ได้ดี. Train โมเดล 1.5B บน CPU ใช้เวลา ~100× ของ GPU

**Q: ทำไม LLM ต้องใหญ่ขนาดนี้?**
A: scaling laws บอกว่า loss ลดลงตาม power-law ของ params + data + compute. ใหญ่ขึ้น → ฉลาดขึ้น (จนถึงจุดที่ data หมดก่อน)

**Q: 1.5B vs 7B vs 70B ต่างกันเท่าไหร่?**
A: 1.5B = ตอบคำถามง่าย ๆ (ที่เราใช้), 7B = พอใช้งานจริง (Llama-3-8B), 70B = ใกล้ GPT-3.5 (Llama-3-70B), 400B+ = GPT-4 / Claude class

**Q: Fine-tune กับ RAG ต่างกันยังไง? ใช้ตัวไหน?**
A:
- **Fine-tune** = สอน "วิธีตอบ" / "สไตล์" / "ความรู้ทั่วไปเฉพาะทาง"
- **RAG** (Retrieval-Augmented Generation) = ดึงข้อมูลจาก database/docs ใส่ context ก่อนตอบ — เหมาะกับ "ข้อมูลที่เปลี่ยน" เช่น ราคาสินค้า
- ใน Calories Guard ในอนาคต อาจใช้ทั้งคู่: fine-tune ให้ตอบสไตล์ไทย + RAG ดึง USDA nutrition database

**Q: ทำไม model ของเรายัง dégénéré (ตอบมั่ว, ซ้ำ ๆ)?**
A: 150 Q&A pairs น้อยเกินไปสำหรับ 1.5B params. Rule of thumb: 500-1000 pairs ต่อ task เป็นจุดเริ่มมีประโยชน์, 5000+ คือเริ่ม solid

**Q: GPU 4 GB ทำอะไรได้บ้าง?**
A: Train ได้ 1-3B params ด้วย LoRA + 4-bit. Train 7B ต้องไป Colab T4 (16 GB) ขึ้นไป. 13B ต้อง 24+ GB

**Q: Training cost ของจริงเท่าไหร่?**
A: GPT-3 = ~$5M, GPT-4 = ~$100M, Claude Opus = unknown แต่ดูทรงคล้าย ๆ. Indie dev ใช้ pre-trained + fine-tune (ของเราใช้ ~ค่าไฟ 50 บาท)

---

## 13. งานที่ทำใน Calories Guard — ลำดับเวลาแบบสั้น

```
Day 1 — Plan + dataset
├── เขียน 60 Q&A pairs (อาหารไทย / macro / exercise / app)
├── Setup notebook structure
└── Verify Python 3.13 + CUDA torch + bitsandbytes

Day 2 — Pipeline expansion
├── ขยาย dataset → 150 pairs
├── เพิ่ม 70/15/15 split + JSON persistence
├── เขียน WordBoundaryMLP segmenter (10 epoch, 96.4% val acc)
├── เพิ่ม VRAM-aware config (4 GB vs 16 GB)
└── Smoke test (CPU + GPU)

Day 3 — Training run
├── รัน 5 LoRA epoch (107 นาที, RTX 3050 Ti 4GB)
├── Train loss: 3.61 → 1.15
├── VAL alignment peak ที่ epoch 3 (overfit แล้ว)
├── TEST: unigram 16.1%, bigram 8.3%, exact 0%
└── Save adapter 73 MB

Day 4 — Polish + integration
├── Inject outputs back into .ipynb
├── เพิ่ม best-checkpoint save (แก้ overfit)
├── เขียน notebooks/README + .gitignore artifacts
├── Backend integration test ผ่าน generate() จริง
├── เพิ่ม 4-bit support ใน llm_provider.py
├── ปรับ inference defaults (max_tokens 1024→256, rep_pen 1.3)
└── Latency: 180s → 35s/call

Next →
├── Dataset → 500+ pairs (impactful แต่ chunky)
├── Push adapter ผ่าน git LFS
├── GGUF quant สำหรับ CPU production
├── Runtime fallback (local ตอบช้า → Gemini)
└── DPO หลังมี user feedback
```

---

## 14. คำแนะนำส่วนตัว (เริ่มจากตรงนี้)

1. **อย่าพยายามอ่าน paper ก่อน** — เริ่มที่ Karpathy YouTube series. ลำดับนั้นออกแบบมาดีที่สุดสำหรับ dev
2. **Code along ทุกตอน** — ดูเฉย ๆ ไม่ผ่าน. เปิด Colab, เขียนตามให้รัน
3. **อย่าเพิ่งเทรนเอง** — ลอง inference ก่อน. ใช้ HuggingFace pipeline ลองรัน 5-6 โมเดลให้รู้สึก "เขาตอบยังไง" ก่อน
4. **เลือก 1 project เล็ก** — ของเราคือ "ตอบโภชนาการ", ของคุณอาจเป็น "ผู้ช่วยตอบ FAQ ของแอป Y". scope แคบ ๆ ก่อนเสมอ
5. **อ่าน issue / PR ของ HuggingFace** — เรียนวิธีคิด/วิธีแก้ปัญหาจริงของ practitioners
6. **รัน notebook ของเราอีกครั้ง** — แก้ค่า hyperparameter ทีละตัว ดูว่าผลเปลี่ยนยังไง (`r=4 vs r=32`, `epochs=2 vs 10`, `lr=1e-4 vs 5e-4`)

โชคดีครับ — ของแบบนี้เริ่มแล้วจะติดมาก
