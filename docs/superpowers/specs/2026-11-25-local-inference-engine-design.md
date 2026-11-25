# Lemon Track v1 — Local Inference Engine Design

Date: 2026-11-25
Status: Draft (pending approval)

## Intent and Why

Lemon Track is an Android-only life organizer: goals, assignments, tasks,
schedule, time blocking, and a kanban board. The existing app (Flutter,
Riverpod, dark theme) already has these surfaces plus an AI chat that
talks to cloud providers.

The differentiator — and the point of v1 — is **fully local AI inference**:
the app runs real LLMs entirely on the device, with no cloud dependency and
no external server. The novel mechanism is **layer streaming**: model
weights stay resident on flash storage, and only the layer currently being
computed is paged into RAM. This makes larger, more capable models viable
on low-end Android devices that could never hold the whole model in memory.

## Goals

- Run LLM inference 100% on-device via llama.cpp, compiled with the Android
  NDK and bridged to Flutter through Dart FFI.
- Implement a custom layer-streaming scheme in the C++ layer: keep only the
  active layer resident in RAM; page layers in/out from flash on demand.
- Ship a **curated model list** (2–4 models, hand-picked across size tiers,
  including at least one MoE model) with known quantizations, tested for
  speed and accuracy on real devices.
- A **device capability check**: scan RAM, chipset, and free storage, then
  recommend and download a compatible model from the curated list.
- Basic chat working end-to-end against the local engine (the existing chat
  UI and thread/message persistence in `LocalStore` stay).
- Token-by-token streaming of the model's reply into the chat UI.

## Non-Goals (v1)

- iOS. Android only.
- Cloud inference in the v1 critical path (existing OpenAI/Claude/OpenRouter/
  Ollama support stays in the codebase but is not the focus).
- The **full agent** — AI taking actions on app data (creating tasks,
  scheduling events, moving kanban cards) is **deferred to v1.5**, because
  small local models are weak at reliable tool-calling. v1's AI is
  conversational only.
- Arbitrary user-supplied GGUF models. Only curated models are supported.

## Anti-Goals (what would make this a failure)

- Pretending local inference works where it doesn't. If a device can't run
  a model at usable speed, the capability check must say so honestly.
- A cloud fallback required for the app to function.

## Constraints

- Flutter app; native work happens in Kotlin/C++ via the Android NDK and
  Dart FFI bindings (or `flutter_rust_bridge`-free, plain FFI).
- Layer paging performance is bounded by flash read speed. On slow-storage
  devices, tokens/sec will drop; the curated-model tests must quantify this
  and the UI must set expectations (e.g., show a "usable speed" verdict).
- MoE models are a natural fit (few experts active per token → most weights
  can stay on flash); dense models will page every layer per token and be
  slower. The curated list should reflect this trade-off.
- SharedPreferences (`LocalStore`) is the current persistence layer; model
  files need real file storage management (download, verify, delete).

## Approaches Considered

1. **Google AI Edge (MediaPipe / LiteRT LLM API)** — official on-device
   runtime, easiest integration. Rejected: it's a black box; we cannot
   control how layers page from storage, which is the core novelty.
2. **llama.cpp via FFI with custom C++ layer paging** — full control over
   memory-mapping, quantization, and a custom paging strategy (only active
   layers resident). Chosen. Cost: real NDK/C++ work and a longer road.
3. **Hybrid (AI Edge first, custom engine later)** — faster to first token,
   but the first engine gets thrown away when the paging work lands.

## Decisions Made

- Android only, no iOS.
- Device floor: 4GB RAM with UFS storage. Devices below this are unsupported
  and the capability check must say so.
- Usable speed bar: ~8 tokens/sec. Below that, the capability check should
  steer the user to a smaller model or declare the device unsupported.
- Large model downloads (several GB) are acceptable, but the user must be
  clearly informed before download: model size, expected speed on their
  device, and a recommendation to use Wi-Fi.
- Local inference engine is the v1 priority; the agent comes later.
- Engine: llama.cpp compiled via NDK, wired through Dart FFI.
- Layer streaming: weights on flash (SSD-grade storage), only the active
  layer in RAM, paged per-token as needed.
- Curated models, tuned and tested by us; capability check matches the
  device to the list.
- v1 ships: capability check + model download + local chat + streaming.
  v1.5: agent actions over app data.

## What's Left to the Builder

- Exact llama.cpp fork/branch and how the paging strategy hooks into its
  memory-mapping (`mmap`) path.
- Quantization formats and per-model configs for the curated list.
- Which specific models make the curated list (must include MoE and small
  dense tiers) and their measured tokens/sec on reference devices.
- FFI bridge design: API surface between Dart and the C++ engine
  (load/unload, generate with token callbacks, cancel).
- Model download UX and file verification (checksums).
- Capability-check thresholds (RAM/chipset/storage cutoffs per model tier).
- How the existing chat UI switches from cloud providers to the local
  engine as default.
