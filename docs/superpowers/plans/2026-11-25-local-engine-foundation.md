# Local Inference Engine Foundation — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** llama.cpp compiled into the Android app via NDK, bridged through Dart FFI, generating streamed tokens into the existing chat UI using the stock engine (no custom layer paging yet).

**Architecture:** A small C bridge (`liblemon_bridge.so`) wraps llama.cpp's C API (init / generate-with-token-callback / stop / free), built by Gradle's `externalNativeBuild`. Dart FFI binds to it behind an injectable interface so the engine layer is unit-testable with fakes. The chat stack gains a new `AiProvider.local` that routes through the engine.

**Tech Stack:** llama.cpp (git submodule), Android NDK + CMake, Dart FFI (`dart:ffi`, no new packages), Flutter/Riverpod (existing).

**Spec:** `docs/superpowers/specs/2026-11-25-local-inference-engine-design.md`

## Global Constraints

- Android only; no iOS targets touched.
- ABIs: `arm64-v8a` and `x86_64` (x86_64 for emulator smoke tests).
- CPU inference only this plan: no GPU/OpenCL/Vulkan flags; `GGML_OPENMP=OFF`, `LLAMA_CURL=OFF`, `GGML_NATIVE=OFF`.
- Engine defaults: `n_ctx = 2048`, `threads = 4`.
- No new Dart/Flutter dependencies (dart:ffi is in the SDK).
- Only bundled model is the ~1MB smoke-test asset `stories260K.gguf`; no large models in the repo.
- Follow existing Riverpod patterns (StateNotifier + providers in `lib/providers/`).
- This plan uses stock llama.cpp behavior; the custom layer-paging scheme is a later plan and must not be pre-built here.

## Review Focus

Inputs and failure modes the spec implies but no test above exercises; each is pinned by a named test below:

1. **Model file missing/moved at load** — user gets a clear error state, not a crash or silent hang. Pinned by: `test/lemon_engine_test.dart` "init failure surfaces error state".
2. **Second generate requested while generating** — engine rejects it (busy), does not interleave tokens. Pinned by: `test/lemon_engine_test.dart` "rejects concurrent generate".
3. **Engine used after dispose** — throws `StateError`, never a use-after-free of native memory. Pinned by: `test/lemon_engine_test.dart` "use after dispose throws".
4. **Empty or blank user message** — no native call made, empty completion returned. Pinned by: `test/chat_template_test.dart` "blank user message yields empty prompt".
5. **History longer than context budget** — oldest messages are trimmed, last user message always kept; never silently truncated mid-conversation garbage. Pinned by: `test/chat_template_test.dart` "trims oldest messages beyond budget".

---

### Task 1: Android toolchain configuration

**Files:**
- Modify: `android/local.properties`
- Modify: `android/gradle.properties`
- Modify: `android/app/build.gradle.kts`

**Interfaces:**
- Produces: a working `flutter build apk --debug`; NDK `30.0.16248370` and CMake `3.31.5` installed; `ndkVersion` pinned so later tasks can compile native code.

- [ ] **Step 1: Install NDK and CMake via sdkmanager**

```bash
export JAVA_HOME="C:/Program Files/Android/Android Studio/jbr"
"C:/Users/L3I7G14R32S1TRTX46TI/AppData/Local/Android/Sdk/cmdline-tools/latest/bin/sdkmanager.bat" "ndk;30.0.16248370" "cmake;3.31.5"
```

Accept licenses when prompted. Verify both directories exist under the SDK root.

- [ ] **Step 2: Point Gradle at the SDK and JBR**

Append to `android/local.properties` (properties file: escape backslashes and colon):

```properties
sdk.dir=C\:\\Users\\L3I7G14R32S1TRTX46TI\\AppData\\Local\\Android\\Sdk
```

Append to `android/gradle.properties` (system Java is 1.8; the build needs 17+):

