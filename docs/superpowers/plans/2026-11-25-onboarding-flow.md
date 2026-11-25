# First-Boot Onboarding Flow Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A first-boot sequence that welcomes the user, collects their name, scans their device, recommends and downloads a model with honest disclosure, and lands them on a working local chat.

**Architecture:** A `SeenOnboardingNotifier` (Riverpod StateNotifier, persisted via SharedPreferences key `onboarding_complete`) gates routing at app start: not seen → `/onboarding` (a `PageView` wizard), seen → existing `/`. The wizard is step-structured so each stage (welcome → name → device scan → model choice + download → done) is its own widget, skippable where the spec allows. Name plugs into the existing `UserNameNotifier` (`lemon_user_name`). Model selection reuses Plan 3's models stack verbatim — onboarding is a thin guided sequence over it, not a second implementation.

**Tech Stack:** Flutter/Riverpod (existing); no new packages.

**Spec:** `docs/superpowers/specs/2026-11-25-local-inference-engine-design.md`

## Global Constraints

- Onboarding runs exactly once per install; completion flag survives restarts (SharedPreferences).
- **Skip must always be available** — every step except the final "you're set" screen can be skipped; skipping lands on home with the app fully usable (cloud provider or a later model choice from settings). A user who skips is never nagged again this install.
- Name entry reuses `UserNameNotifier.setName` — no second persistence path.
- Download disclosure in onboarding uses the same dialog/rules as Plan 3's Models screen (size + speed estimate + Wi-Fi advice; nothing downloads without explicit confirm).
- Dark theme via existing `AppTheme.dark()` only; match the app's visual language (Aurora/gradient home styling as reference).
- No telemetry or analytics introduced.

## Review Focus

1. **App killed mid-onboarding** (process death on step 3 of 5) — relaunch restarts onboarding at step 1 (flag not yet set); no partial state like a half-downloaded model handed to chat. Pinned by Task 4 test + Task 5 manual check.
2. **Download fails mid-onboarding** (network drop) — user sees failure, can retry or skip; onboarding never traps them. Pinned by Task 4 test.
3. **User skips name entry with blank input** — greeting falls back to existing `'there'` default; no empty-name state. Pinned by Task 3 test.
4. **Second launch after completion** — goes straight to home, never flashes onboarding. Pinned by Task 1 test.
5. **Back button during onboarding** — system back does not skip steps out of order or exit the wizard into a broken half-state; back returns to previous step (or confirms exit on step 1). Pinned by Task 4 widget test.

---

### Task 1: Completion gate + routing (TDD)

**Files:**
- Create: `lib/features/onboarding/providers/onboarding_provider.dart` (`SeenOnboardingNotifier` + `seenOnboardingProvider`, key `onboarding_complete`, methods `complete()`, `reset()` (debug/testing))
- Modify: `lib/app.dart` — check gate before `MaterialApp.routes` resolution: while the flag is loading, show a splash `Scaffold`; when false route to `/onboarding`, when true existing behavior.
- Modify: `lib/main.dart` if provider wiring requires it (it should not — Riverpod scope is enough)
- Test: `test/onboarding_gate_test.dart`

**Interfaces:**
- Produces: `seenOnboardingProvider = StateNotifierProvider<SeenOnboardingNotifier, AsyncValue<bool>>`; `/onboarding` route returning `OnboardingScreen` (defined Task 2).

