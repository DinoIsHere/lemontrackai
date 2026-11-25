# Capability Check + Model Catalog + Download Pipeline Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** The app scans the device, matches it against a curated model catalog, shows honest size/speed disclosures, downloads and verifies the chosen model, and manages installed models.

**Architecture:** A pure-Dart capability module reads `/proc/meminfo`, `Build.SUPPORTED_ABIS`, and storage stats via platform channel, producing a `DeviceProfile`. A versioned catalog (bundled JSON asset, remote-refreshable later) lists curated models with size, quant, tier (flagship MoE / mid MoE / small MoE / small dense), min-RAM and min-storage requirements. A matcher picks compatible models; a downloader with progress, pause/resume, checksum, and Wi-Fi guidance lands the file; a model manager lists/deletes installed models. Spec decisions to honor: floor = 4GB RAM + UFS; usability bar ~8 tok/s; downloads several GB OK **but** user must see size, expected speed, and Wi-Fi recommendation first.

**Tech Stack:** Dart + existing Riverpod patterns; `dio` (already a dependency) for downloads; platform channel for device stats; no new packages.

**Spec:** `docs/superpowers/specs/2026-11-25-local-inference-engine-design.md`

## Global Constraints

- Catalog is a bundled JSON asset (`assets/catalog/models.json`) with a `schemaVersion` field; unknown fields are ignored on read (forward compatible).
- All tok/s numbers in the catalog come from measured benchmark data (Plan 2 Task 3 harness), never guesses; emulator-measured values are marked `"provisional": true` and displayed as such.
- Download target directory: app-private documents dir (`getApplicationDocumentsDirectory()/models/`), same location Plan 1's `model_locator` already uses.
- No model downloads begin without explicit user confirmation showing size + speed estimate + Wi-Fi note.
- Follow existing Riverpod StateNotifier patterns.

## Review Focus

1. **Device below floor** (e.g. 2GB RAM) — UI states unsupported clearly with reason, never offers a download that cannot work. Pinned by Task 2 matcher test + Task 5 UI rule test.
2. **Network drops mid-download** — resume or clean retry, never a half-written file treated as valid. Pinned by Task 3 partial-download test.
3. **Corrupted/checksum-mismatched file** — detected, file deleted, clear error; never handed to the engine. Pinned by Task 3 test.
4. **Insufficient storage at download time** — pre-flight check; user told exactly how much more is needed. Pinned by Task 3 test.
5. **Catalog JSON malformed/missing fields** — app renders with empty catalog + error surface rather than crash. Pinned by Task 1 catalog-parser test.

---

### Task 1: Model catalog model + parser (TDD)

**Files:**
- Create: `lib/features/models/domain/device_profile.dart`
- Create: `lib/features/models/domain/model_catalog.dart` (catalog + entries)
- Create: `lib/features/models/data/catalog_loader.dart`
- Create: `assets/catalog/models.json` (seed with candidate list from spec discussion: Qwen3-30B-A3B Q4 ~17GB flagship / DeepSeek-V2-Lite Q4 ~9GB mid / OLMoE-1B-7B Q4 ~4GB small MoE / Qwen2.5-3B-Instruct Q4 ~1.8GB small dense — **final names/tok/s pending Plan 2 benchmarks; mark all `"provisional": true`**)
- Test: `test/model_catalog_test.dart`

