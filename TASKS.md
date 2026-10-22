# SPRINT 2 ARCHITECTURE: CORE ENGINE & UI/UX REFINEMENT
**Sprint Window:** October 19, 2026 – October 25, 2026  
**Primary Objective:** Zero-crash, pixel-perfect stabilization, ATS template rendering precision, and editor fluidity for Resume Brain.  
**Repository Target:** `VALIXIS/ResumeBrain` (Remote: `https://github.com/VALIXIS/ResumeBrain.git`)  
**Assigned Engineers:** Vignesh, Krishna, Adithya  

---

## 📅 Daily Sprint Tickets (Resume Brain Track)

### 🔹 Vignesh (Editor UX, Form State & AI Failover Track)
- **Day 1 (Oct 19) | [RSM-REF-01] Live Editor Form State & Focus Retention**
  - **Branch:** `feature/vignesh-resume-editor-focus-fix` | **Priority:** Critical
  - **Scope:** Retain focus and cursor position in `live_resume_editor_screen.dart` during state rebuilds; debounce auto-save to Hive (800ms) to eliminate typing lag.
  - **DOD:** Smooth typing experience with no lost focus or jumping cursor during live edits.

- **Day 2 (Oct 20) | [RSM-REF-02] Section Drag-and-Drop Reorder Stability**
  - **Branch:** `feature/vignesh-resume-section-reorder-fix` | **Priority:** High
  - **Scope:** Fix index re-calculation in `ReorderableListView` in `reorderable_section_card.dart`. Ensure custom sections maintain user-ordered position across launches.
  - **DOD:** Sections reorder smoothly with haptic feedback and persist order reliably.

- **Day 3 (Oct 21) | [RSM-REF-03] AI Prompt Engine & Failover Hardening**
  - **Branch:** `feature/vignesh-resume-ai-failover-hardening` | **Priority:** Critical
  - **Scope:** Implement exponential backoff and instant fallback from Groq to Gemini in `hybrid_ai_provider.dart` when HTTP 429 or 503 is returned. Ensure valid JSON parsing.
  - **DOD:** Seamless AI failover with 100% valid parsed responses even under high API load.

- **Day 4 (Oct 22) | [RSM-REF-04] Bullet Point Enhancer UI Diff Comparison**
  - **Branch:** `feature/vignesh-resume-bullet-diff-ui` | **Priority:** High
  - **Scope:** Clean visual diff card highlighting added metrics and action verbs. Provide Accept, Edit, and Discard buttons with undo support.
  - **DOD:** Clear visual diff UI showing word additions and replacements with single-tap acceptance.

- **Day 5 (Oct 23) | [RSM-REF-05] Job Description Keyword Matcher Tuning**
  - **Branch:** `feature/vignesh-resume-jd-keyword-tuning` | **Priority:** High
  - **Scope:** Support n-gram tokenization (bi-grams and tri-grams) in `keyword_extractor_service.dart` to capture compound technologies (e.g., "Google Cloud", "Spring Boot").
  - **DOD:** Zero false positive keywords; multi-word technologies recognized as single entities.

- **Day 6 (Oct 24) | [RSM-REF-06] Input Validation & Character Sanitizer**
  - **Branch:** `feature/vignesh-resume-input-sanitizer` | **Priority:** High
  - **Scope:** Replace or sanitize emojis and zero-width spaces with safe ASCII/UTF-8 equivalents before sending to PDF generator canvas in `pdf_text_sanitizer.dart`.
  - **DOD:** All special characters and emojis either safely mapped or stripped without breaking PDF output.

- **Day 7 (Oct 25) | [RSM-REF-07] Editor & AI Integration Regression Suite**
  - **Branch:** `feature/vignesh-resume-editor-regression` | **Priority:** High
  - **Scope:** Run `flutter test test/features/tailoring/` and `test/features/resume/`. Verify all form validation tests and AI failover mocks pass. Clean up lint warnings.
  - **DOD:** All editor and AI tests pass cleanly; gatekeeper checks pass.

---

### 🔹 Krishna (ATS Templates, Typography & Vector PDF Track)
- **Day 1 (Oct 19) | [RSM-TPL-01] Multi-Page Layout & Orphan Header Prevention**
  - **Branch:** `feature/krishna-resume-pagebreak-orphan-fix` | **Priority:** Critical
  - **Scope:** Wrap experience and education items in keep-together layout constraints in `pdf_service.dart` and template implementations to push full blocks to page 2 if space is insufficient.
  - **DOD:** Page breaks always occur cleanly between complete experience blocks, never mid-sentence.