```properties
org.gradle.java.home=C\:\\Program Files\\Android\\Android Studio\\jbr
```

- [ ] **Step 3: Pin ndkVersion and ABI filters in `android/app/build.gradle.kts`**

Replace `ndkVersion = flutter.ndkVersion` with `ndkVersion = "30.0.16248370"`, and inside `defaultConfig` add:

```kotlin
ndk {
    abiFilters += listOf("arm64-v8a", "x86_64")
}
```

- [ ] **Step 4: Verify baseline build passes**

Run: `flutter build apk --debug`
Expected: `Built build/app/outputs/flutter-apk/app-debug.apk` with no NDK/CMake errors.

- [ ] **Step 5: Commit**

```bash
git add android/local.properties android/gradle.properties android/app/build.gradle.kts
git commit -m "chore: pin Android NDK and CMake toolchain for native engine"
```

---

### Task 2: Vendor llama.cpp as a pinned submodule

**Files:**
- Create: `third_party/llama.cpp` (git submodule)

**Interfaces:**
- Produces: llama.cpp sources at a pinned tag, referenced by path from Task 3's CMakeLists.

- [ ] **Step 1: Add the submodule**

```bash
git submodule add https://github.com/ggml-org/llama.cpp third_party/llama.cpp
```

- [ ] **Step 2: Pin to the latest release tag**

```bash
cd third_party/llama.cpp
git describe --tags --abbrev=0   # note the latest b-tag, e.g. b7xxx
git checkout <that tag>
cd ../..
git add third_party/llama.cpp
```

Record the chosen tag in the commit message.

- [ ] **Step 3: Verify**

Run: `git submodule status`
Expected: one entry for `third_party/llama.cpp`, no leading `-` (checked out).

- [ ] **Step 4: Commit**

```bash
git commit -m "chore: vendor llama.cpp at <tag> for local inference engine"
```

---

### Task 3: C bridge and CMake wiring

**Files:**
- Create: `android/app/src/main/cpp/CMakeLists.txt`
- Create: `android/app/src/main/cpp/lemon_bridge.cpp`
- Modify: `android/app/build.gradle.kts`

