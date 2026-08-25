# Resume Brain — Feature Roadmap & Employee Workstreams

Developed by **VALIXIS** (`com.valixis.resumebrain`)

This roadmap defines the 5 parallel developer workstreams starting tomorrow.

---

## Workstream 1: Resume Builder & Section Expansion
**Owner**: Employee 1  
**Primary Files**: `lib/features/resume/`

### Objectives:
- Expand Section Editor tabs (Certifications, Languages, Publications, Custom Sections).
- Implement Drag-and-Drop section reordering.
- Add real-time input field validation and character counters.
- Connect section AI action buttons to `AIService`.

---

## Workstream 2: Resume Analysis & ATS Scoring Engine
**Owner**: Employee 2  
**Primary Files**: `lib/features/analysis/`

### Objectives:
- Build `ResumeAnalysisEngine` to compute ATS compliance scores (0-100).
- Implement detailed feedback breakdown (Formatting, Action Verbs, Contact Info, Section Completeness).
- Create `AnalysisResultsScreen` with interactive progress indicators.
- Connect real AI analysis requests through `AIService.analyzeResume(resume)`.

---

## Workstream 3: Job Matching & Resume Tailoring
**Owner**: Employee 3  
**Primary Files**: `lib/features/job_matching/`

### Objectives:
- Build `JobDescriptionInputScreen` for pasting job descriptions or URLs.
- Implement keyword overlap calculator (Resume skills vs. Job requirements).
- Build `ResumeTailorScreen` with side-by-side original vs. AI-suggested bullet points.
- Provide "Apply Tailored Suggestions" button to update the active resume.

---

## Workstream 4: Home Dashboard, UI/UX & Design System
**Owner**: Employee 4  
**Primary Files**: `lib/features/home/`, `lib/core/`

### Objectives:
- Enhance Home Dashboard with analytics summary widgets (e.g. Total resumes, Average ATS score).
- Create custom animations and micro-interactions for card selections.
- Add Dark/Light theme toggle support in `AppTheme`.
- Refine responsive screen layouts for tablet and desktop form factors.

---

## Workstream 5: PDF Engine, Storage & Cloud Synchronization
**Owner**: Employee 5  
**Primary Files**: `lib/features/pdf/`, `lib/features/templates/`, `lib/data/`

### Objectives:
- Add 3 additional ATS-conscious PDF templates (Creative Professional, Tech Specialist, Academic CV).
- Implement custom font loading and SVG icon rendering in PDF engine.
- Add Cloud Backup & Sync support (Supabase / Firebase adapter implementation of `ResumeRepository`).
- Enable PDF export customization (margins, line height, primary color picker).
