# Qwen3.8-27B optimization options for the 18 GiB M3 Pro

Updated 2026-10-04. Recommendations draw on local configuration and existing
logs, source inspection, and publisher evaluations. ByteShape and MTP have now
been tried locally; MLX, Splash, and SlotStream have not been benchmarked here.
This review updates documentation only.

## Recommended order

1. Keep **ByteShape 3.84 BPW without MTP** as the next comparison baseline.
   Existing logs show about 8.1 tokens/s without MTP and 5.8 with it; these
   were ordinary sessions, not controlled benchmark pairs.
2. Test Q8 K / Q4 V cache, then Q4 K / Q4 V if needed. At 32K context these
   save approximately 256 MiB and 512 MiB respectively versus today's Q8/Q8.
3. If more headroom is needed, compare **GSQ-RCO IQ3_S** with **vocabulary-pruned
   ByteShape**. GSQ retains the full vocabulary; pruning offers a different
   quality tradeoff. For coding/math, prefer an ASCII policy that also retains
   Greek and common terminal symbols.
4. Run a bounded **MLX comparison** if testing another engine is worthwhile.
   The linked 4-bit MLX checkpoint is larger than ByteShape, so measure memory
   as carefully as speed. See [MLX and Splash](#7-native-mlx-and-splash).
5. Treat further speculation as a kernel-and-memory experiment. **One draft
   token minimizes rollback storage; it is not an established speed optimum.**
   Splash has promising Metal results but no demonstrated 18 GiB setup in its
   published tests. See the revised MTP section below.
6. Keep **SlotStream as an optional quality comparison**. Its published
   expectations for this memory tier are slower than the current 27B setup.
   See [SlotStream](#8-qwen38-27b-versus-slotstream).

The main opportunity is reducing weight traffic and memory pressure. Raising the
GPU wired-memory limit cannot increase the Mac's physical memory.

## Local setup and measured baselines

Configuration: [local-ai-server.nix](hosts/mandubu-server/local-ai-server.nix).
Client: [local-ai-client.nix](home/profiles/local-ai-client.nix).

The following table records the October 3 Unsloth baseline summarized in
[MAC_MIGRATION.md](MAC_MIGRATION.md); newer ByteShape observations follow it.

| Item | Original configuration or observation |
| --- | --- |
| Hardware | M3 Pro, 18 GiB unified memory; CPU and GPU share this capacity |
| Runtime inspected | llama.cpp 0.5.0, build 11146, commit `7fe450e` |
| Model | `unsloth/Qwen3.8-27B-GGUF:IQ4_XS`, resolving to UD-IQ4_XS |
| Serving | At most one loaded model, one slot, text only, Flash Attention enabled |
| Context/cache | 32,768 tokens; Q8 K and Q8 V |
| Loading | `load-mode = none`; mmap previously caused Metal OOM |
| GPU placement | All 66/66 layers offloaded in the recorded no-MTP run |
| GPU allocations | Model 12,726 MiB; KV 1,088 MiB; recurrent state about 149.6 MiB; compute about 269 MiB |
| CPU model/compute allocations | About 573 MiB, excluding conversation checkpoints and other process memory |
| Generation | 4,129 tokens across five completions: 8.09 tokens/s |
| Memory pressure in that run | Free memory 4–8%; system-wide swapouts increased about 1,646 MiB |
| Current checkpoint policy | `ctx-checkpoints = 4`, `cache-ram = 0` |
| Previous MTP trial | Approximately 6.3–6.5 tokens/s; slower than the no-MTP run |

The old run accumulated 11 conversation checkpoints at 149.626 MiB each.
Today's cap of four limits that component to approximately 599 MiB. This is
already a substantial improvement; count only further savings when comparing
new proposals. Swap counters are system-wide, so the checkpoint growth is a
plausible contributor rather than proven attribution of every swapped page.

### October 4 update: ByteShape and MTP

The working configuration now includes ByteShape's local 3.84 BPW file under
`byteshape/Qwen3.8-27B-GGUF:IQ4_XS`, with 32K context, Q8/Q8 KV, four
checkpoints, and its MTP settings commented out. The installed runtime remains
0.5.0 / `7fe450e`; this Mac reports macOS 27.0.1.

Existing `~/Library/Logs/llama-server.log` entries identify both of these
processes as loading the same ByteShape snapshot:

| Session | Completions | Output tokens | Aggregate decode | Other observations |
| --- | ---: | ---: | ---: | --- |
| PID 55323, MTP enabled | 4 | 3,291 | About 5.80 tokens/s | Acceptance 50.6–61.4%; reported mean length 2.52–2.84 |
| PID 55599, MTP disabled | 3 | 4,109 | About 8.10 tokens/s | Individual completions 8.03–8.12 tokens/s |

Rates are total output tokens divided by total logged decode time. Different
requests and histories prevent a controlled speedup claim, but these sessions
support leaving MTP off for normal use. They do not isolate kernel dispatch
from memory pressure, drafting overhead, or other costs.

## 1. ByteShape IQ4_XS versus GSQ-RCO IQ3_S

All sizes in this table are rounded **decimal GB of files**, not runtime memory.
Loaded tensors, skipped MTP weights, KV, recurrent state, scratch buffers, and
macOS overhead determine whether a configuration fits.

| Candidate | File size | Vocabulary | Intended use |
| --- | ---: | --- | --- |
| Original Unsloth UD-IQ4_XS | 14.3 GB | Full | Original baseline |
| ByteShape IQ4_XS, 3.84 BPW | 13.1 GB | Full | First quality-oriented replacement to test |
| GSQ-RCO IQ3_S, 3.50 BPW | 11.8 GB; about 12.1 GB with MTP | Full | More headroom for caches and speculation |
| Third-party ByteShape ASCII-P1M | 12.25 GB | Pruned | Retain ByteShape's transformer quantization while shrinking vocabulary tensors |
| ByteShape IQ3_S, 3.23 BPW | 11.0 GB | Full | Further compression if the above still do not fit comfortably |

File sources: [Unsloth files](https://huggingface.co/unsloth/Qwen3.8-27B-GGUF/tree/main),
[ByteShape model card](https://huggingface.co/byteshape/Qwen3.8-27B-GGUF),
[GSQ-RCO files](https://huggingface.co/ISTA-DASLab/Qwen3.8-27B-GSQ-RCO-GGUF/tree/main),
and the [pruned ByteShape model card](https://huggingface.co/islamsidratul/Qwen3.8-27B-ByteShape-IQ4_XS-ASCII-GGUF).

**ByteShape remains a useful memory baseline after the local trial.** However,
its IQ4_XS name describes a size class: ShapeLearn chooses mixed quantization
types per tensor, averaging 3.84 bits per weight. It does not keep every tensor
at four bits. GSQ-RCO also uses mixed precision, so the labels alone cannot rank
quality. See the publishers' [ByteShape quantization notes](https://huggingface.co/byteshape/Qwen3.8-27B-GGUF#notes-on-quantization)
and [GSQ-RCO description](https://huggingface.co/ISTA-DASLab/Qwen3.8-27B-GSQ-RCO-GGUF).

ByteShape's own comparison reports the following aggregate scores normalized to
BF16 across its evaluation suite:

| Quantization | BF16-normalized aggregate |
| --- | ---: |
| ByteShape 3.84 BPW | 99.63% |
| GSQ-RCO 3.50 BPW | 99.43% |
| ByteShape 3.23 BPW | 98.72% |

These are publisher results, not percentages of universally retained
intelligence or independent validation. The 0.20 percentage-point difference
between the first two is too small to establish a dependable advantage on your
tasks. Their speed measurements use NVIDIA GPUs; Metal kernels may rank the
quants differently. [ByteShape evaluation and methodology](https://byteshape.com/blogs/Qwen3.8-27B/)

For the full ByteShape candidate, select the exact file
`Qwen3.8-27B-IQ4_XS-3.84bpw.gguf`. The publisher's model identifier is
`byteshape/Qwen3.8-27B-GGUF:Qwen3.8-27B-IQ4_XS-3.84bpw`.
Its embedded MTP weights are included and skipped when MTP is disabled.
[ByteShape model card](https://huggingface.co/byteshape/Qwen3.8-27B-GGUF)

## 2. ASCII, English, and math vocabulary pruning

**Yes: vocabulary pruning is a practical option.** It removes selected rows from
the input embedding and output projection, then rewrites tokenizer metadata and
token IDs. The pruning tool copies retained quantized rows directly, avoiding
another quantization pass. The transformer layers remain intact.
[Pruning tools](https://github.com/bsaleh03/ASCII-Condensed-prune-tools)

ASCII filtering is a character policy. It cannot identify and remove all
non-English knowledge, and English documents can contain Unicode names,
punctuation, paths, symbols, or quoted text. There is no corresponding simple
switch that removes the model's multilingual transformer computation.

### Existing artifact and expected savings

The third-party
[`islamsidratul/Qwen3.8-27B-ByteShape-IQ4_XS-ASCII-GGUF`](https://huggingface.co/islamsidratul/Qwen3.8-27B-ByteShape-IQ4_XS-ASCII-GGUF)
provides `Qwen3.8-27B-ByteShape-IQ4_XS-3.84bpw-ASCII-P1M.gguf`:

- 13.08 GB source becomes 12.25 GB: approximately **0.83 GB / 0.77 GiB smaller**.
- Vocabulary falls from 248,320 to 129,272 entries.
- The publisher reports unchanged non-vocabulary tensors and a retained MTP head.
- Published checks cover a small sample; they do not establish parity for Pi,
  long-context reasoning, or arbitrary coding tasks.

The file reduction is useful, but only part of it reduces the per-token output
projection work. Embedding lookup does not scan the whole embedding table for
each generated token. Expect a modest potential decode improvement plus memory
headroom; do not infer a twofold speedup from halving vocabulary size.

### Choose the character policy carefully

| Policy | Retained characters beyond mandatory tokenizer entries |
| --- | --- |
| P1 | ASCII |
| P1M | ASCII plus a selected set of math and typography symbols |
| P1G | P1M plus selected Greek letters, terminal/status symbols, units, and currency |
| Custom | A policy plus explicit `--keep-chars` additions |

**P1M does not retain Greek-letter tokens such as π, λ, and Ω.** Its name should
not be read as preserving every mathematical character. For your workload I
would start from P1G, inspect the actual retained set, and add characters found
in your source files and tool output. No P1G file size is established here.
[Actual policy definitions](https://github.com/bsaleh03/ASCII-Condensed-prune-tools/blob/main/prune_vocab.py)

The tools preserve special tokens, byte fallback, and partial UTF-8 fragments.
Excluded characters remain representable, but can require more tokens and may
be handled worse. Pruning also changes the possible output-token distribution;
unchanged transformer tensors do not guarantee unchanged answers. Per-token
perplexity comparisons become harder to interpret when tokenization changes.

Before using a custom prune, run the repository's vocabulary audit, character
scan, and prune verifier. Test Pi tool calls, reasoning delimiters, JSON,
Unicode paths, and representative math. For an external DFlash draft, validate
the **same retained vocabulary and token-ID mapping** in target and draft;
matching policy names alone are insufficient. These checks follow the
[pruning repository's verification workflow](https://github.com/bsaleh03/ASCII-Condensed-prune-tools).

## 3. Memory savings available in the existing runtime

### KV quantization and context capacity

For this model's observed 32K cache geometry, approximate KV allocations are:

| Context capacity | K / V type | KV allocation | Savings versus current 32K Q8/Q8 |
| --- | --- | ---: | ---: |
| 32,768 | Q8 / Q8 | 1,088 MiB | — |
| 32,768 | Q8 / Q4 | 832 MiB | 256 MiB |
| 32,768 | Q4 / Q4 | 576 MiB | 512 MiB |
| 24,576 | Q8 / Q8 | 816 MiB | 272 MiB |
| 16,384 | Q8 / Q8 | 544 MiB | 544 MiB |

The Q4/Q4 reduction was also supported by a local `llama-fit-params` estimate.
These values exclude recurrent state and compute buffers. Rows are alternatives;
do not add overlapping cache savings. This hybrid model already has much less
KV than an equally sized model with full attention in every layer.

Start with `cache-type-v = q4_0`, keeping K at Q8. If more memory is needed,
test `cache-type-k = q4_0` too. Validate long-context retrieval and coding quality;
smaller caches can alter accuracy, and Metal decode speed is not guaranteed to
improve. Both types are supported by the installed binary's help output.

Keeping 32K with Q4/Q4 costs about as much KV as 16K with Q8/Q8. That makes cache
quantization attractive before cutting the working context in half. If context
capacity is reduced, update Pi's context window and compaction budgets together.

### Conversation checkpoints and compute buffers

- **Checkpoints 4 → 2:** lowers the snapshot cap from approximately 599 to
  299 MiB, saving up to 299 MiB once the old cap would have filled. Fewer restore
  points can increase prompt reprocessing. Avoid choosing zero without testing
  multi-turn latency.
- **Keep `cache-ram = 0` initially:** the old 8192 MiB setting was a limit, not
  a reservation. That separate cache was empty in the measured run, so disabling
  it did not itself free 8 GiB. Keep in-slot prefix reuse enabled.
- **Try `ubatch-size = 256`, then 128:** smaller physical batches may reduce
  compute scratch at the cost of prefill throughput. The recorded GPU compute
  buffer was only about 269 MiB, so this is a secondary opportunity. Generic
  estimator scratch figures differed from the actual server; use startup logs
  for the deployed configuration.

The defaults and option behavior can be checked against the installed
`llama-server --help` and the [server documentation](https://github.com/ggml-org/llama.cpp/blob/7fe450e/tools/server/README.md).

### MTP on Metal: verification width matters

The earlier Unsloth trial had high acceptance but lower throughput; the newer
ByteShape trial also slowed down. The user's suspicion about narrow Metal
batches has a concrete basis in the installed `7fe450e` source:

- The ordinary matrix-matrix route requires `ne11 > 8`, non-transposed inputs,
  an inner dimension of at least 64, and device support. Here `ne11` is the number of
  activation rows being evaluated, not the configured draft maximum.
  [Exact dispatch condition](https://github.com/ggml-org/llama.cpp/blob/7fe450e/ggml/src/ggml-metal/ggml-metal-common.cpp#L28)
- Before that check, several formats have specialized small-batch kernels for
  widths 2–8; K-quants use that route at widths 4–8. **IQ4_XS is absent from
  those format lists.** A mixed-quant model can therefore take different paths
  at different projections. Calling every batch below eight unoptimized would
  be too broad. [Small-batch dispatch](https://github.com/ggml-org/llama.cpp/blob/7fe450e/ggml/src/ggml-metal/ggml-metal-ops.cpp#L2441)

Verification usually evaluates the current token plus the proposed drafts.
Eight actual drafts can therefore produce nine target rows and cross the
matrix-matrix threshold. Setting `spec-draft-n-max = 8` does not guarantee that
every round reaches it: drafting can stop early. Increasing `ubatch-size`
only changes a capacity limit; it does not manufacture additional drafts.

This explains a plausible source of mixed Mac results. Chip, quantization,
actual verification width, acceptance, draft latency, GDN state handling,
context length, and runtime revision all matter. Source inspection establishes
the dispatch rules; profiling would be needed to attribute this Mac's slowdown.

**Correction to the October 3 recommendation:** one-token MTP is a memory
diagnostic, not a recommendation for peak generation speed. If investigating
further, compare no MTP and draft maxima 1, 3, 7, and 8 with otherwise identical
settings, only after ensuring they fit. The 7/8 pair probes the potential
8-row/9-row boundary; log actual draft lengths and verify GPU placement.

In this installed implementation, the target's recurrent rollback capacity
grows with `spec-draft-n-max`. Using the observed approximately 149.6 MiB state
size, reducing the maximum from three drafts to one saves approximately
**299 MiB of target rollback storage**. One draft still adds roughly 149.6 MiB
over the target's base state, before the MTP context and other buffers.
These allocations are separate from `ctx-checkpoints`.
[Speculative allocation rule](https://github.com/ggml-org/llama.cpp/blob/7fe450e/common/common.h),
[recurrent memory allocation](https://github.com/ggml-org/llama.cpp/blob/7fe450e/src/llama-memory-recurrent.cpp)

Eight draft positions reserve approximately **1,197 MiB of extra target state**,
about 748 MiB more than three, before draft KV, compute buffers, and weights.
Crossing the kernel threshold can therefore create a memory problem. Sequential
MTP drafting and rejected proposals can also erase a faster verification pass.

Optional settings for the one-token memory diagnostic:

```ini
spec-type = draft-mtp
spec-draft-n-max = 1
spec-draft-type-k = q8_0
spec-draft-type-v = q8_0
```

Draft cache types default separately to F16 in this build. Explicit Q8 avoids
assuming that the target's cache settings propagate. MTP reuses the loaded
model's weights while creating another context; stripping an unused embedded
head does not save RAM already avoided by skipping those tensors.
[Installed-version speculative implementation](https://github.com/ggml-org/llama.cpp/blob/7fe450e/common/speculative.cpp)

Hold the draft probability threshold fixed while varying depth; then tune it
separately. Record accepted tokens per verification, draft time, verification
time, and final throughput. Keep MTP disabled unless the complete cycle wins.

## 4. What transfers from the linked Reddit setup?

The [linked comment](https://www.reddit.com/r/LocalLLaMA/comments/1wh21e9/comment/p9zqrgr/)
combines vocabulary-pruned ByteShape weights, a pruned small DFlash draft,
adaptive KV streaming, phase-based buffer reuse, and draft unloading on an
RTX 5060 Ti. Its reported 35–80 tokens/s and very long contexts are measurements
of that combined NVIDIA setup, not projections for this Mac.

| Component | Relevance here |
| --- | --- |
| ByteShape target | High: standard GGUF candidate for the existing server |
| Vocabulary pruning | High for memory; requires the language/symbol checks above |
| Small DFlash draft | Worth a separate Metal benchmark after the simpler changes |
| Sharing prefill/decode scratch across phases | Useful design, but the linked implementation needs backend support |
| Streaming KV from system RAM into VRAM | Addresses separate host/device memory; much less compelling on this unified-memory Mac |
| Unloading the draft at large contexts | Potential memory policy; adds reload/transition costs and requires the fork's implementation |

### The small DFlash draft is a real candidate

[`HermiHg/Qwen3.8-27B-DFlash2-Q2_K_S-MIX-GGUF`](https://huggingface.co/HermiHg/Qwen3.8-27B-DFlash2-Q2_K_S-MIX-GGUF)
is approximately **535 MiB / 0.56 GB**, versus a 1,090 MiB reference Q4 draft.
Its publisher measured similar throughput on one prompt and an NVIDIA GPU,
with some acceptance loss. That is useful evidence for testing the smaller
draft, not proof of Metal performance.

The Reddit author's *pruned* draft is 535,306,304 bytes, approximately 0.535 GB;
that is distinct from the unpruned model's 535 MiB. Their target-plus-draft sum
of roughly 12.8 GB covers files, not all runtime allocations.

The installed binary recognizes `draft-dflash`. Start with the full-vocabulary
target and compatible draft to establish correctness and speed, then consider
matched pruning. A three-draft experiment is a reasonable initial comparison
with the drafter's published tests.

**Budget more than the draft's file size.** The stock recurrent allocation rule
also applies to DFlash: three draft positions imply approximately 449 MiB of
additional target rollback state for this geometry, before draft KV and compute
buffers. Seven positions would imply about 1,047 MiB. A small draft therefore
does not make speculation a half-gigabyte feature.
[Stock allocation rule](https://github.com/ggml-org/llama.cpp/blob/7fe450e/common/common.h)

### The streaming fork is not currently a Mac optimization to apply

Raymond's V2 implementation maintains host KV history and lends one device arena
to different execution phases. Its qualified end-to-end path targets CUDA; the
documentation says other backends lack streamed-attention execution paths.
The [implementation and supported scope](https://github.com/RaymondHuang210129/llama.cpp-adaptive-kv-streaming)
therefore do not establish a working Metal version.

On this Mac, moving KV from GPU-addressable memory to CPU memory still consumes
the same 18 GiB pool. Maintaining a host history plus a resident GPU copy could
increase total usage. A Metal implementation that shares allocations
could help, but that is development work. With only 1,088 MiB of target KV at
32K today, cache quantization is a simpler first step.

Also, [troed's fork](https://github.com/troed/llama.cpp-adaptive-kv-streaming)
changed on October 3: its current main documentation describes V2 plus ngram/MTP
changes and links the earlier ejectable MTP/DFlash version on another branch.
Do not assume the default branch reproduces the exact Reddit configuration.

Ngram speculation is an additional low-priority experiment for repetitive code
or copying text: the installed server exposes it and it requires no neural
draft weights. Verification and rollback still cost time and memory. Test it
alone before combining speculative methods.

## 5. Higher precision and other tradeoffs

- **Larger weight quants:** Unsloth lists Q4_K_S around 15.4 GB, Q4_K_M around
  16.5 GB, and Q5 variants around 18.7–19.8 GB. Q4_K_S may become testable after
  reclaiming memory; Q5 leaves too little room for normal runtime and macOS
  overhead at 18 GiB. Compare task quality before spending reclaimed memory on
  a larger file. [Unsloth files](https://huggingface.co/unsloth/Qwen3.8-27B-GGUF/tree/main)
- **Thinking effort:** Pi currently defaults to `xhigh`. Use `medium` or `low`
  for routine edits if quality holds. Generating fewer reasoning tokens can
  shorten completion time substantially without changing tokens/s. Keep
  `preserve_thinking` and prefix behavior fixed during performance comparisons.
- **GPU fit and loading:** retain automatic fitting while all target layers
  fit. Check placement after enabling speculation. CPU offload shares the same
  physical memory and can slow execution. Keep the working non-mapped load mode;
  the prior mmap failure is stronger local evidence than a generic preference
  for mmap.
- **Runtime updates:** the inspected 0.5.0 release already includes Metal SSM
  fusion work. Prioritize a newer build when its changes address this model or
  backend; CUDA speedups do not imply Metal speedups.
  [Release notes](https://github.com/ggml-org/llama.cpp/releases/tag/v0.5.0)
- **Alternate runtimes:** evaluate each engine's actual memory plan and model
  support. MTPLX's cited Qwen3.8-27B configuration recommends 32 GB and lists
  a roughly 20 GiB bare minimum peak. That is a requirement of that setup,
  not a universal minimum for plain MLX. See the dedicated section below.
  [MTPLX requirements](https://github.com/youssofal/mtplx)

For perspective, the M3 Pro has 150 GB/s memory bandwidth. Dividing that by the
roughly 13.3 GB of recorded GPU weights gives an optimistic scale of about
11 ordinary decode steps/s before other traffic and overhead. This is a rough
bandwidth estimate, not a hard performance ceiling; speculative verification
can produce multiple accepted tokens per weight pass. It helps explain why
smaller weights and effective speculation are more promising than minor server
features. [Apple specifications](https://support.apple.com/en-au/117736)

## 6. How to compare candidates without confounding the results

### Preserve the model-specific configuration

The router's global `[*]` preset sets only context capacity. A newly named
model will **not inherit another model's** load mode, cache types, or checkpoint
cap. ByteShape now has an explicit preset. Give any further candidate's exact
model ID a preset containing the comparison settings first.

Likewise, Pi's default model, reasoning mapping, `preserve_thinking`, context
window, and compaction overrides are keyed to the current Unsloth ID. Carry
those settings to the tested ID and confirm its chat template supports the
same tool/reasoning flow. Otherwise the comparison may change both model and
client behavior.

### Suggested trial sequence

| Trial | Change from its comparison baseline |
| --- | --- |
| A | ByteShape 3.84 BPW, current checkpoint cap, no MTP: controlled baseline |
| B | Optional matched Unsloth comparison; ordinary ByteShape sessions already exist |
| C | Best candidate with Q8 K / Q4 V, then optionally Q4/Q4 |
| D | Checkpoint cap 2; separately test microbatch 256 if needed |
| E | Compare GSQ or pruned ByteShape with matched settings and task quality checks |
| F | MLX without speculation, first at short context, then the actual working context |
| G | Optional MTP width diagnostic or separate DFlash/ngram trial if headroom remains |
| H | Splash capacity experiment or SlotStream quality comparison, using the criteria below |

Use repeated short, medium, and near-32K prompts, plus a real multi-turn Pi
coding session. Keep sampling and thinking effort fixed. Include English/math,
Greek symbols, JSON/tool calls, paths, and some Unicode input for pruning tests.

Record:

- Startup model, KV, recurrent, and compute allocations; target and draft GPU
  placement; peak process footprint and system memory pressure.
- Changes in swap activity during each trial, accounting for other applications.
- Prefill speed, time to first token, generation tokens/s, and total task time.
- Prefix reuse, checkpoint restores, and extra prompt reprocessing across turns.
- Speculative acceptance and time spent drafting/verifying when enabled.
- Task correctness. With different tokenizers, compare completion time and
  useful output as well as token counts.

Keep a change when it improves the desired tradeoff under sustained use. A load
that succeeds but pushes the machine into swap is not a successful memory fit.

## 7. Native MLX and Splash

### Native MLX: worth measuring, with a tighter weight budget

**Yes, consider an MLX baseline; a format change alone does not establish a
speed or capacity improvement.** MLX uses its own operators, graph execution,
and quantization layouts. llama.cpp's batch threshold does not determine MLX's
behavior, but both engines use the same Mac memory bandwidth.

The linked [MLX checkpoint](https://huggingface.co/mlx-community/Qwen3.8-27B-4bit)
uses affine 4-bit quantization with groups of 64. Its weight index totals
**16,054,262,240 bytes: 16.05 GB / 14.95 GiB**. This is materially larger than
the approximately 13.1 GB ByteShape GGUF. The total includes vision weights;
text-only loading can discard them, so it is not an exact resident-memory
estimate. [Quantization configuration](https://huggingface.co/mlx-community/Qwen3.8-27B-4bit/blob/main/config.json),
[weight index](https://huggingface.co/mlx-community/Qwen3.8-27B-4bit/blob/main/model.safetensors.index.json)

With 18 GiB total, macOS, attention KV, recurrent state, and prefill scratch
still need room. The same attention geometry at 32K needs approximately 2 GiB
of unquantized 16-bit KV. Plain MLX generation defaults to no KV quantization,
so comparing defaults against today's Q8 llama.cpp cache would be misleading.
The CLI provides `--kv-bits`, `--quantized-kv-start`, and
`--prefill-step-size`; an initial memory-conscious trial can use 8-bit KV from
step zero and a prefill step of 256. These affect attention caches and scratch,
not the quantization of the model's recurrent state.
[Generation implementation and options](https://github.com/ml-explore/mlx-lm/blob/main/mlx_lm/generate.py)

The inspected MLX-LM Qwen implementation supports text-only loading by removing
vision tensors, but it also drops `mtp.*` weights. **Downloading an MLX model
does not automatically enable native MTP.** An engine implementing the matching
speculative method is a separate choice.
[Qwen implementation](https://github.com/ml-explore/mlx-lm/blob/main/mlx_lm/models/qwen3_5.py)

Suggested evaluation:

1. Unload the llama.cpp model before loading MLX; two servers can otherwise
   exceed memory even if each has a one-model policy.
2. Start without speculation at short context. Record peak process memory,
   swap activity, prefill and decode speed, then repeat at 8K and 32K if it fits.
3. Keep reasoning effort, output length, and tool templates comparable. Test
   cached follow-up turns before adopting it for Pi.
4. If this 4-bit model swaps, consider a smaller audited MLX quantization or
   return to the smaller GGUF. Lower precision introduces another quality
   variable; it is not a clean engine-only comparison.

Do not treat `--max-kv-size` as equivalent to llama.cpp's context-capacity
setting: MLX documents it as a rotating cache that can discard old attention
history. Preserve the intended context semantics when benchmarking.
[MLX cache documentation](https://github.com/ml-explore/mlx-lm#long-prompts-and-generations)

### Splash: promising Metal design, insufficient evidence for 18 GiB

**Splash directly addresses the relevant performance problem.** It combines
DFlash2, model-specific Metal kernels, prefix reuse, and memory planning. It
supports Qwen3.8-27B in both MLX and supported GGUF formats, so using it does not
require choosing the larger MLX file. Your M3 Pro and macOS 27.0.1 satisfy its
M3-or-newer and macOS 26.4-or-newer platform requirements.
[Splash overview](https://github.com/incoai/splash)

The publisher reports the following on the same Unsloth UD-Q4_K_M weights:

| Engine | M3 Max, 40-core GPU | M5 Pro, 20-core GPU |
| --- | ---: | ---: |
| llama.cpp | 17 tokens/s | 16 tokens/s |
| llama.cpp with MTP | 20 tokens/s | 27 tokens/s |
| Splash | 92 tokens/s | 74 tokens/s |

These selected coding-prompt measurements use different hardware from yours
and compare different speculative algorithms. They establish that effective
Mac speculation is possible, not that this M3 Pro will reach those rates.
The documented lower-memory trial uses a **24 GB Mac with IQ3_XXS**.
[Benchmark conditions and lower-memory tests](https://github.com/incoai/splash/blob/main/docs/performance.md)

The normal 4-bit examples specify **at least 36 GB, with 48 GB recommended**;
smaller variants target 24 GB machines. Consequently, I would not plan on the
standard 27B 4-bit Splash setup fitting your 18 GiB Mac.
[Published requirements](https://github.com/incoai/splash#quick-start)

For an 18 GiB experiment, I would start with a substantially smaller supported
GGUF, `--language-only`, a short `--max-context`, and a memory plan that leaves macOS
room. Whether a particular low-bit candidate fits remains unverified. Keep
the quality comparison against ByteShape: a fast, much lower-precision model
may lose the reason for choosing the 27B.

Two implementation constraints matter here:

- `--max-memory` caps Metal allocations, not total process RSS. Disk KV/state
  caching can help retained conversations, but does not remove the need for
  active model and execution memory.
- Splash's documented external draft input is its family's BF16 safetensors
  checkpoint, prepared into its Q4 layout. Do not assume the tiny HermiHg GGUF
  drafter from the llama.cpp section can be substituted directly.

The loader checks architecture and tensor formats, so ByteShape or a pruned
GGUF needs explicit compatibility validation even when its nominal quant type
is supported. [Loading, drafts, and memory behavior](https://github.com/incoai/splash/blob/main/DEVELOPMENT.md)

My priority on this machine is a bounded plain-MLX comparison before investing
in a Splash integration. Splash merits a capacity experiment if a suitable
smaller quant retains the quality you need; its full 4-bit configuration is a
stronger candidate for a machine with more memory.

## 8. Qwen3.8-27B versus SlotStream

**For interactive work on this 18 GiB Mac, I would keep the current 27B ahead
of SlotStream unless task testing shows a substantial quality advantage.**
The observed approximately 8 tokens/s is not a proven hard ceiling across all
engines. Still, improving latency enough for everyday use matters more than
crossing ten as an arbitrary threshold.

SlotStream serves **Qwen3.8-Flash-Next**, a different MoE model, by retaining
shared weights and frequently used experts in RAM and reading other experts
from SSD. Its roughly 105 GB download and approximately 110 GB free-disk
requirement are a sizable commitment on this Mac. It supports Macs with at
least 16 GB and can serve Pi-compatible APIs.
[SlotStream design and requirements](https://github.com/carloslfu/slotstream)

| Evidence | Published speed | What it tells us |
| --- | ---: | --- |
| SlotStream's 16–<24 GB planning range | Approximately 1–6 tokens/s | Relevant memory tier; not an M3 Pro measurement |
| Community M2, 16 GB | About 1.4–1.5 tokens/s | A measured small-memory example, with a different chip/SSD |
| Community M4 Pro, 24 GB, release 0.2.25 | About 5.4 tokens/s | A newer Pro chip with more memory still trails your observed 27B rate |
| Historical M5 Pro, 48 GB, 22 GB process target | 15.86 tokens/s | Its process budget already exceeds this Mac's total RAM |

The small-memory range's upper end is not a measured result on a real Mac in
that tier. SlotStream's simulated 18 GB plan uses an 11.5 GB process target,
32K context, and no MTP; this is a planner example, not the measured plan for
your 18 GiB machine. [Hardware evidence and planning assumptions](https://github.com/carloslfu/slotstream/blob/main/docs/HARDWARE.md)

**My inference:** SlotStream is likely slower here than the resident 27B.
Its larger model could nevertheless solve tasks the 27B misses. Neither the
parameter count nor these throughput measurements establish that quality gain.
The source artifact's publisher also reports meaningful degradation from uniform
4-bit quantization and prefers its mixed 4/8-bit build on a perplexity test.
That does not rank coding ability against the 27B, and it does not establish
SlotStream compatibility with the alternate artifact.
[Flash-Next quantization evaluation](https://huggingface.co/pipenetwork/Qwen3.8-Flash-Next-MLX-4bit#quality)

For scale, 1,000 generated tokens take about **2.1 minutes at 8 tokens/s**, versus
**2.8–16.7 minutes at 1–6 tokens/s**, before prompt processing and tool calls.
Reasoning tokens count toward that time. Long cold prompts add SSD work, while
cached follow-up turns can be much better.

If testing SlotStream, start with `slotstream doctor` to inspect its memory and
disk plan before downloading the model. Compare the same 5–10 real coding/math
tasks: successful fixes, retries, elapsed time to a correct answer, tool-call
validity, cold prefill, and cached follow-ups. Prefer internal SSD storage for
this workload; the project's hardware reports show large slowdowns on a
10 Gb/s external drive.

Normalize thinking settings: `slotstream launch pi` defaults to thinking off,
whereas this repository's Unsloth 27B profile defaults to `xhigh`. Also, the launcher
writes Pi provider configuration; this setup should express any adopted
provider declaratively and route it through the existing tunnel/sandbox design.
Use the server's reported context limit instead of copying the guide's 64K
example. [Pi integration details](https://github.com/carloslfu/slotstream/blob/main/docs/CODING-AGENTS.md#pi)

For now: use the resident 27B for harder local tasks, compare the existing 9B
for routine edits where responsiveness matters, and evaluate SlotStream as an
optional slower model for tasks that justify the wait.