**Interfaces:**
- Consumes: llama.cpp C API from `third_party/llama.cpp` (Task 2).
- Produces: `libliblemon_bridge.so` exporting exactly these symbols (Task 4's FFI layer binds to them):
  - `int64_t lemon_init(const char* model_path, int32_t n_ctx, int32_t n_threads)` — returns handle, or `-1` on failure; logs the failure reason via `__android_log_print`.
  - `int32_t lemon_generate(int64_t handle, const char* prompt, void* user_data, void (*on_token)(void* user_data, const char* token))` — runs generation, calls `on_token` per token, returns `0` on completion; generation loop checks an internal stop flag set by `lemon_stop`.
  - `void lemon_stop(int64_t handle)` — sets the stop flag so `lemon_generate` returns early.
  - `void lemon_free(int64_t handle)` — frees context, model, and any buffers; safe to call with `-1`.

- [ ] **Step 1: Write `android/app/src/main/cpp/CMakeLists.txt`**

```cmake
cmake_minimum_required(VERSION 3.22)
project(lemon_bridge LANGUAGES C CXX)

set(LLAMA_BUILD_EXAMPLES OFF CACHE BOOL "" FORCE)
set(LLAMA_BUILD_TESTS OFF CACHE BOOL "" FORCE)
set(LLAMA_BUILD_SERVER OFF CACHE BOOL "" FORCE)
set(LLAMA_CURL OFF CACHE BOOL "" FORCE)
set(GGML_OPENMP OFF CACHE BOOL "" FORCE)
set(GGML_NATIVE OFF CACHE BOOL "" FORCE)

add_subdirectory(${CMAKE_CURRENT_SOURCE_DIR}/../../../../third_party/llama.cpp llama_build)

add_library(lemon_bridge SHARED lemon_bridge.cpp)
target_link_libraries(lemon_bridge PRIVATE llama log)
```

- [ ] **Step 2: Write `lemon_bridge.cpp` implementing the four symbols above**

Use llama.h (`#include "llama.h"`). `lemon_init` creates `llama_model`, `llama_context`, stores both plus an `std::atomic<bool> stop` in a heap struct; `lemon_generate` tokenizes the prompt, runs `llama_decode` + `llama_sampler` chain (greedy: `llama_sampler_init_greedy`) in a loop, converts sampled tokens with `llama_token_to_piece`, invokes the callback, and honors the stop flag and EOG token.

- [ ] **Step 3: Add externalNativeBuild to `android/app/build.gradle.kts`**

Inside the `android { }` block:

```kotlin
externalNativeBuild {
    cmake {
        path = file("src/main/cpp/CMakeLists.txt")
        version = "3.31.5"
    }
}
```

- [ ] **Step 4: Build and verify the .so is produced**

Run: `flutter build apk --debug`
Then: `unzip -l build/app/outputs/flutter-apk/app-debug.apk | grep liblemon_bridge`
Expected: `lib/arm64-v8a/liblemon_bridge.so` and `lib/x86_64/liblemon_bridge.so` listed.

- [ ] **Step 5: Commit**

```bash
git add android/app/src/main/cpp android/app/build.gradle.kts
git commit -m "feat: add llama.cpp C bridge (init/generate/stop/free) with CMake build"
```

---

### Task 4: Dart FFI engine layer (TDD with injectable native API)

**Files:**
- Create: `lib/core/local_engine/lemon_native_api.dart`
- Create: `lib/core/local_engine/lemon_engine.dart`
- Create: `lib/core/local_engine/chat_template.dart`
- Create: `lib/providers/local_engine_provider.dart`
- Test: `test/chat_template_test.dart`
- Test: `test/lemon_engine_test.dart`

**Interfaces:**
- Consumes: `liblemon_bridge.so` symbols from Task 3.
- Produces (used by Task 5):
  - `abstract class LemonNativeApi { int init(String modelPath, int nCtx, int nThreads); int generate(int handle, String prompt, void Function(String token) onToken); void stop(int handle); void free(int handle); }`
  - `class FfiLemonApi implements LemonNativeApi` — dart:ffi implementation opening `liblemon_bridge.so`.
  - `class LemonEngine { LemonEngine({required LemonNativeApi api}); Future<void> load(String modelPath); Stream<String> generate(String prompt); void stop(); void dispose(); bool get isReady; }`
  - `String buildChatPrompt(List<({String role, String content})> messages, {int budgetChars = 6000})` — ChatML format, trims oldest messages past budget, keeps last user message.
  - `final localEngineProvider = Provider<LemonEngine>((ref) => LemonEngine(api: FfiLemonApi())..onDispose(ref.onDispose));` — one app-wide instance.

- [ ] **Step 1: Write failing tests in `test/chat_template_test.dart`**

```dart
test('formats ChatML with system prompt', () {
  final p = buildChatPrompt([('user', 'hi')]);
  expect(p, contains('<|im_start|>user\nhi<|im_end|>'));
  expect(p, endsWith('<|im_start|>assistant\n'));
});
test('blank user message yields empty prompt', () {
  expect(buildChatPrompt([('user', '   ')]), '');
});
test('trims oldest messages beyond budget, keeps last user message', () {
  final msgs = List.generate(50, (i) => ('user', 'message $i with padding' * 20));
  final p = buildChatPrompt([...msgs, ('user', 'final question')], budgetChars: 6000);
  expect(p.length, lessThan(6600));
  expect(p, contains('final question'));
  expect(p, isNot(contains('message 0 with padding')));
});
```

- [ ] **Step 2: Write failing tests in `test/lemon_engine_test.dart`** using a `FakeLemonApi implements LemonNativeApi` (records calls; `generate` emits a fixed token list through the callback; configurable failure mode):

```dart
test('load then generate emits tokens in order', () async {
  final engine = LemonEngine(api: fake);
  await engine.load('model.gguf');
  expect(engine.isReady, isTrue);
  final tokens = await engine.generate('p').toList();
  expect(tokens, ['Hello', ' world']);
});
test('init failure surfaces error state', () async {
  final engine = LemonEngine(api: FakeLemonApi(failInit: true));
  await expectLater(engine.load('nope.gguf'), throwsA(isA<EngineLoadException>()));
  expect(engine.isReady, isFalse);
});
test('rejects concurrent generate', () async {
  final engine = LemonEngine(api: fake);
  await engine.load('model.gguf');
  final first = engine.generate('p').toList();
  expect(() => engine.generate('p2'), throwsA(isA<StateError>()));
  engine.stop();
  await first;
});
test('use after dispose throws', () async {
  final engine = LemonEngine(api: fake);
  await engine.load('model.gguf');
  engine.dispose();
  expect(() => engine.generate('p'), throwsA(isA<StateError>()));
});
```

- [ ] **Step 3: Run tests to verify they fail**

Run: `flutter test test/chat_template_test.dart test/lemon_engine_test.dart`
Expected: FAIL — files/classes not found.

- [ ] **Step 4: Implement the four files**

- `lemon_native_api.dart`: the abstract class + `FfiLemonApi` using `DynamicLibrary.open('liblemon_bridge.so')`, native typedefs matching Task 3's exported symbols (callback via `NativeCallable` so Dart receives tokens).
- `chat_template.dart`: `buildChatPrompt` per its test contract.
- `lemon_engine.dart`: `LemonEngine` and `EngineLoadException`. `generate` guards: not ready → `StateError`, already generating → `StateError`, disposed → `StateError`; streams tokens from the native callback via a `StreamController` (non-broadcast, single subscriber); `stop()` calls `lemon_stop`; `dispose()` frees the native handle exactly once (guard with a bool).
- `local_engine_provider.dart`: `localEngineProvider` per its contract, plus `ref.onDispose(engine.dispose)`.

- [ ] **Step 5: Run tests to verify they pass**

Run: `flutter test test/chat_template_test.dart test/lemon_engine_test.dart`
Expected: PASS, all tests.

- [ ] **Step 6: Commit**

```bash
git add lib/core/local_engine lib/providers/local_engine_provider.dart test
git commit -m "feat: Dart FFI engine layer with injectable native API and prompt builder"
```

---

### Task 5: Wire the local provider into chat and settings

**Files:**
- Modify: `lib/providers/ai_engine_provider.dart` (add `AiProvider.local`, `localModelPath` field + copyWith + persistence)
- Modify: `lib/features/chat/data/ai_chat_service.dart` (exhaustive switch: add local case)
- Modify: `lib/features/chat/data/local/chat_repository_local.dart` (pass engine to service)
- Modify: `lib/features/settings/presentation/ai_engine_screen.dart` (provider option + model path field)

**Interfaces:**
- Consumes: `LemonEngine`, `localEngineProvider`, `buildChatPrompt` from Task 4.
- Produces: `AIChatService(this.config, {LemonEngine? localEngine})`; `AiEngineConfig.localModelPath` (String, default `''`), persisted in SharedPreferences under key `local_model_path` following the existing key pattern.

- [ ] **Step 1: Extend `AiEngineConfig`**

Add `AiProvider.local` to the enum (Dart exhaustive switches will then produce compile errors at every switch site — fix each by adding the case, the compiler is the checklist). Add `localModelPath` field (default `''`) with copyWith support and persistence alongside the existing keys in the provider's load/save logic.

- [ ] **Step 2: Add the local case to `AIChatService`**

Constructor becomes `AIChatService(this.config, {this.localEngine})`. In the switch, `AiProvider.local` → if `localEngine == null || !localEngine!.isReady`, throw `'Local model not loaded. Set it in AI Engine settings.'`; otherwise `buildChatPrompt` from the full history and return the joined tokens of `await for (t in engine.generate(prompt)) buffer.write(t)`.

- [ ] **Step 3: Pass the engine from the repository**

In `LocalChatRepository.sendMessage`, replace `AIChatService(aiConfig)` with `AIChatService(aiConfig, localEngine: ref.read(localEngineProvider))`. If generation fails, the existing catch block already renders `'Error: ...'` — keep that path.

- [ ] **Step 4: Add UI to `ai_engine_screen.dart`**

Follow the screen's existing pattern: add "Local (on-device)" to the provider selector; when selected show a `TextField` bound to a `_localModelPath` controller (hint: full path to a .gguf file, e.g. the bundled-smoke path from the manual verification below), saving to `localModelPath` on change like the other fields.

- [ ] **Step 5: Verify analyze and tests**

Run: `flutter analyze`
Expected: no new errors.
Run: `flutter test`
Expected: PASS (existing suite unchanged).

- [ ] **Step 6: Commit**

```bash
git add lib/providers/ai_engine_provider.dart lib/features/chat lib/features/settings/presentation/ai_engine_screen.dart
git commit -m "feat: add on-device local provider to AI engine and chat stack"
```

---

### Task 6: End-to-end smoke verification

**Files:**
- Create: `assets/models/README.md` (documents the smoke asset — no model in git)
- Modify: `pubspec.yaml` (declare the assets/models/ asset directory)

**Interfaces:**
- Consumes: everything above; produces a verified working local chat.

- [ ] **Step 1: Bundle the tiny smoke model as an asset**

Download once (not committed to git; README records the URL and sha256):

```
https://huggingface.co/ggml-org/models/resolve/main/tinyllamas/stories260K.gguf
```

Place it at `assets/models/stories260K.gguf`, add `assets/models/` to `pubspec.yaml` under `flutter: assets:`, and commit `README.md` + `pubspec.yaml` only (add the .gguf to `.gitignore`).

- [ ] **Step 2: Add asset extraction to the engine path**

On load, if the path points at an asset (`assets/...`), copy it to `getApplicationDocumentsDirectory()` via path_provider (already a dependency) and load from there. Put this helper in `lib/core/local_engine/model_locator.dart` with a unit test in `test/model_locator_test.dart`: asset path → returns a file path; missing asset → throws `EngineLoadException`. Run: `flutter test test/model_locator_test.dart` — expect PASS.

- [ ] **Step 3: Run the full local verification on device or emulator**

Create/launch an emulator (or plug in a device): `flutter emulators`, `flutter emulators --launch <id>`. Then `flutter run`. In AI Engine settings: select **Local (on-device)**, set model path `assets/models/stories260K.gguf`. In chat, send "Tell me a story". Expected: a reply streams in within seconds — generated by the on-device model, no network call (verify with airplane mode on emulator for a hard check).

- [ ] **Step 4: Run the whole verification suite**

```bash
flutter analyze && flutter test && flutter build apk --debug
```
Expected: all clean.

- [ ] **Step 5: Commit**

```bash
git add assets/models/README.md .gitignore pubspec.yaml lib/core/local_engine/model_locator.dart test/model_locator_test.dart
git commit -m "feat: bundle tiny smoke model and asset extraction for local engine"
```

---

## Manual Verification Notes (no automation)

- The emulator smoke test in Task 6 Step 3 is the real E2E proof; automate later via `integration_test` once a CI device farm exists.
- `stories260K.gguf` is a toy story-completion model with no chat training — a coherent-ish story continuation is a pass; a refusal or empty output is a fail (that signals a prompt-template or decode bug, not model quality).
- Benchmarking real curated models (tokens/sec on reference hardware) is explicitly out of scope for this plan; it belongs to the model-selection work in the spec.
