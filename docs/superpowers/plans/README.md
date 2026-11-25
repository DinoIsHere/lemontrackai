# Superpowers Plans — Roadmap & Status

Spec: `docs/superpowers/specs/2026-11-25-local-inference-engine-design.md`

Execute in order. Each plan produces working, testable software on its own.

| # | Plan | File | Status |
|---|------|------|--------|
| 1 | Local engine foundation (stock llama.cpp → FFI → chat) | `2026-11-25-local-engine-foundation.md` | **READY — next up** |
| 2 | Custom layer streaming (active-layer-only RAM residency) | `2026-11-25-layer-streaming.md` | Written; **Task 1 is a spike — revise Tasks 2–5 from its findings before executing them** |
| 3 | Capability check + model catalog + download pipeline | `2026-11-25-capability-and-models.md` | Written; task details may shift slightly after Plan 2 lands |
| 4 | First-boot onboarding flow | `2026-11-25-onboarding-flow.md` | Written; depends on Plan 3's model pipeline |

Notes for a fresh session continuing this work:

- Plans 2–4 were written before Plan 1 was executed. Plan 2's spike (its Task 1)
  exists precisely because llama.cpp internals on-device are the unknown; update
  plan 2 after the spike before executing its remaining tasks.
- Environment facts discovered while planning (Windows machine):
  - SDK at `C:\Users\L3I7G14R32S1TRTX46TI\AppData\Local\Android\Sdk` (NOT yet in
    `android/local.properties` — Plan 1 Task 1 adds it)
  - System Java is 1.8; use Android Studio JBR (`C:\Program Files\Android\Android
    Studio\jbr`) via `org.gradle.java.home` (Plan 1 Task 1 adds this)
  - No emulator AVD exists yet; no device attached as of 2026-11-25
  - Flutter 3.51.0 master channel, Java 17+ required for Gradle
- User decisions to honor: Android-only; device floor 4GB RAM + UFS; ~8 tok/s
  usability bar; multi-GB downloads OK but user must see size/speed/Wi-Fi advice;
  curated models only; full agent deferred to v1.5.
