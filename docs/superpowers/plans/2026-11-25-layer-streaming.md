# Layer Streaming (Active-Layer RAM Residency) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Modify the vendored llama.cpp so model weights stay on flash and only the layer currently being computed is paged into RAM, letting larger models run on low-RAM devices.

**Architecture:** llama.cpp already reads weights via `mmap`; the OS page cache decides residency. We replace that passive behavior with explicit management: a custom `ggml` backend allocator backed by pinned, lockable host memory that evicts layer weights after use, and an optional `mlock`-style hinting scheme (read-ahead of layer N+1 while layer N computes). The Dart FFI surface gains calls to query/set residency policy and report page-fault-driven stall time (for the perf HUD in Plan 3).

**Tech Stack:** C++ (modifications inside `third_party/llama.cpp` fork or wrapper layer), Android NDK, existing Dart FFI bridge from Plan 1.

**Spec:** `docs/superpowers/specs/2026-11-25-local-inference-engine-design.md`

## Global Constraints

- All Plan 1 global constraints still hold (Android-only, arm64-v8a + x86_64, CPU-only, `GGML_NATIVE=OFF`).
- Never keep more than one transformer layer's weights resident at a time in the low-memory mode (this is the feature).
- No accuracy regression vs Plan 1 engine on the smoke model (bit-exact greedy output on same prompt).
- Keep llama.cpp upstream API surface intact where possible: wrap rather than fork if feasible; a fork is acceptable only if wrapping cannot express the paging hook. Record which path was chosen in the spike report.
- Target floor: 4GB RAM device with UFS storage; usability bar 8 tok/s measured end-to-end.

## Review Focus

1. **Eviction of the layer currently in use** — must never happen; guard with reference counting. Pinned by: `test/`… layer-residency unit test in Task 2.
2. **Model file modified/replaced mid-session** — checksum validated at load; mismatch → clear error, no crash. Pinned by Task 4 test.
3. **Paging disabled path** — small models that fit in RAM must bypass the pager entirely (no overhead). Pinned by Task 3 A/B benchmark.
4. **App backgrounded during generation** — Android may kill the process; no corrupted state on resume (model reloads cleanly). Pinned by Task 5 manual check.
5. **Memory ceiling enforcement** — pager must respect a configurable RAM budget and refuse to load a model whose active-layer set cannot fit, with a clear error. Pinned by Task 2 test.

---

### Task 1: SPIKE — map llama.cpp weight residency on Android (throwaway)

**This is a spike per the brainstorming skill: no tests, not bulletproof, findings feed the real plan. Budget ~1 day.**

**Files:**
- Create: `docs/superpowers/spikes/2026-XX-XX-llama-residency-spike.md` (the deliverable)

**Interfaces:**
- Consumes: Plan 1 engine.
- Produces: a written report answering, with code references into `third_party/llama.cpp`:
  1. Where does weight data enter memory? (which `ggml` backend buffer, which `mmap` calls in `llama-model-loader`)
  2. On a model larger than RAM, what actually happens today on Android? (throttle? OOM kill? Measure with a large GGUF on emulator/device.)
  3. Can a custom `ggml_gallocr` / backend buffer type intercept weight loads per-layer, or is the hook at `llama_model` load time?
  4. MoE models: where are expert tensors grouped per layer? (determines eviction granularity)
  5. Wrap vs fork: is there a hook point reachable without editing llama.cpp sources?

- [ ] **Step 1:** Build Plan 1 engine with a >RAM GGUF (e.g. a 17GB Qwen3-30B-A3B Q4 on a 4GB-configured emulator won't fit — that's the point) and record actual behavior: logcat, /proc/meminfo, tokens/sec.
- [ ] **Step 2:** Read `llama-model-loader.cpp`, `ggml-backend.cpp`, `ggml/src/ggml-mmap` paths; identify the load path for layer weights and write finding (1), (3), (4).
- [ ] **Step 3:** Prototype ONE minimal intervention (e.g. `madvise(MADV_DONTNEED)` after each layer in the graph execution, or a custom buffer type) enough to prove the hook point works. Measure tokens/sec before/after on the smoke model.
- [ ] **Step 4:** Write the spike report answering (1)–(5) with a recommendation: wrap or fork, and where the paging loop lives.
- [ ] **Step 5:** Commit report: `git commit -m "docs: llama.cpp residency spike findings"`

**STOP AFTER THIS TASK. Revise Tasks 2–5 below from the spike findings before executing them — the real paging design depends on what the spike proves.**

---

### Task 2: Residency-managed weight buffer (post-spike: exact hook from Task 1 findings)

