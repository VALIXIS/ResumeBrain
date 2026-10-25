# Resume Brain — AI Resume Architect & ATS Optimization Engine

[![CI/CD Pipeline](https://github.com/VALIXIS/ResumeBrain/actions/workflows/ci.yml/badge.svg)](https://github.com/VALIXIS/ResumeBrain/actions)
[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Riverpod](https://img.shields.io/badge/State-Riverpod%202.x-00D2B8)](https://riverpod.dev)
[![PDF Engine](https://img.shields.io/badge/PDF-Vector%20Rendering-red)](https://pub.dev/packages/pdf)
[![Storage](https://img.shields.io/badge/Storage-Hive%20%2B%20Secure%20Storage-F89820)](https://pub.dev/packages/hive)
[![Tests](https://img.shields.io/badge/Tests-299%2F299%20Passing-brightgreen)](https://github.com/VALIXIS/ResumeBrain)
[![License: Proprietary](https://img.shields.io/badge/License-Proprietary-red.svg)](LICENSE)

**Resume Brain** is an enterprise-grade, AI-assisted resume creation, ATS (Applicant Tracking System) optimization, and vector PDF compilation engine in the **VALIXIS Enterprise Suite**. Built on Flutter and Riverpod, it provides algorithmic ATS scoring, real-time bullet point achievement synthesis, multilingual CV translation, biometric profile encryption, and modular typographic resume template compilation.

---

## Key Capabilities

### AI-Powered Content Optimization
* **Live Job Description Tailor**: Analyzes target job specs and dynamically suggests missing keywords, tech skills, and summary adjustments with real-time scoring.
* **Metrics-Driven Bullet Enhancer**: Transforms passive resume entries into quantifiable, high-impact achievements using action verbs and STAR frameworks.
* **Multilingual Translation Engine**: Translates resumes across Spanish, German, French, Japanese, and other languages while retaining strict industry nomenclature.
* **ATS Compatibility Scoring**: Calibrates formatting against ATS parsing heuristics across 5 rigorous quality tiers (A through E).

### Typographic Template Registry
* **7+ Engineered Formats**: Pass ATS layout parsers cleanly with zero floating columns or unindexed text frames.
  1. **Academic Clean**: High-legibility serif layout tailored for academia, research, and fellowships.
  2. **Executive Minimal**: High-density typography designed for VP, Director, and C-suite profiles.
  3. **Tech Modern**: Contemporary layout with specialized skill pills, project matrices, and repository links.
  4. **Academic CV**: Multi-page expanded curriculum vitae with publication and conference registries.
  5. **Creative Professional**: Modern color accents and asymmetric dual-column structure.
  6. **Modern Classic**: Standard corporate layout for legal, financial, and strategic consulting.
  7. **Tech Specialist**: System architecture, cloud certification, and infrastructure matrix layout.

### Precision Vector PDF Engine & Cryptography
* **Native Vector Output**: High-resolution vector PDF generation with configurable page sizes (A4 / US Letter), line height ratios, and margins.
* **Encrypted Document Export**: Optional password-protected AES PDF encryption for sensitive executive CVs.
* **Hardware-Backed Biometrics**: Fingerprint and Face ID authentication for local resume vault access via `local_auth`.

---

## System Architecture

```
+-----------------------------------------------------------------------------+
|                                RESUME BRAIN                                 |
|                                                                             |
|  +--------------------+   +-----------------------+   +-------------------+ |
|  | User Interface     |   |   State Management    |   | AI & Translation  | |
|  | - Resume Builder   |-->| - Riverpod Providers  |<--| - Gemini Flash    | |
|  | - Live ATS Radar   |   | - Startup Diagnostics |   | - Groq Llama      | |
|  | - Template Preview |   | - Theme Controller    |   | - ATS Evaluator   | |
|  +--------------------+   +-----------------------+   +-------------------+ |
|            |                          |                         |           |
|            v                          v                         v           |
|  +------------------------------------------------------------------------+ |
|  |               Vector PDF Compiler & Typography Engine                  | |
|  |        (dart_pdf vector renderer, encrypted export, printing)          | |
|  +------------------------------------------------------------------------+ |
|                                       ^                                     |
|                                       | Local / Cloud Persistence           |
|                                       v                                     |
|  +------------------------------------------------------------------------+ |
|  |             Hive Box Storage + Flutter Secure Storage Vault             | |
|  +------------------------------------------------------------------------+ |
+-----------------------------------------------------------------------------+
```

---

## Directory Structure

```
Resume Brain/
├── .devcontainer/                  # VS Code & Codespaces hermetic container
├── .github/
│   └── workflows/
│       ├── ci.yml                 # 4-stage GitHub Actions enterprise pipeline
│       └── valixis_gatekeeper.yml # PR gatekeeper workflow
├── lib/
│   ├── app/                       # Riverpod provider configurations & routes
│   ├── core/                      # Encryption, theme, typography, & storage
│   ├── features/                  # Builder, preview, templates, & ATS modules
│   ├── services/                  # PDF rendering, AI tailor, & translation services
│   └── main.dart                  # Top-level entry point with diagnostic watchdog
├── test/
│   ├── core/                      # Typography, fallback & storage unit tests
│   ├── features/                  # Feature widgets, template renders & ATS tests
│   └── startup_architecture_test.dart # Cold-boot diagnostics & non-blocking tests
├── Dockerfile                     # Multi-stage hermetic web build
├── docker-compose.yml             # Local evaluation stack
├── nginx.conf                     # Production SPA routing & security headers
├── pubspec.yaml                   # Dependency specification
└── analysis_options.yaml          # Strict linting & static analysis rules
```

---

## Environment Variables

| Variable | Description | Required | Default |
| :--- | :--- | :---: | :--- |
| `GEMINI_API_KEY` | Google Gemini API key for resume synthesis | No | Empty (Mock fallback) |
| `GROQ_API_KEY` | Groq Llama API key for ultra-fast generation | No | Empty (Mock fallback) |
| `SUPABASE_URL` | Optional Supabase cloud synchronization URL | No | Empty (Offline mode) |
| `SUPABASE_ANON_KEY` | Optional Supabase anonymous client key | No | Empty (Offline mode) |
| `PORT` | Container binding port for Nginx web server | No | `80` (mapped to `8086`) |

---

## Quickstart

### Prerequisites
- [Flutter SDK](https://flutter.dev/docs/get-started/install) (`>= 3.24.0`)
- [Dart SDK](https://dart.dev/get-dart) (`>= 3.5.0`)
- [Docker & Docker Compose](https://www.docker.com/) (optional)

### Clean-Clone Setup & Local Run

```bash
# Clone the repository
git clone https://github.com/VALIXIS/ResumeBrain.git
cd "Resume Brain"

# Install dependencies
flutter pub get

# Run on Chrome
flutter run -d chrome

# Run on Android / iOS
flutter run
```

### Running with Docker

```bash
# Build and launch the container
docker compose up -d --build

# Access the application at http://localhost:8086
```

---

## Testing & Coverage

Run the complete hermetic test suite:

```bash
# Run all 299 automated tests
flutter test

# Generate lcov coverage report
flutter test --coverage

# Run static analysis
dart analyze lib
```

All 299 tests execute hermetically with zero external network or database dependencies.

---

## License

Proprietary © VALIXIS. All rights reserved.
