# Gemini Rules

---

## 🎨 Color Palette Rule
**Prioritize black and white** as the primary color scheme for all UI elements:
- Use **black** (`#000000` or near-black shades) and **white** (`#FFFFFF` or near-white shades) as the dominant colors.
- Accent colors (if needed) should be minimal, muted, and complementary to a monochromatic palette.
- Avoid using vibrant or saturated colors unless explicitly requested by the user.
- Dark mode should use near-black backgrounds with white/light text; light mode should use white/near-white backgrounds with black/dark text.

---

## ✅ Pre-Finish Error Check Rule
**Before ending every chat response**, the agent MUST:
1. Run `flutter analyze` on the project (or check for Dart/Flutter errors via available tools).
2. Review any errors or warnings surfaced.
3. Fix critical errors (if any were introduced during the session) before concluding.
4. If no changes were made, a quick analysis check is still recommended.

> This ensures the project remains in a compilable, error-free state after every interaction.

---

# App Localization & Trilingual Support Guidelines

## Primary Rule
**EVERY** new UI text element, error message, label, or notification added to this app MUST support exactly three languages:
1. **English** (`en`)
2. **Sorani Kurdish** (`ku`) - Right-to-Left (RTL)
3. **Arabic** (`ar`) - Right-to-Left (RTL)

**Never** hardcode user-facing strings directly in the Dart UI code (e.g., `Text('Hello World')`).

### ⚠️ Exceptions (Backend & System Requirements)
DO NOT translate the following items. They MUST remain in English (or standard formats) to prevent backend failures, database errors, or system crashes:
- **Database Keys/Fields**: JSON keys, Firestore collection/document names, and field names (e.g., `status: 'pending'`).
- **Identifiers & Logic**: User IDs, roles (`admin`, `user`), or backend status codes.
- **Numbers & Math**: System numbers, IDs, and unformatted raw numeric data sent to the backend. (You may format numbers for the UI, but the underlying data must be standard English/Arabic numerals).
- **Technical/System Info**: Error codes, URLs, API endpoints, and system logs.

### 🌐 Translation Quality Rule
When translating into **Sorani Kurdish** or **Arabic**, DO NOT use literal, word-for-word machine translations. Instead, find the culturally and contextually accurate word or phrase that natively represents the concept in that language. It must sound natural to a native speaker.

Whenever you need to add or modify a string in the UI, follow these steps:

### 1. Add the Translation Keys
Open `lib/core/utils/app_translations.dart` and locate the `_strings` map. You must add your new key-value pair to **ALL THREE** language sections:

```dart
// Under 'en':
'myNewFeature': 'My New Feature',

// Under 'ku':
'myNewFeature': 'تایبەتمەندی نوێم',

// Under 'ar':
'myNewFeature': 'ميزتي الجديدة',
```

### 2. Retrieve the Language Code in the UI
In your widget's `build` method, watch the locale provider to get the current language code:
```dart
final lang = ref.watch(localeProvider).languageCode;
```

### 3. Use the `Tr.t()` Helper
Retrieve the translated string using the `Tr.t()` helper method, passing your translation key and the language code:
```dart
Text(Tr.t('myNewFeature', lang))
```

### 4. Handling Dynamic Variables
If your string requires dynamic data, use curly braces `{}` in the translation key and pass the `args` map to `Tr.t()`:

**In `app_translations.dart`:**
```dart
'en': { 'welcomeMsg': 'Welcome, {name}!' },
'ku': { 'welcomeMsg': 'بەخێربێیت، {name}!' },
'ar': { 'welcomeMsg': 'مرحباً بك، {name}!' },
```

**In your UI Widget:**
```dart
Text(Tr.t('welcomeMsg', lang, {'name': 'John'}))
```

## Checklist for AI Agents
- [ ] Did you hardcode any strings in the UI? If yes, move them to `app_translations.dart`.
- [ ] Did you add the key to the `en` dictionary?
- [ ] Did you add the exact same key to the `ku` dictionary?
- [ ] Did you add the exact same key to the `ar` dictionary?
- [ ] Did you verify that RTL layouts support the Kurdish and Arabic text properly using `Directionality.of(context)` where applicable?
- [ ] Did you follow the **black & white color priority** rule for any new UI?
- [ ] Did you run a **project error check** (`flutter analyze`) before finishing?

---

# Agent Core Directives & Guardrails

As an AI Agent operating in this workspace, I am bound by the following strict operational rules:

## 1. Absolute Scope Containment
- **Zero Collateral Edits:** I will only modify the specific files, variables, or functions explicitly targeted by the user's prompt. I will not arbitrarily clean up, lint, or refactor unrelated code.
- **No Scope Creep:** If fulfilling a request requires changing systems outside the initial scope, I will halt execution and ask the user for explicit permission before proceeding.
- **No Assumptions:** I will never guess the user's intent regarding unstated features or hidden dependencies. If something is ambiguous, I will ask for clarification.

## 2. Access & Edit Permissions
- **Context is Read-Only:** I have full read access to explore the codebase for context, but reading a file does not grant me permission to edit it.
- **Explicit Authorization:** I am only authorized to modify files that are directly necessary to complete the stated objective.

## 3. Pre-Flight Checks & Safety
- **State Verification:** Before implementing new features, I will verify the integrity of the relevant codebase to ensure no previous syntax errors or broken states exist.
- **Prioritize Fixes:** If I detect broken code or unintended formatting drift caused by prior edits, I will fix those issues *before* writing new logic.
- **Intent Declaration:** I will explicitly document the files I am modifying to ensure scope alignment, but I do not require explicit human approval to proceed with execution unless requested.
- **Never Use Git to Undo Mistakes:** I will NEVER run `git checkout <file>`, `git restore <file>`, or `git reset` to revert a file to an older state if I make a mistake. Because the workspace often contains extensive uncommitted work, running these commands destructively wipes out all recent progress. If I accidentally break a file, I must fix it manually line-by-line using precise text replacements instead of taking Git shortcuts.

## 4. Post-Flight Verification
- **Test Before Completion:** I will always run `flutter analyze` (or the equivalent build/test commands) to prove my code is error-free before concluding my turn.
- **Format Preservation:** I will respect the existing structural formatting and indentation of the codebase, ensuring my edits blend seamlessly without triggering massive diffs.
- **Strict UI Overflow Prevention (Multi-Lingual Safe):** After adding or modifying any UI component, I will proactively ensure that the widget is robustly constrained (using `Expanded`, `Flexible`, `SingleChildScrollView`, or `Wrap`) to guarantee zero pixel overflow (RenderFlex errors) across all supported languages. I will explicitly account for string length variations and RTL (Right-to-Left) directionality for Kurdish and Arabic.

## 5. Artifacts and Workspace Cleanliness
- **No Loose Files:** I will never generate random scratch scripts, output logs, or ad-hoc documentation files (like `.md` or `.py` files) directly in the root of the project workspace. 
- **Use the Artifact System:** If I need to present data, maps, plans, or documentation to the user, I will use the IDE's built-in `artifacts` directory via my tool integrations, ensuring the user's codebase stays clean.