**Files:**
- Create or Modify: paging implementation per spike recommendation (expected: `android/app/src/main/cpp/lemon_pager.cpp` + one hook file in the vendored tree)
- Modify: `android/app/src/main/cpp/lemon_bridge.cpp` (expose `lemon_set_mem_budget(int64_t bytes)`, `lemon_get_resident_bytes(int64_t handle)`)
- Test: `test/lemon_engine_test.dart` (new cases)

**Interfaces:**
- Consumes: spike-chosen hook point; Plan 1 `LemonNativeApi`.
- Produces: `LemonNativeApi` gains `void setMemBudget(int handle, int bytes); int residentBytes(int handle);` — mirrored in `LemonEngine` as `setMemoryBudget(int bytes)` and `residentBytes`.

- [ ] **Step 1:** Write failing Dart tests: budget below active-layer size → `load` throws `EngineLoadException('model active layers exceed memory budget')`; `residentBytes` stays under budget throughout a generation (poll from a token callback).
- [ ] **Step 2:** Run: `flutter test test/lemon_engine_test.dart` — expect FAIL (methods missing).
- [ ] **Step 3:** Implement the pager per spike design: pin active layer, prefetch next layer during current compute, evict after last use (refcount guard).
- [ ] **Step 4:** Run: `flutter test test/lemon_engine_test.dart` — expect PASS.
- [ ] **Step 5:** Verify bit-exact output vs Plan 1 on smoke model (same greedy prompt, identical tokens) — compare in a test harness run on device.
- [ ] **Step 6:** Commit: `git commit -m "feat: residency-managed weight pager with memory budget"`

---

### Task 3: A/B benchmark harness (pager on vs off)

**Files:**
- Create: `android/app/src/main/cpp/bench_main.cpp` (standalone NDK executable, run via `adb shell`)
- Create: `docs/benchmarks/README.md` (records results)

**Interfaces:**
- Consumes: pager from Task 2.
- Produces: measured tok/s for {pager off, pager on} × {stories260K, one mid-size GGUF ~2–3GB} on emulator + any real device available.

- [ ] **Step 1:** Build bench executable in CMake (guard behind `LEMON_BUILD_BENCH` option so app builds don't include it).
- [ ] **Step 2:** Run via adb on x86_64 emulator and any arm64 device; record tok/s and peak RSS in `docs/benchmarks/README.md`.
- [ ] **Step 3:** Assert in README: models that fit in RAM show ≤5% regression with pager off-path (Review Focus #3); oversize model completes with pager on instead of crashing.
- [ ] **Step 4:** Commit: `git commit -m "feat: paging A/B benchmark harness and first results"`

---

### Task 4: Model integrity and safe reload

**Files:**
- Modify: `lib/core/local_engine/model_locator.dart` (add sha256 validation at load)
- Modify: `lib/core/local_engine/lemon_engine.dart` (expose reload path)
- Test: `test/model_locator_test.dart` (new cases)

**Interfaces:**
- Produces: `Future<String> locateModel(String source, {String? expectedSha256})` — existing signature gains optional checksum; mismatch throws `EngineLoadException('model file checksum mismatch')`.

- [ ] **Step 1:** Failing tests: matching checksum passes; tampered file throws `EngineLoadException`.
- [ ] **Step 2:** Run — expect FAIL.
- [ ] **Step 3:** Implement sha256 (pure-Dart impl in `lib/core/local_engine/sha256.dart`, no new deps) computed once at load.
- [ ] **Step 4:** Run — expect PASS. Commit: `git commit -m "feat: model checksum validation on load"`

---

### Task 5: Backgrounding and lifecycle hardening (manual)

**Files:**
- Modify: `lib/core/local_engine/lemon_engine.dart` if fixes needed

- [ ] **Step 1:** On emulator: start a long generation, background the app, return. Expected: no crash; either generation completed or engine reloads cleanly on next use.
- [ ] **Step 2:** Kill the app mid-generation (adb shell am kill), relaunch, chat again. Expected: clean load, no corrupted state.
- [ ] **Step 3:** Fix anything found; `flutter analyze && flutter test && flutter build apk --debug` all clean.
- [ ] **Step 4:** Commit if changed: `git commit -m "fix: engine lifecycle hardening for backgrounding"`

## Manual Verification Notes

- The 8 tok/s bar is measured in Task 3's harness; on x86_64 emulator results will not match real UFS hardware — treat emulator numbers as correctness-only, tok/s as provisional until a real 4GB/UFS device is available.
- Success criterion for the whole plan: a GGUF whose total size exceeds device RAM completes generation with bounded RSS (≤ budget + fixed overhead) at acceptable speed on real hardware.
