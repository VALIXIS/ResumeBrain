# 🧠 Resume Brain — AI Resume Architect & ATS Optimizer

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Riverpod](https://img.shields.io/badge/State-Riverpod%202.x-00D2B8)](https://riverpod.dev)
[![PDF Engine](https://img.shields.io/badge/PDF-Vector%20Rendering-red)](https://pub.dev/packages/pdf)
[![Backend](https://img.shields.io/badge/BaaS-Supabase%20PostgreSQL-3ECF8E?logo=supabase&logoColor=white)](https://supabase.com)
[![Storage](https://img.shields.io/badge/Storage-Hive%20%2B%20Secure%20Storage-F89820)](https://pub.dev/packages/hive)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

**Resume Brain** is a comprehensive, AI-assisted resume creation, ATS (Applicant Tracking System) optimization, and vector PDF compilation mobile application built with **Flutter** and **Riverpod**. Designed to bridge the gap between job candidates and hiring managers, Resume Brain provides real-time bullet point enhancement, automated role tailoring, multilingual translation, and publication-ready typographic resume templates.

---

## 🌟 Key Capabilities

### ⚡ AI-Powered Content Optimization
* **Live Resume Tailor**: Paste target job descriptions and automatically align your resume keywords, skills, and summary with algorithmic ATS scoring (`LiveResumeTailorScreen`).
* **Action-Driven Bullet Point Enhancer**: Rewrites weak bullet points into impactful, metrics-driven achievements using action verbs and quantifiable results (`BulletEnhancementService`).
* **Multilingual Translation**: Seamlessly translate your CV into Spanish, German, French, Japanese, and other global languages while preserving technical terminology (`TranslateResumeScreen`).
* **Resume Parser & Import Sanitizer**: Import existing resume PDFs and clean up formatting anomalies automatically.

### 🎨 Modular Template Registry
Features 7+ carefully crafted typographic resume templates engineered to pass ATS automated parsers without layout corruption:
1. **Academic Clean**: Traditional serif layout ideal for research, graduate applications, and academia.
2. **Executive Minimal**: Clean, high-density corporate layout tailored for C-suite and senior leadership.
3. **Tech Modern**: Contemporary layout with specialized skill pills, project matrices, and GitHub links.
4. **Academic CV**: Multi-page expanded curriculum vitae with publications and conferences.
5. **Creative Professional**: Modern color accents and two-column layout for design and marketing leaders.
6. **Modern Classic**: Balanced corporate format suitable for finance, legal, and consulting.
7. **Tech Specialist**: Focused layout highlighting system architectures, frameworks, and cloud certifications.

### 📄 Precision Vector PDF Engine
* **Native Vector Output**: High-resolution print output using the `pdf` and `printing` packages with selectable margins, page sizes (A4 / US Letter), and font scalers.
* **Instant In-App Preview**: Real-time interactive document canvas with zoom and pan controls.
* **Encrypted Export**: Optional password-protected PDF export for sensitive executive portfolios (`EncryptedExportService`).

### 🔒 Enterprise Data Privacy & Security
* **Biometric Authentication**: Secure your private job hunt with fingerprint or face biometric lock (`local_auth`).
* **Hybrid Storage Architecture**: Encrypted local caching via **Hive** and hardware key storage via **Flutter Secure Storage**, paired with optional cloud backup via **Supabase**.

---

## 🏛️ System Architecture

```
lib/
├── features/
│   ├── monetization/        # In-app purchases, subscriptions, and AdMob integration
│   ├── onboarding/          # Interactive career profile setup wizard
│   ├── pdf/                 # Core vector PDF compilation engine
│   │   ├── models/          # PdfExportConfig & page layout settings
│   │   ├── presentation/    # ResumePreviewScreen & dialogs
│   │   ├── services/        # PdfService & layout builders
│   │   └── utils/           # PdfTextSanitizer
│   ├── resume/              # Resume state, editors, and AI enhancement
│   │   ├── models/          # Work experience, education, skills, projects
│   │   ├── presentation/    # LiveResumeEditorScreen, SectionEditorTab
│   │   ├── services/        # BulletEnhancementService, ResumeParserService
│   │   └── widgets/         # ReorderableSectionCard, BulletPointEnhancer
│   └── templates/           # ATS-friendly visual template implementations
│       ├── implementations/ # Academic, Executive, Tech, Creative templates
│       ├── models/          # ResumeTemplate definition
│       └── services/        # TemplateRegistry
├── services/                # Supabase auth, storage, and synchronization
└── main.dart                # Application bootstrap & Riverpod ProviderScope
```

---

## 🚀 Getting Started

### Prerequisites
* **Flutter SDK**: `^3.12.2` or higher
* **Dart SDK**: `^3.12.2`
* **Android Studio / Xcode**: Configured for mobile development
* *(Optional)* **Supabase Account**: For cross-device cloud sync

### Installation & Run

1. **Clone the Repository**
   ```bash
   git clone https://github.com/VALIXIS/ResumeBrain.git
   cd ResumeBrain
   ```

2. **Install Flutter Dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Environment**
   Update your Supabase URL and credentials in `lib/config/constants.dart` (or via `.env`):
   ```dart
   const String supabaseUrl = 'YOUR_SUPABASE_PROJECT_URL';
   const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
   ```

4. **Launch the Application**
   ```bash
   # Run on connected mobile device or emulator
   flutter run
   ```

---

## 📦 Key Dependencies

| Dependency | Purpose |
| :--- | :--- |
| `flutter_riverpod` | Reactive state management and business logic isolation |
| `pdf` & `printing` | Precision vector PDF generation and native platform printing |
| `supabase_flutter` | Authentication, PostgreSQL database, and cloud backup |
| `hive_flutter` | Blazingly fast on-device NoSQL storage |
| `flutter_secure_storage` | Hardware-backed keystore for tokens and sensitive keys |
| `local_auth` | Biometric fingerprint and face unlock authentication |
| `http` | AI refinement API communication |

---

## 📄 License

This repository is licensed under the [MIT License](LICENSE).