**Interfaces:**
- Produces:
  - `class DeviceProfile { final int totalRamMb; final bool isUfs; final int freeStorageMb; final List<String> abis; }`
  - `class CatalogEntry { final String id; final String displayName; final int totalParamsB; final int activeParamsB; final int sizeBytes; final int minRamMb; final int minStorageMb; final double? measuredTokPerSec; final bool provisional; final String downloadUrl; final String sha256; final int ramBytes; }`
  - `Catalog loadCatalogFromJson(String jsonString)` — throws `CatalogException` on malformed JSON (Review Focus #5).

- [ ] **Step 1:** Failing tests: valid JSON → entries parsed with exact field values; missing required field → `CatalogException`; unknown extra field ignored.
- [ ] **Step 2:** Run: `flutter test test/model_catalog_test.dart` — expect FAIL.
- [ ] **Step 3:** Implement the three Dart files + seed JSON.
- [ ] **Step 4:** Run — PASS. Commit: `git commit -m "feat: model catalog domain and parser with seed catalog"`

---

### Task 2: Device capability scan + matcher (TDD)

**Files:**
- Create: `android/app/src/main/kotlin/.../DeviceStatsPlugin.kt` (platform channel: total RAM from `ActivityManager.MemoryInfo`, storage from `StatFs`, UFS heuristic via `Build.SUPPORTED_ABIS` + `/sys/block` naming — spike-light: record heuristic in code comment, refine on real device)
- Create: `lib/features/models/data/device_scanner.dart` (channel client)
- Create: `lib/features/models/domain/model_matcher.dart`
- Modify: `lib/providers/` (new `device_profile_provider.dart`)
- Test: `test/model_matcher_test.dart`

**Interfaces:**
- Consumes: Task 1 domain.
- Produces:
  - `Future<DeviceProfile> scanDevice()` (MethodChannel `lemon/device_stats`)
  - `List<CatalogEntry> matchModels(DeviceProfile profile, Catalog catalog)` — entries where `totalRamMb*1MB >= minRamMb && freeStorageMb*1MB >= minStorageMb && abis overlap`, sorted by activeParamsB descending. Below floor (4GB RAM or non-UFS-flag) → still returns small-dense tier if it fits; entries whose measured speed can't meet the 8 tok/s bar get `provisional` speed surfaced, never hidden.

- [ ] **Step 1:** Failing matcher tests with synthetic profiles: 4GB+UFS device → flagship + mid + small all match; 2GB device → only small dense matches; 6GB device → all match sorted flagship-first; ABI mismatch → excluded.
- [ ] **Step 2:** Run — FAIL. Step 3: implement. Step 4: Run — PASS.
- [ ] **Step 5:** Commit: `git commit -m "feat: device capability scan and model matcher"`

---

### Task 3: Downloader with integrity and storage pre-flight (TDD)

**Files:**
- Create: `lib/features/models/data/model_downloader.dart`
- Modify: `lib/core/local_engine/model_locator.dart` (accept installed-models dir)
- Test: `test/model_downloader_test.dart`

**Interfaces:**
- Consumes: `CatalogEntry.downloadUrl`/`sha256`/`sizeBytes`.
- Produces:
  - `Stream<DownloadEvent> download(CatalogEntry entry, {required String destinationPath})` — events: `progress(received, total)`, `completed(path)`, `failed(reason)`.
  - Pre-flight before any byte: free storage < `sizeBytes * 1.1` → immediate `failed('insufficient storage: need X more MB')` (Review Focus #4).
  - Partial file written to `.part` suffix; renamed only after checksum passes; checksum mismatch → delete file, `failed('checksum mismatch')` (Review Focus #2/#3).

- [ ] **Step 1:** Failing tests using a local `HttpServer` fixture: completes and renames after valid checksum; mismatch deletes file; storage pre-flight fails fast with exact message; resume after connection drop continues from `.part` (dio supports range headers — assert range request sent).
- [ ] **Step 2:** Run — FAIL. Step 3: implement. Step 4: Run — PASS.
- [ ] **Step 5:** Commit: `git commit -m "feat: resumable model downloader with checksum and storage pre-flight"`

---

### Task 4: Model manager (list/switch/delete, TDD)

**Files:**
- Create: `lib/features/models/data/model_manager.dart`
- Create: `lib/providers/model_manager_provider.dart`
- Modify: `lib/providers/ai_engine_provider.dart` (installed models registry persisted under key `installed_models`)
- Test: `test/model_manager_test.dart`

**Interfaces:**
- Produces: `Future<List<InstalledModel>> listInstalled()`, `Future<void> delete(String id)`, `Future<void> setActive(String id)`; `InstalledModel { id, displayName, path, sizeBytes, installedAt }`. Deleting the active model clears the active pointer (engine falls back to not-loaded state, existing error path from Plan 1 handles it).

- [ ] **Step 1:** Failing tests: register/list/delete round-trip; delete active clears pointer; deleting nonexistent throws `StateError`.
- [ ] **Step 2:** Run — FAIL. Step 3: implement. Step 4: Run — PASS.
- [ ] **Step 5:** Commit: `git commit -m "feat: installed model manager with registry persistence"`

---

### Task 5: Models screen UI + honest disclosure

**Files:**
- Create: `lib/features/models/presentation/models_screen.dart`
- Modify: `lib/features/settings/presentation/settings_screen.dart` (add "AI Models" entry)
- Modify: `lib/features/settings/presentation/ai_engine_screen.dart` (replace free-text model path field from Plan 1 with installed-model picker; keep free-text as advanced fallback)
- Test: `test/models_screen_test.dart` (widget tests)

**Interfaces:**
- Consumes: Tasks 1–4 providers.
- Produces: Models screen with: device profile card (RAM/storage/verdict); compatible models list with size, download button; **disclosure dialog before any download showing file size, expected tok/s (marked "estimate" when provisional), and "use Wi-Fi" advice — no download starts until confirmed** (spec requirement); installed models section with set-active and delete.

- [ ] **Step 1:** Widget tests: unsupported device shows unsupported verdict and no download buttons; disclosure dialog appears before download starts; installed list renders with delete buttons.
- [ ] **Step 2:** Run — FAIL. Step 3: implement screen. Step 4: Run — PASS.
- [ ] **Step 5:** Full suite + analyze: `flutter analyze && flutter test` — clean. Commit: `git commit -m "feat: models screen with disclosure-driven download flow"`

---

### Task 6: E2E verification (manual, device/emulator)

- [ ] **Step 1:** On emulator: Models screen shows real RAM/storage from channel. Download the smallest catalog entry (or a local-file URL via `adb reverse` pointing at a local HTTP server hosting stories260K — avoids network flake). Verify checksum, set active, chat works end-to-end.
- [ ] **Step 2:** Airplane-mode retry test: kill server mid-download, verify `.part` survives, resume completes.
- [ ] **Step 3:** `flutter analyze && flutter test && flutter build apk --debug` clean. Commit any fixes.

## Manual Verification Notes

- Real-device tok/s display stays provisional until Plan 2 benchmarks run on real UFS hardware; the UI must label them as estimates.
- The 4GB/UFS floor verdict uses whatever heuristic the platform channel exposes; validate the UFS detection on a real device before trusting the UI verdict (add to spike notes when it happens).