- [ ] **Step 1:** Failing tests with a mocked SharedPreferences: flag unset → `AsyncValue.data(false)`; `complete()` persists and state flips; second read returns true (Review Focus #4).
- [ ] **Step 2:** Run: `flutter test test/onboarding_gate_test.dart` — FAIL.
- [ ] **Step 3:** Implement notifier + gate in `app.dart` (route table gains `/onboarding`; `initialRoute` decision moved behind the gate).
- [ ] **Step 4:** Run — PASS. Commit: `git commit -m "feat: onboarding completion gate and route"`

---

### Task 2: Onboarding wizard shell + welcome step (TDD)

**Files:**
- Create: `lib/features/onboarding/presentation/onboarding_screen.dart` (PageView shell, step indicator dots, Skip button top-right on all steps, Next/Back bottom)
- Create: `lib/features/onboarding/presentation/steps/welcome_step.dart` (app identity: name, one-line promise "your life, organized by an AI that runs entirely on your phone", feature highlights: goals/assignments/schedule + local AI)
- Test: `test/onboarding_wizard_test.dart`

**Interfaces:**
- Produces: `OnboardingScreen` hosts ordered steps; each step is a widget receiving an `OnboardingController` (plain class exposing `next()`, `skip()`, `finish()`); later steps register themselves in this file's `steps` list.

- [ ] **Step 1:** Widget tests: screen renders welcome step first; Skip is visible; tapping Next advances to step 2 placeholder; tapping Skip leaves the wizard (calls `finish()` without completion — see Task 4 for distinction between skip and finish).
- [ ] **Step 2:** Run — FAIL. Step 3: implement shell + welcome step. Step 4: Run — PASS.
- [ ] **Step 5:** Commit: `git commit -m "feat: onboarding wizard shell and welcome step"`

---

### Task 3: Name step (TDD)

**Files:**
- Create: `lib/features/onboarding/presentation/steps/name_step.dart`
- Test: `test/onboarding_name_step_test.dart`

**Interfaces:**
- Consumes: `UserNameNotifier.setName` (existing, `lib/providers/user_provider.dart`); blank input allowed → falls back to default (Review Focus #3).
- Produces: Name step with a single `TextField`, persistence on Next (not per keystroke).

- [ ] **Step 1:** Widget tests: entering "Aldino" and tapping Next calls `setName('Aldino')`; blank input + Next calls `setName` with empty string or skips the call (either acceptable — assert greeting-provider state falls back to `'there'`).
- [ ] **Step 2:** Run — FAIL. Step 3: implement. Step 4: Run — PASS.
- [ ] **Step 5:** Commit: `git commit -m "feat: onboarding name step wired to user provider"`

---

### Task 4: Device scan + model steps (TDD)

**Files:**
- Create: `lib/features/onboarding/presentation/steps/device_step.dart` (shows scan result: RAM/storage/verdict, reusing Plan 3 `device_profile_provider`)
- Create: `lib/features/onboarding/presentation/steps/model_step.dart` (compatible models from Plan 3 matcher; disclosure dialog identical to Plan 3's; download progress inline; retry on failure; **Skip works even mid-download** — download cancels cleanly via existing cancel path)
- Create: `lib/features/onboarding/presentation/steps/done_step.dart` (final screen, "Start" button → `finish()` sets flag and routes home)
- Modify: `lib/features/onboarding/presentation/onboarding_screen.dart` (register steps in order)
- Test: `test/onboarding_model_step_test.dart`

**Interfaces:**
- Consumes: Plan 3's `scanDevice`, `matchModels`, `download`, `ModelManager`; Plan 1's `localEngineProvider` (post-download load).
- Produces: the complete 5-step wizard (welcome → name → device → model → done).

- [ ] **Step 1:** Widget tests with faked model providers: device step renders verdict; model step shows disclosure before download (Review Focus: no silent downloads); download failure shows retry + skip, never dead-ends (Review Focus #2); done step's Start sets completion flag (asserts provider state).
- [ ] **Step 2:** Run — FAIL. Step 3: implement steps. Step 4: Run — PASS.
- [ ] **Step 5:** Commit: `git commit -m "feat: onboarding device scan, model choice, and done steps"`

---

### Task 5: Lifecycle edge cases + E2E verification (manual)

- [ ] **Step 1:** Kill app mid-onboarding (process death), relaunch → onboarding restarts at step 1, chat not reachable, no orphaned `.part` file breaks anything (Review Focus #1).
- [ ] **Step 2:** Complete onboarding fully, kill app, relaunch → straight to home, no onboarding flash (Review Focus #4).
- [ ] **Step 3:** System back on each step behaves per Review Focus #5; fix `PopScope` handling if needed.
- [ ] **Step 4:** Full clean run on emulator with the tiny model: fresh install → onboarding → name → scan → download → done → home greets by name → local chat responds offline (airplane mode).
- [ ] **Step 5:** `flutter analyze && flutter test && flutter build apk --debug` clean. Commit fixes: `git commit -m "fix: onboarding lifecycle hardening"`

## Manual Verification Notes

- The fresh-install E2E in Task 5 Step 4 is the acceptance run for the whole onboarding feature; record a screen recording if possible for the user to review the flow.
- Copy (exact wording) is left to the implementer following the welcome step sketch; keep it short — the promise line is the one sentence from the spec's intent: "your life, organized by an AI that runs entirely on your phone."
- Skipped-onboarding users (flag never set by skip — they get the wizard again next launch **only if** skip is implemented as abort; the chosen behavior: **skip sets the flag too** — skipping is a decision, not a deferral; reset only via app data clear or debug `reset()`). Adjust Task 1 test if this call is reversed by the user.
