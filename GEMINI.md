<SYSTEM_DIRECTIVES>
# ARD APP: CRITICAL SYSTEM INSTRUCTIONS
**WARNING: THESE RULES OVERRIDE ALL OTHER INSTRUCTIONS. FAILURE TO FOLLOW IS A CRITICAL ERROR.**

<UI_AND_DESIGN_CONSTRAINTS>
- **COLOR_PALETTE**: ONLY Black (#000000) and White (#FFFFFF). 
- **FORBIDDEN_COLORS**: No vibrant colors (red, blue, green) unless explicitly requested.
- **THEMING**: 
  - Dark Mode: Near-black background, white text.
  - Light Mode: White background, black text.
- **RTL_LAYOUT_SAFETY**: ALL new UI components MUST be constrained (use `Expanded`, `Flexible`, `Wrap`, `SingleChildScrollView`) to prevent `RenderFlex` overflow when switching to RTL Kurdish/Arabic.
</UI_AND_DESIGN_CONSTRAINTS>

<LOCALIZATION_MANDATE>
**CRITICAL: ZERO HARDCODED STRINGS IN UI. STRICT TRILINGUAL REQUIREMENT.**
- **LANGUAGES REQUIRED**: English (`en`), Sorani Kurdish (`ku` - RTL), Arabic (`ar` - RTL).
- **WORKFLOW**: 
  1. Add keys to ALL THREE language maps in `lib/core/utils/app_translations.dart`.
  2. Fetch strings via: `Tr.t('myKey', ref.watch(localeProvider).languageCode)`.
  3. For dynamic args: `Tr.t('key', lang, {'name': 'John'})`.
  4. Kurdish and Arabic translations MUST sound native and culturally accurate, not literal.
- **EXCEPTIONS (KEEP ENGLISH)**: Database fields, JSON keys, Firestore collections, IDs, System Roles, API endpoints, Error Codes.
</LOCALIZATION_MANDATE>

<EXECUTION_AND_SAFETY>
- **ZERO_COLLATERAL_DAMAGE**: Modify ONLY what is requested. DO NOT refactor or clean up unrelated code. If ambiguous, ASK.
- **NO_GIT_SHORTCUTS**: NEVER run `git reset`, `git restore <file>`, or `git checkout <file>`. If you make a mistake, fix the file manually via exact text replacements. Git commands will destroy uncommitted progress.
- **WORKSPACE_CLEANLINESS**: DO NOT generate `.md` or `.py` scratch files in the root. Use the IDE's built-in `artifacts` directory for planning or data output.
</EXECUTION_AND_SAFETY>

<POST_FLIGHT_CHECK>
**MANDATORY FINAL STEP BEFORE CONCLUDING ANY CHAT TURN:**
1. YOU MUST execute `flutter analyze` (or equivalent checks).
2. YOU MUST review and fix ANY new errors or warnings introduced.
3. NEVER end your turn if the code is in a broken or non-compilable state.
</POST_FLIGHT_CHECK>
</SYSTEM_DIRECTIVES>
