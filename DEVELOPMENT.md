# Resume Brain — Developer Onboarding & Architecture Guide

Welcome to **Resume Brain** by **VALIXIS** (`com.valixis.resumebrain`).

This repository contains the production-ready MVP foundation designed for Google Play Closed Testing and scaled parallel development by 5 engineers.

---

## 1. Directory & Feature Structure

```text
lib/
├── app/
│   └── providers.dart             # Global Riverpod state providers
│
├── core/                          # Cross-cutting utilities & UI tokens
│   ├── constants/                 # App names, storage keys, configuration
│   ├── errors/                    # Custom error handling
│   ├── theme/                     # AppColors, AppTypography, AppSpacing, AppRadius, AppTheme
│   └── widgets/                   # AppButton, AppCard, AppTextField, StateWidgets
│
├── data/                          # Core Data Layer
│   ├── models/                    # Resume, PersonalInformation, Experience, Education, etc.
│   ├── repositories/              # ResumeRepository, HiveResumeRepository
│   └── services/                  # Persistent storage helpers
│
└── features/                      # Feature Modules (1 per employee workstream)
    ├── home/                      # Dashboard UI & recent resume list
    ├── resume/                    # Multi-section editor & inputs
    ├── templates/                 # ResumeTemplate interface & ATS implementations
    ├── pdf/                       # PDF rendering, byte compilation & sharing
    ├── ai/                        # AIService, AIProvider, MockAIProvider
    ├── analysis/                  # Extension boundary for Employee 2 (AI Analysis)
    ├── job_matching/              # Extension boundary for Employee 3 (Job Matching)
    └── settings/                  # App preferences & backup options
```

---

## 2. State Management Rules (Riverpod 2.x)

- All application state must be stored inside Riverpod `Provider` or `StateNotifierProvider`.
- Do **NOT** put long-term domain logic inside local `StatefulWidget` states.
- Local widget state is permitted only for short-lived UI transitions or text controllers inside dialogs.
- `currentResumeProvider` manages the active resume document in memory and triggers auto-save to `resumesListProvider` / Hive.

---

## 3. Design System & Theme Rules

- Do **NOT** introduce hardcoded colors or ad-hoc text styles in feature screens.
- Use `AppColors` for all color definitions (Deep Navy `#0A0E1A`, Indigo `#6366F1`, Royal Blue `#3B82F6`).
- Use `AppTypography` for typography scaling.
- Use `AppButton`, `AppCard`, and `AppTextField` for consistent component UI across all features.

---

## 4. Data Model Overview

The `Resume` class (`lib/data/models/resume_models.dart`) is strongly typed and includes:
- `PersonalInformation`
- `ProfessionalSummary`
- `List<Experience>`
- `List<Education>`
- `List<Project>`
- `List<Skill>`
- `List<Certification>`
- `List<Language>`
- `List<SocialLink>`

All models provide `toMap()`, `fromMap()`, and `copyWith()` for immutability and Hive offline persistence.

---

## 5. How to Add a New Feature

1. Identify your workstream module in `lib/features/<your_feature>/`.
2. Create subfolders: `presentation/`, `controllers/`, `services/`.
3. If new data structures are needed, extend `lib/data/models/`.
4. Register your Riverpod controllers in `lib/app/providers.dart` or a dedicated provider file in your feature directory.
5. Create UI components using `core/widgets/`.

---

## 6. How to Run the Project

### Prerequisites
- Flutter SDK 3.22+ / 3.44+
- Android Studio / VS Code with Dart & Flutter extensions

### Commands
```bash
# Get dependencies
flutter pub get

# Run static analysis
flutter analyze

# Run unit & widget tests
flutter test

# Run app in debug mode
flutter run
```

---

## 7. How to Build for Release (Google Play Closed Testing)

Generate the Android App Bundle (`.aab`):

```bash
flutter build appbundle --release
```

The output bundle will be located at:
`build/app/outputs/bundle/release/app-release.aab`

---

## 8. Employee Ownership Boundaries

| Workstream | Owner | Primary Scope | Directories |
|---|---|---|---|
| **Workstream 1** | Employee 1 | Resume Builder & Section Expansion | `lib/features/resume/` |
| **Workstream 2** | Employee 2 | Resume Analysis & ATS Score Engine | `lib/features/analysis/` |
| **Workstream 3** | Employee 3 | Job Matching & Resume Tailoring | `lib/features/job_matching/` |
| **Workstream 4** | Employee 4 | Home Dashboard, UI/UX & Design System | `lib/features/home/`, `lib/core/` |
| **Workstream 5** | Employee 5 | PDF Engine, Storage & Cloud Backup | `lib/features/pdf/`, `lib/features/templates/`, `lib/data/` |
