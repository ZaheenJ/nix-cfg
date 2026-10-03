# SSD-streamed local AI experiments

Research snapshot: 2026-10-02. No SSD-streaming candidates were installed or tested as part of this investigation.

## Hardware and goal

- Server: Apple M3 Pro MacBook Pro, 18 GB unified memory, macOS 27.0.1. A read-only `df` check showed about 346 GiB free on the internal SSD on 2026-10-02.
- Current baseline: Qwen3.8-27B through `llama-server`, used remotely by Pi on `home-g16`. Compare any candidate against the same coding-agent tasks, not just an isolated token-generation benchmark.
- Aim: see whether SSD-streamed mixture-of-experts (MoE) models offer better practical coding quality within this memory limit. An MoE runtime can keep shared weights and a small expert cache in memory, fetching routed expert weights from SSD as needed. This works much better for sparse MoE models than for a dense model that uses nearly every weight for each token.

The [Qwen3.8-Flash-Next model card](https://huggingface.co/Qwen/Qwen3.8-Flash-Next) reports higher scores than Qwen3.8-27B on DeepSWE 1.1 (58.7 vs. 42.2), SWE-bench Pro (62.5 vs. 61.7), and NL2Repo-Bench (48.1 vs. 42.3). These are publisher-reported model evaluations, not measurements of the SSD-streamed, locally quantized builds at 32K context. A larger parameter count or faster decode alone does not establish a quality improvement for our work.

## Candidate runtimes

| Runtime and model | Storage and memory evidence | Assessment for 18 GB M3 Pro |
| --- | --- | --- |
| [Whallm](https://github.com/yanun0323/Whallm), Qwen3.8-Flash-Next FP8 | Original Qwen download is about 117.52 GiB. The published 3,072-slot run used about 17.49 GiB of *process footprint* on a larger Mac; Whallm recommends 64 GiB unified memory. [Benchmark details](https://github.com/yanun0323/Whallm/blob/master/BENCHMARK.md). | Storage fits, but that measured cache configuration leaves effectively no memory for macOS. A smaller expert cache may reduce memory and speed; no measured 18 GB result was found. Treat as experimental, not a known fit. |
| [DS4 IQ2 GGUF](https://huggingface.co/ivanfioravanti/Qwen3.8-Flash-Next-DS4-IQ2) | Current main GGUF is 44.81 GB and its required Q4_1 PLE sidecar is about 32.00 GB: 76.81 GB (71.53 GiB) together on disk. The main weights alone are 41.73 GiB. The GGUF requires the special `qwen3.8-flash-next` DS4 branch with padded-down support; compatibility with other runners is not claimed. | The documented DS4 runtime cannot run it within 18 GB: [SSD expert streaming is not implemented for this model](https://github.com/antirez/ds4/blob/main/docs/QWEN38_FLASH_NEXT.md). The PLE table's SSD paging does not solve the main-weight memory requirement. The existing `llama-server` cannot simply load this GGUF. |
| [Slotstream](https://github.com/carloslfu/slotstream), Qwen3.8-Flash-Next 4-bit | Different model format, around 105 GB of weights and about 110 GB of free SSD space required. It supports 16 GB Macs; its simulated 18 GB automatic plan targets 11.5 GB of memory, 32,768 context tokens, and no MTP. [Hardware guide](https://github.com/carloslfu/slotstream/blob/main/docs/HARDWARE.md). | Best documented, reproducible Flash-Next candidate for this Mac. The 18 GB plan is an allocation estimate, not a measured 18 GB result. Nearby reported warm-decode speeds are 1.48 tokens/s on a 16 GB M2 mini and 5.41 tokens/s on a 24 GB M4 Pro. The project's broad 16–under-24 GB estimate is about 1–6 tokens/s. |

Whallm and Slotstream use their own model formats. The linked DS4 IQ2 GGUF cannot be reused directly by either one. Whallm and Slotstream expose OpenAI-compatible servers; Slotstream also [documents Pi integration](https://github.com/carloslfu/slotstream/blob/main/docs/CODING-AGENTS.md). A Pi instance on `home-g16` should be able to reach either server through an SSH tunnel and a Pi custom provider, analogous to the current setup. This has not been tested.

### The 18 GB M3 Pro article

The author of [“Running the 77GB Qwen3.8-Flash-Next on an 18GB Mac”](https://note.com/kotokotoudon/n/nc23c32add842?hl=en) reports using a custom runtime, Tsugumi, on an 18 GB M3 Pro MacBook Pro. Their reported results are 32K context, around 90 input tokens/s, roughly 7–8 output tokens/s as context grows, and 10 output tokens/s on a math task *including MTP*. They report a 12K-token input without swapping. The article's 1.8 GB process-memory figure is not a complete system-memory accounting: shared weights, mapped files, macOS file cache, and other allocations still matter.

This is first-person evidence that SSD-streamed Flash-Next can run on the same hardware. The article says the runtime repository was still under development and the author planned to release it after further verification; no reproducible release was found during this review. The article also mentions reducing its model from 77 GB to 74 GB, so its tested artifact may differ from the current 76.81 GB DS4 IQ2 plus sidecar release. Its result cannot be reproduced just by starting DS4 or our current `llama-server` with the linked GGUF.

## Other comparable SSD-streaming work

- [SSD MoE](https://github.com/RasoulNik/ssdmoe) streams Qwen3.5-35B-A3B experts from the original roughly 19 GB MLX checkpoint. The author reports 7–8 fresh and 10–12 warm output tokens/s on a 16 GB M4 MacBook Air at **K=4**, while the trained routing setting is **K=8**. The project's estimate at K=8 is roughly 4–5 tokens/s. K=4 is a quality/speed tradeoff, so the headline speed should not be treated as a full-quality result. It has an OpenAI-compatible server and tool-call support. It is a smaller, cheaper experiment, though a quality gain over Qwen3.8-27B is unproven.
- [Slipstream](https://github.com/Schero94/slipstream) is a llama.cpp fork that streams MoE experts from SSD into a bounded cache. On the author's 36 GB Mac, Qwen3.6-35B-A3B Q4 generated about 5.5 tokens/s with a 2 GiB expert cache and about 13 tokens/s with a 10 GiB cache. There is no comparable measured 18 GB result. It requires Q4_K, Q5_K, or Q6_K expert tensors; the linked DS4 IQ2 model is incompatible.
- Internal SSD speed is material. In one otherwise matched [Slotstream hardware comparison](https://github.com/carloslfu/slotstream/blob/main/docs/HARDWARE.md), a 64 GB M4 Max generated 15.93 tokens/s from its internal SSD and 2.98 tokens/s from a 10 Gb/s external USB drive. These numbers are not predictions for the M3 Pro, but support testing from its internal SSD.

## Suggested experiment order

1. Keep the current Qwen3.8-27B server as the baseline and choose a few representative Pi coding tasks with explicit validation flows.
2. Try Slotstream first if the goal is to test Flash-Next on the 18 GB Mac. Confirm its actual memory plan, context window, server/API behavior, and swap activity before comparing quality. Use the internal SSD.
3. Try SSD MoE at the model's trained K=8 setting if a smaller download or a second MoE comparison is useful. Treat K=4 as a separate speed/quality experiment.
4. Revisit Whallm if an 18 GB configuration or benchmark appears. Revisit the specific DS4 IQ2 release if Tsugumi becomes reproducible or DS4 gains SSD expert streaming for Flash-Next.

For each comparison, record download size, process and system memory pressure, swapping, first-token wait, prompt-processing speed, output speed, tool-call reliability, completed-task quality, and total wall time. Large Pi prompts can make prefill more important than decode speed. Retain the exact model quantization, cache settings, context size, and task transcript with each result.