- **Day 2 (Oct 20) | [RSM-TPL-02] Template Typography & Margin Polish**
  - **Branch:** `feature/krishna-resume-template-typography` | **Priority:** High
  - **Scope:** Normalize margin constants (0.5 to 0.75 in), heading sizes (H1: 18-22pt, H2: 12-14pt, Body: 9.5-11pt), and line heights across all 7 templates.
  - **DOD:** Consistent visual rhythm and strictly ATS-compliant typography across every template.

- **Day 3 (Oct 21) | [RSM-TPL-03] Vector PDF Hyperlink & Metadata Integrity**
  - **Branch:** `feature/krishna-resume-hyperlink-metadata` | **Priority:** High
  - **Scope:** Use `pw.UrlLink` for external profiles and mailto links. Populate PDF Document metadata (title, author, subject, creator) for standard ATS parsers.
  - **DOD:** Exported PDFs have clickable links in Acrobat/Preview and embedded ATS metadata.

- **Day 4 (Oct 22) | [RSM-TPL-04] Interactive Preview Viewport Optimization**
  - **Branch:** `feature/krishna-resume-preview-optimization` | **Priority:** High
  - **Scope:** Debounce PDF regeneration in `resume_preview_screen.dart` when preview options change. Enable hardware acceleration and optimize rasterization scale factor.
  - **DOD:** Smooth 60fps pinch-to-zoom and page transitions in resume preview.

- **Day 5 (Oct 23) | [RSM-TPL-05] Color Theme & Custom Accent Palettes**
  - **Branch:** `feature/krishna-resume-color-palettes` | **Priority:** High
  - **Scope:** Implement predefined executive color palettes (Navy, Slate, Burgundy, Forest Green, Monochrome) that maintain high contrast on standard white paper and B&W laser printers.
  - **DOD:** All template themes look professional in both color and black-and-white printouts.

- **Day 6 (Oct 24) | [RSM-TPL-06] Export Customization Sheet**
  - **Branch:** `feature/krishna-resume-export-customization-sheet` | **Priority:** High
  - **Scope:** Add switches in `pdf_export_customization_dialog.dart` for page numbering, contact icon style, and date format. Pass settings dynamically to `pdf_service`.
  - **DOD:** User can customize export formatting toggles with live preview reflection.

- **Day 7 (Oct 25) | [RSM-TPL-07] Golden Master PDF Audit & Test Suite**
  - **Branch:** `feature/krishna-resume-golden-pdf-audit` | **Priority:** Critical
  - **Scope:** Run `flutter test test/features/templates/ats_templates_test.dart` and `test/services/pdf_service_layout_test.dart`. Ensure zero overflows and verify `flutter analyze` reports 0 issues.
  - **DOD:** All template layout and golden PDF tests pass cleanly with zero warnings.

---

### 🔹 Adithya (Cross-App Persistence & Security Track)
- **Day 1 (Oct 19) | [APP-HRD-01] Hive DB Safe Migration & Backup**
  - **Branch:** `feature/adithya-crossapp-hive-safe-migration` | **Priority:** Critical
  - **Scope:** Wrap `Hive.openBox` calls in schema migration wrappers that verify typeIds before opening. Create an automated backup copy before schema migration in `encrypted_hive_persistence.dart`.
  - **DOD:** Safe Hive initialization with automatic backup to prevent box corruption on updates.

- **Day 3 (Oct 21) | [APP-HRD-03] Biometric & App Lock Polish**
  - **Branch:** `feature/adithya-resume-biometric-lock-polish` | **Priority:** High
  - **Scope:** Handle `AppLifecycleState.paused` and `resumed` by applying a privacy blur overlay when app is backgrounded. Verify biometrics cancel gracefully.
  - **DOD:** App contents blurred in task switcher; biometrics unlock smoothly.

- **Day 5 (Oct 23) | [APP-HRD-05] Cold Start & Asset Preloading Optimization**
  - **Branch:** `feature/adithya-crossapp-coldstart-optimization` | **Priority:** High
  - **Scope:** Parallelize Hive initialization, SharedPreferences loading, and precache font assets on splash screen. Profile launch latency.
  - **DOD:** App launches in under 600ms with smooth fade-in from native splash.
