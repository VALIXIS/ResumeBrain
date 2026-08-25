import sys
import os
from reportlab.lib.pagesizes import letter
from reportlab.lib import colors
from reportlab.lib.units import inch
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.platypus import (
    SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, PageBreak, KeepTogether, HRFlowable
)
from reportlab.pdfgen import canvas

class NumberedCanvas(canvas.Canvas):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self._saved_page_states = []

    def showPage(self):
        self._saved_page_states.append(dict(self.__dict__))
        self._startPage()

    def save(self):
        num_pages = len(self._saved_page_states)
        for state in self._saved_page_states:
            self.__dict__.update(state)
            self.draw_header_footer(num_pages)
            super().showPage()
        super().save()

    def draw_header_footer(self, page_count):
        self.saveState()
        self.setFont("Helvetica", 8)
        self.setFillColor(colors.HexColor("#64748B"))
        
        # Draw header (on page 2 and later)
        if self._pageNumber > 1:
            self.drawString(36, 11 * inch - 25, "RESUME BRAIN — 7-DAY EMPLOYEE EXECUTION PLAN")
            self.drawRightString(8.5 * inch - 36, 11 * inch - 25, "VALIXIS | com.valixis.resumebrain")
            self.setStrokeColor(colors.HexColor("#CBD5E1"))
            self.setLineWidth(0.5)
            self.line(36, 11 * inch - 28, 8.5 * inch - 36, 11 * inch - 28)
            
        # Draw footer on all pages
        page_text = f"Page {self._pageNumber} of {page_count}"
        self.drawRightString(8.5 * inch - 36, 20, page_text)
        self.drawString(36, 20, "CONFIDENTIAL — FOR INTERNAL VALIXIS TEAM USE ONLY")
        self.setStrokeColor(colors.HexColor("#CBD5E1"))
        self.setLineWidth(0.5)
        self.line(36, 30, 8.5 * inch - 36, 30)
        
        self.restoreState()

def build_pdf(filename):
    doc = SimpleDocTemplate(
        filename,
        pagesize=letter,
        leftMargin=36,
        rightMargin=36,
        topMargin=36,
        bottomMargin=36
    )

    styles = getSampleStyleSheet()

    # Custom Color Palette
    PRIMARY = colors.HexColor("#0A0E1A")      # Deep Navy
    SECONDARY = colors.HexColor("#4F46E5")    # Indigo
    ACCENT = colors.HexColor("#2563EB")       # Royal Blue
    TEXT_DARK = colors.HexColor("#1E293B")    # Charcoal Body Text
    BG_LIGHT = colors.HexColor("#F8FAFC")     # Light card background
    BORDER_COLOR = colors.HexColor("#E2E8F0") # Border line
    SUCCESS_COLOR = colors.HexColor("#059669")
    WARNING_COLOR = colors.HexColor("#D97706")

    # Typography Styles
    title_style = ParagraphStyle(
        'DocTitle',
        parent=styles['Normal'],
        fontName='Helvetica-Bold',
        fontSize=22,
        leading=26,
        textColor=PRIMARY,
        spaceAfter=4
    )

    subtitle_style = ParagraphStyle(
        'DocSubtitle',
        parent=styles['Normal'],
        fontName='Helvetica',
        fontSize=11,
        leading=15,
        textColor=SECONDARY,
        spaceAfter=12
    )

    h1_style = ParagraphStyle(
        'Heading1_Custom',
        parent=styles['Normal'],
        fontName='Helvetica-Bold',
        fontSize=14,
        leading=18,
        textColor=PRIMARY,
        spaceBefore=14,
        spaceAfter=8,
        keepWithNext=True
    )

    h2_style = ParagraphStyle(
        'Heading2_Custom',
        parent=styles['Normal'],
        fontName='Helvetica-Bold',
        fontSize=11,
        leading=15,
        textColor=SECONDARY,
        spaceBefore=10,
        spaceAfter=4,
        keepWithNext=True
    )

    body_style = ParagraphStyle(
        'Body_Custom',
        parent=styles['Normal'],
        fontName='Helvetica',
        fontSize=8.5,
        leading=11.5,
        textColor=TEXT_DARK,
        spaceAfter=5
    )

    table_header_style = ParagraphStyle(
        'TableHeader',
        parent=styles['Normal'],
        fontName='Helvetica-Bold',
        fontSize=8,
        leading=10,
        textColor=colors.white,
        alignment=0
    )

    table_cell_style = ParagraphStyle(
        'TableCell',
        parent=styles['Normal'],
        fontName='Helvetica',
        fontSize=7.5,
        leading=9.5,
        textColor=TEXT_DARK
    )

    table_cell_bold = ParagraphStyle(
        'TableCellBold',
        parent=table_cell_style,
        fontName='Helvetica-Bold'
    )

    story = []

    # Title Banner
    story.append(Paragraph("Resume Brain — 7-Day Employee Execution Plan", title_style))
    story.append(Paragraph("Comprehensive Parallel Engineering Roadmap, Merge-Conflict Minimization & Master Prompt Suite", subtitle_style))
    story.append(HRFlowable(width="100%", thickness=2, color=SECONDARY, spaceBefore=0, spaceAfter=12))

    # SECTION 1
    story.append(Paragraph("1. Product Vision & 7-Day Engineering Objective", h1_style))
    story.append(Paragraph(
        "<b>Resume Brain</b> (package <code>com.valixis.resumebrain</code> by <b>VALIXIS</b>) is an intelligent, offline-first resume engineering application built using Flutter 3.x, Riverpod 2.x, Hive offline persistence, and PDF compiling engines. Having successfully achieved a clean, fully verified MVP foundation (0 <code>flutter analyze</code> warnings, 6/6 unit & widget test suite passing), the product is now entering a high-intensity, 7-day parallel expansion phase across five dedicated developer workstreams.",
        body_style
    ))
    story.append(Paragraph(
        "<b>Primary Objective:</b> Execute a structured 7-day parallel sprint with 5 software engineers to evolve the MVP into a polished, commercial-grade product ready for Google Play Closed Testing and production deployment. The architecture and task distribution are engineered to enforce strict module boundaries, minimizing merge conflicts, eliminating code duplication, and enabling seamless Founder AI integration on Day 7.",
        body_style
    ))

    # Callout Box: Vision Summary
    vision_box_data = [[
        Paragraph(
            "<b>CORE PARALLEL DEVELOPMENT PRINCIPLES:</b><br/>"
            "• <b>Independent Workstreams:</b> 5 developers operating within distinct directory trees.<br/>"
            "• <b>Interface-Driven Contracts:</b> Features interact strictly through provider abstractions.<br/>"
            "• <b>Zero Real-AI Pollution:</b> AI logic is mocked via stable interfaces until Founder integration.<br/>"
            "• <b>Continuous Verification:</b> PRs require 100% static analysis cleanliness and test passing.",
            body_style
        )
    ]]
    v_table = Table(vision_box_data, colWidths=[540])
    v_table.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,-1), BG_LIGHT),
        ('BOX', (0,0), (-1,-1), 1, SECONDARY),
        ('PADDING', (0,0), (-1,-1), 8),
    ]))
    story.append(v_table)
    story.append(Spacer(1, 10))

    # SECTION 2
    story.append(Paragraph("2. Current Architecture & Technology Stack", h1_style))
    story.append(Paragraph(
        "The project foundation is built upon clean layered Flutter architecture adhering strictly to SOLID design principles:",
        body_style
    ))

    tech_stack_data = [
        [Paragraph("Layer", table_header_style), Paragraph("Technology / Package", table_header_style), Paragraph("Architectural Role & Scope", table_header_style)],
        [Paragraph("UI Framework", table_cell_bold), Paragraph("Flutter 3.22+ / Dart 3.x", table_cell_style), Paragraph("Cross-platform UI rendering with Material 3 components.", table_cell_style)],
        [Paragraph("State Management", table_cell_bold), Paragraph("flutter_riverpod 2.5+", table_cell_style), Paragraph("Global reactive providers registered in <code>lib/app/providers.dart</code>.", table_cell_style)],
        [Paragraph("Local Storage", table_cell_bold), Paragraph("hive / hive_flutter 1.1+", table_cell_style), Paragraph("NoSQL key-value persistence for resumes and app preferences.", table_cell_style)],
        [Paragraph("PDF Generation", table_cell_bold), Paragraph("pdf 3.10+ / printing 5.11+", table_cell_style), Paragraph("Vector PDF layout engine & native printing/export preview.", table_cell_style)],
        [Paragraph("AI Architecture", table_cell_bold), Paragraph("Provider-Agnostic AIService", table_cell_style), Paragraph("Unified <code>AIRequest</code>/<code>AIResponse</code> payload handling with mock fallbacks.", table_cell_style)],
        [Paragraph("Design System", table_cell_bold), Paragraph("Custom Core Tokens", table_cell_style), Paragraph("Centralized <code>AppColors</code>, <code>AppTypography</code>, <code>AppSpacing</code>, <code>AppCard</code>.", table_cell_style)],
    ]
    ts_table = Table(tech_stack_data, colWidths=[90, 150, 300])
    ts_table.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,0), PRIMARY),
        ('ALIGN', (0,0), (-1,-1), 'LEFT'),
        ('VALIGN', (0,0), (-1,-1), 'MIDDLE'),
        ('GRID', (0,0), (-1,-1), 0.5, BORDER_COLOR),
        ('ROWBACKGROUNDS', (0,1), (-1,-1), [colors.white, BG_LIGHT]),
        ('PADDING', (0,0), (-1,-1), 4),
    ]))
    story.append(ts_table)
    story.append(Spacer(1, 10))

    # SECTION 3
    story.append(Paragraph("3. Team Ownership Matrix", h1_style))
    story.append(Paragraph(
        "To prevent file locking and merge conflicts during 7 days of concurrent development, explicit ownership boundaries are enforced across the codebase:",
        body_style
    ))

    matrix_data = [
        [Paragraph("Role", table_header_style), Paragraph("Workstream", table_header_style), Paragraph("Primary Ownership Directory", table_header_style), Paragraph("Key Responsibilities & Scope", table_header_style)],
        [
            Paragraph("<b>Founder</b>", table_cell_style),
            Paragraph("AI & Release", table_cell_style),
            Paragraph("<code>lib/features/ai/</code><br/><code>lib/main.dart</code>", table_cell_style),
            Paragraph("Real AI provider integration, AI prompts, response schemas, cross-feature AI wiring, final architecture approval, release build compilation.", table_cell_style)
        ],
        [
            Paragraph("<b>Co-Founder</b>", table_cell_style),
            Paragraph("Supervision", table_cell_style),
            Paragraph("Repository Root<br/>Docs & PRs", table_cell_style),
            Paragraph("Employee coordination, progress tracking, functional review, dependency management, PR pre-review, regression testing oversight.", table_cell_style)
        ],
        [
            Paragraph("<b>Employee 1</b>", table_cell_style),
            Paragraph("Resume Builder", table_cell_style),
            Paragraph("<code>lib/features/resume/</code><br/><code>lib/data/models/</code>", table_cell_style),
            Paragraph("Resume editor enhancements, section expansion (certs, publications), dynamic reordering, input validation, completeness score calculator.", table_cell_style)
        ],
        [
            Paragraph("<b>Employee 2</b>", table_cell_style),
            Paragraph("Resume Analysis", table_cell_style),
            Paragraph("<code>lib/features/analysis/</code>", table_cell_style),
            Paragraph("ATS analysis UI, deterministic scoring engine (0-100), strengths/weaknesses breakdown, keyword check infrastructure, mock AI analysis interface.", table_cell_style)
        ],
        [
            Paragraph("<b>Employee 3</b>", table_cell_style),
            Paragraph("Matching & Tailor", table_cell_style),
            Paragraph("<code>lib/features/job_matching/</code><br/><code>lib/features/tailoring/</code>", table_cell_style),
            Paragraph("Job description management, resume ↔ JD comparison, keyword overlap calculator, tailoring workflow, diff preview UI, mock AI tailor interface.", table_cell_style)
        ],
        [
            Paragraph("<b>Employee 4</b>", table_cell_style),
            Paragraph("UI/UX & Home", table_cell_style),
            Paragraph("<code>lib/features/home/</code><br/><code>lib/core/theme/</code><br/><code>lib/core/widgets/</code>", table_cell_style),
            Paragraph("Dashboard analytics summary, design system consistency, micro-animations, empty/loading states, responsive/tablet support, light/dark theme.", table_cell_style)
        ],
        [
            Paragraph("<b>Employee 5</b>", table_cell_style),
            Paragraph("PDF & Templates", table_cell_style),
            Paragraph("<code>lib/features/pdf/</code><br/><code>lib/features/templates/</code><br/><code>lib/data/repositories/</code>", table_cell_style),
            Paragraph("PDF layout engine, font loading, pagination handling, 3 new ATS templates, export/share options, offline repository & cloud backup adapter prep.", table_cell_style)
        ],
    ]
    m_table = Table(matrix_data, colWidths=[65, 80, 145, 250])
    m_table.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,0), PRIMARY),
        ('ALIGN', (0,0), (-1,-1), 'LEFT'),
        ('VALIGN', (0,0), (-1,-1), 'TOP'),
        ('GRID', (0,0), (-1,-1), 0.5, BORDER_COLOR),
        ('ROWBACKGROUNDS', (0,1), (-1,-1), [colors.white, BG_LIGHT]),
        ('PADDING', (0,0), (-1,-1), 4),
    ]))
    story.append(m_table)
    story.append(Spacer(1, 10))

    # SECTION 4
    story.append(Paragraph("4. Global Coding & PR Rules", h1_style))
    story.append(Paragraph(
        "To ensure frictionless parallel execution and zero merge conflicts, all 5 employees must strictly adhere to the six core engineering rules:",
        body_style
    ))

    rules_text = (
        "<b>Rule 1: Ownership Boundaries:</b> Developers must only modify files inside their assigned primary directories. Never edit another employee's directory.<br/>"
        "<b>Rule 2: Shared Files Protocol:</b> Changes to <code>lib/main.dart</code>, <code>lib/app/providers.dart</code>, <code>lib/core/</code>, or <code>pubspec.yaml</code> must be minimal, documented, and approved by the Co-Founder prior to committing.<br/>"
        "<b>Rule 3: No Giant Refactors:</b> Rewriting existing core logic, renaming large directory trees, replacing Riverpod/Hive/PDF, or deleting functional features is strictly forbidden.<br/>"
        "<b>Rule 4: Stable Interfaces:</b> When cross-feature data is required, define abstract contracts or interfaces. Never depend directly on unmerged implementations.<br/>"
        "<b>Rule 5: Dependency Control:</b> No third-party package additions without Co-Founder authorization and technical justification.<br/>"
        "<b>Rule 6: Daily PR Discipline:</b> Every employee submits exactly one logical PR per day with a standardized description containing: Feature, Files Changed, Dependencies, Test Verification, and Integration Notes."
    )
    story.append(Paragraph(rules_text, body_style))
    story.append(Spacer(1, 10))

    # SECTION 5: 7-DAY SCHEDULE
    story.append(PageBreak())
    story.append(Paragraph("5. Complete Day 1 – Day 7 Development Schedule", h1_style))
    story.append(Paragraph(
        "The following multi-day matrix outlines every task, target file, expected behavior, dependency, deliverable, and integration contract across the 7-day development cycle.",
        body_style
    ))

    # Days 1 to 7 Detailed Tables
    days_data = [
        # DAY 1
        ("Day 1: Foundation Understanding, Feature Skeletons & Interface Contracts", [
            ("Emp 1", "Resume Builder", "Dynamic Section Models & State Setup", "lib/features/resume/, lib/data/models/", "Add Certifications, Languages, Custom Sections models to `resume_models.dart`. Create editor tab skeleton for expanded sections.", "None", "lib/features/resume/presentation/section_editor_tab.dart created with state binding.", "flutter test passing, model serialization tests."),
            ("Emp 2", "Resume Analysis", "ATS Analysis Domain Skeleton & State", "lib/features/analysis/", "Create `ResumeAnalysisReport` model and `AnalysisEngine` interface with deterministic mock score (0-100).", "None", "Analysis domain models & stub provider in `lib/features/analysis/`.", "Unit test for deterministic calculation logic."),
            ("Emp 3", "Job Matching", "Job Description Input & Storage Skeleton", "lib/features/job_matching/", "Create `JobDescription` model, `JobMatchingController`, and JD input UI screen with local state.", "None", "JD input form with validation and temporary in-memory list.", "Widget test for JD input screen rendering."),
            ("Emp 4", "UI/UX & Home", "Dashboard Widget Restructuring & Tokens", "lib/features/home/, lib/core/theme/", "Refactor home dashboard into modular sub-widgets (`Header`, `RecentResumes`, `QuickActions`). Audit AppColors usage.", "None", "Modular home screen split into 3 reusable widgets.", "Widget test verifying home dashboard elements."),
            ("Emp 5", "PDF & Templates", "PDF Engine Margins & Custom Font Support", "lib/features/pdf/, lib/features/templates/", "Extend `PdfService` to accept custom page margins, font sizes, and line height configurations.", "None", "PdfService extended with `PdfCustomizationOptions` parameter.", "Pdf rendering unit tests for dynamic margins.")
        ]),
        # DAY 2
        ("Day 2: Core Feature Implementation", [
            ("Emp 1", "Resume Builder", "Certifications & Languages UI Editors", "lib/features/resume/presentation/", "Build form inputs for adding, editing, and deleting Certifications and Languages with validation.", "Day 1 Models", "Full CRUD UI forms for Certifications & Languages sections.", "Widget tests for adding/removing entries."),
            ("Emp 2", "Resume Analysis", "Deterministic Rules Engine Implementation", "lib/features/analysis/services/", "Implement rule-based checks for contact info completeness, bullet count, word length, action verbs.", "Day 1 Skeleton", "Rule evaluators producing categorised `AnalysisIssue` lists.", "Unit tests verifying score calculation rules."),
            ("Emp 3", "Job Matching", "Keyword Extractor & Overlap Engine", "lib/features/job_matching/services/", "Build `KeywordExtractorService` to parse technical skills/terms from JD and compare against Resume skills.", "Day 1 Models", "Matching score % and missing keywords breakdown logic.", "Unit test for skill matching overlap percentage."),
            ("Emp 4", "UI/UX & Home", "Analytics Summary Cards & Quick Stats", "lib/features/home/presentation/widgets/", "Add summary metric cards (Total Resumes, Avg ATS Score, Recent Activity) on home dashboard.", "Emp 2 Score Interface", "Metric summary widget rendered dynamically on home screen.", "Widget test for summary stat cards."),
            ("Emp 5", "PDF & Templates", "Template 3: Creative Professional Implementation", "lib/features/templates/implementations/", "Create `CreativeProfessionalTemplate` with sidebar layout, accent colors, and modern typography.", "Day 1 Font Setup", "`creative_professional_template.dart` registered in `TemplateRegistry`.", "PDF visual compilation test.")
        ]),
        # DAY 3
        ("Day 3: Primary Feature Completion", [
            ("Emp 1", "Resume Builder", "Drag-and-Drop Reordering & Field Validation", "lib/features/resume/widgets/", "Implement ReorderableListView for resume experience/education items and real-time field validation.", "Day 2 Editors", "Reorderable section UI with instant inline validation feedback.", "Widget test for list reordering gestures."),
            ("Emp 2", "Resume Analysis", "Analysis Results Screen & Score Gauge", "lib/features/analysis/presentation/", "Build full analysis UI with circular score meter, section badges, and actionable suggestion cards.", "Day 2 Engine", "`AnalysisResultsScreen` with interactive filter tabs.", "Widget test for score display & tabs."),
            ("Emp 3", "Job Matching", "Match Breakdown UI & Keyword Gap Screen", "lib/features/job_matching/presentation/", "Build `JobMatchResultsScreen` displaying overall match score, matched skills chips, and missing keywords list.", "Day 2 Engine", "Visual comparison dashboard for JD vs Resume.", "Widget test for match score visual rendering."),
            ("Emp 4", "UI/UX & Home", "Dark/Light Theme System Implementation", "lib/core/theme/", "Configure `AppTheme.darkTheme` and `AppTheme.lightTheme` with theme toggle provider in Riverpod.", "Day 1 Tokens", "Theme switching functionality working across core screens.", "Widget test for theme mode change."),
            ("Emp 5", "PDF & Templates", "Template 4: Tech Specialist Implementation", "lib/features/templates/implementations/", "Create `TechSpecialistTemplate` optimizing for code projects, tech stack badges, and compact layout.", "Day 2 Registry", "`tech_specialist_template.dart` registered in `TemplateRegistry`.", "PDF visual compilation test.")
        ]),
        # DAY 4
        ("Day 4: Advanced Functionality & UX Refinements", [
            ("Emp 1", "Resume Builder", "Resume Completeness Score & Tips Bar", "lib/features/resume/widgets/", "Implement real-time completeness progress indicator showing missing sections and improvement suggestions.", "Day 3 Validation", "`CompletenessIndicator` widget integrated into editor header.", "Widget test for completeness score update."),
            ("Emp 2", "Resume Analysis", "Strengths, Weaknesses & Detailed Feedback UI", "lib/features/analysis/presentation/widgets/", "Add detailed accordion cards for Formatting, Content, and Keyword strengths/weaknesses.", "Day 3 UI", "Categorized feedback UI components.", "Widget test for accordion expanding state."),
            ("Emp 3", "Job Matching", "Resume Tailoring Workflow & Side-by-Side View", "lib/features/tailoring/presentation/", "Build `TailorResumeScreen` showing current bullet points vs suggested tailored bullet points.", "Day 3 Gap Screen", "Interactive tailoring workflow screen with accept/reject buttons.", "Widget test for side-by-side suggestion cards."),
            ("Emp 4", "UI/UX & Home", "Micro-Animations, Empty & Loading States", "lib/core/widgets/, lib/features/home/", "Add shimmer loading indicators, smooth page transitions, and subtle hover/tap scale animations.", "Day 3 Theme", "Custom animated widgets & state feedback screens.", "Widget test for loading and empty states."),
            ("Emp 5", "PDF & Templates", "Template 5: Academic CV & Multi-page Pagination", "lib/features/pdf/services/, lib/features/templates/", "Create `AcademicCvTemplate` and fix multi-page header/footer page numbering in `PdfService`.", "Day 3 Engine", "Multi-page pagination engine with page numbers.", "PDF multi-page rendering test.")
        ]),
        # DAY 5
        ("Day 5: Integration Preparation & Edge Case Handling", [
            ("Emp 1", "Resume Builder", "Custom Sections & Dynamic Field Extensibility", "lib/features/resume/", "Support arbitrary custom user sections (e.g. Publications, Volunteer, Awards) with title & bullets.", "Day 4 Completeness", "Custom section CRUD operations completely integrated.", "Widget test for custom section addition."),
            ("Emp 2", "Resume Analysis", "Mock AI Analysis Interface & Fallback Logic", "lib/features/analysis/services/", "Create `AiAnalysisAdapter` linking `AIService` request to analysis engine with graceful fallback.", "Day 4 Feedback", "Bridge between Analysis Engine and AIService contract.", "Unit test for AI analysis request fallback."),
            ("Emp 3", "Job Matching", "Tailored Resume Apply & Save Integration", "lib/features/tailoring/services/", "Implement 'Apply Suggestions' action to update active `Resume` state in `currentResumeProvider`.", "Day 4 Workflow", "Tailored bullet points seamlessly copied to active resume.", "Unit test for resume state mutation after apply."),
            ("Emp 4", "UI/UX & Home", "Responsive Tablet & Desktop Layout Adapters", "lib/features/home/presentation/", "Add `LayoutBuilder` breakpoints to adapt home and navigation screens for tablet screen dimensions.", "Day 4 Animations", "Dual-pane tablet dashboard layout.", "Widget test for responsive width breakpoints."),
            ("Emp 5", "PDF & Templates", "Repository Abstraction for Storage & Cloud Sync", "lib/data/repositories/", "Refactor `ResumeRepository` interface and prepare `CloudSyncAdapter` stub for remote backup.", "Day 4 Pagination", "Abstract repository pattern with sync metadata tags.", "Unit tests for Hive repository operations.")
        ]),
        # DAY 6
        ("Day 6: Polish, Testing & Performance Optimization", [
            ("Emp 1", "Resume Builder", "Editor Keyboard Handling & Input Scrubbing", "lib/features/resume/", "Fix focus traversal, auto-scrolling on input, special character sanitization, and undo support.", "Day 5 Custom Sec", "Polished editor with smooth keyboard interaction.", "End-to-end form fill unit tests."),
            ("Emp 2", "Resume Analysis", "Analysis History & Score Comparison", "lib/features/analysis/", "Store historic analysis reports per resume to display score progression over time.", "Day 5 AI Adapter", "Historical analysis score chart/list.", "Unit test for score history persistence."),
            ("Emp 3", "Job Matching", "JD History Management & Export Match Summary", "lib/features/job_matching/", "Save past target job descriptions and export match summary reports.", "Day 5 Apply Logic", "JD history drawer and match report generator.", "Widget test for JD history list."),
            ("Emp 4", "UI/UX & Home", "Global Navigation Refinement & App Polish", "lib/features/home/, lib/core/widgets/", "Refine bottom navigation bar, app drawer, snackbars, and modal bottom sheet designs.", "Day 5 Responsive", "Polished navigation shell across all main tabs.", "Widget test for tab switching."),
            ("Emp 5", "PDF & Templates", "PDF Export Options & High-Resolution Renderer", "lib/features/pdf/", "Add PDF export customization dialog (margins, color scheme, font selection) and high-res print.", "Day 5 Repo", "PDF Export options dialog integrated into preview screen.", "Widget test for PDF options modal.")
        ]),
        # DAY 7
        ("Day 7: Final Stabilization, AI Integration & Release Readiness", [
            ("Emp 1", "Resume Builder", "Final Builder Bug Fixes & Doc Updates", "lib/features/resume/", "Final edge-case resolution, memory leak checks, doc comments, test coverage verification.", "All Workstreams", "Production-ready Resume Builder module.", "100% test pass on feature package."),
            ("Emp 2", "Resume Analysis", "Analysis Engine Stabilization & Wire to Real AI", "lib/features/analysis/", "Finalize analysis logic, assist Founder in connecting real LLM prompts to Analysis UI.", "Founder AI Setup", "Real AI Analysis fully verified.", "Integration test with real AI response payload."),
            ("Emp 3", "Job Matching", "Tailor Engine Stabilization & Wire to Real AI", "lib/features/job_matching/, lib/features/tailoring/", "Assist Founder in connecting live AI prompt generation for JD tailoring.", "Founder AI Setup", "Real AI Tailoring engine verified.", "Integration test with real AI tailor payload."),
            ("Emp 4", "UI/UX & Home", "Global UI Audit & Accessibility Check", "lib/features/home/, lib/core/", "Verify color contrast, touch target sizes (48dp+), semantics tags, dark mode consistency.", "All Features", "Fully accessible, polished user interface.", "Accessibility linting & widget test pass."),
            ("Emp 5", "PDF & Templates", "PDF Engine Final Benchmark & Template Polish", "lib/features/pdf/, lib/features/templates/", "Verify 6 template renderings, memory cleanup during PDF compile, print preview stability.", "All Templates", "Flawless PDF engine supporting 5 templates.", "PDF compilation test for all 5 templates.")
        ]),
    ]

    for day_title, tasks in days_data:
        story.append(Paragraph(day_title, h2_style))
        day_table_data = [
            [Paragraph("Emp", table_header_style), Paragraph("Feature / Module", table_header_style), Paragraph("Files Allowed to Modify", table_header_style), Paragraph("Expected Behavior & Deliverable", table_header_style), Paragraph("Testing & Verification", table_header_style)]
        ]
        for emp, mod, task_name, allowed_files, desc, deps, deliv, test_req in tasks:
            day_table_data.append([
                Paragraph(f"<b>{emp}</b>", table_cell_style),
                Paragraph(f"<b>{mod}</b><br/>{task_name}", table_cell_style),
                Paragraph(f"<code>{allowed_files}</code>", table_cell_style),
                Paragraph(f"{desc}<br/><b>Deliverable:</b> {deliv}", table_cell_style),
                Paragraph(f"<b>Test:</b> {test_req}", table_cell_style)
            ])
        d_table = Table(day_table_data, colWidths=[35, 95, 120, 180, 110])
        d_table.setStyle(TableStyle([
            ('BACKGROUND', (0,0), (-1,0), SECONDARY),
            ('ALIGN', (0,0), (-1,-1), 'LEFT'),
            ('VALIGN', (0,0), (-1,-1), 'TOP'),
            ('GRID', (0,0), (-1,-1), 0.5, BORDER_COLOR),
            ('ROWBACKGROUNDS', (0,1), (-1,-1), [colors.white, BG_LIGHT]),
            ('PADDING', (0,0), (-1,-1), 3),
        ]))
        story.append(d_table)
        story.append(Spacer(1, 8))

    # Founder Dependencies Table
    story.append(Paragraph("Founder & Co-Founder Responsibility Matrix", h2_style))
    f_dep_data = [
        [Paragraph("Day", table_header_style), Paragraph("Employee Workstream", table_header_style), Paragraph("Required Founder Action", table_header_style), Paragraph("Co-Founder Gate & Checkpoint", table_header_style)],
        [Paragraph("Day 1", table_cell_style), Paragraph("All Employees", table_cell_style), Paragraph("Approve initial interface contracts and repository branch setup.", table_cell_style), Paragraph("Verify clean PR merge for Day 1 skeletons; enforce strict directory ownership.", table_cell_style)],
        [Paragraph("Day 2-4", table_cell_style), Paragraph("Employees 2 & 3", table_cell_style), Paragraph("Review AI prompt templates and JSON schemas for Analysis & Tailoring.", table_cell_style), Paragraph("Conduct daily functional review of UI screens & deterministic engines.", table_cell_style)],
        [Paragraph("Day 5", table_cell_style), Paragraph("Employees 2, 3 & 5", table_cell_style), Paragraph("Provide real AI provider keys & configure `AIService` production endpoints.", table_cell_style), Paragraph("Execute cross-feature integration test suite & regression validation.", table_cell_style)],
        [Paragraph("Day 6", table_cell_style), Paragraph("All Employees", table_cell_style), Paragraph("Perform real AI live testing against mock fallbacks.", table_cell_style), Paragraph("Coordinate UI freeze and run global performance/memory profiling.", table_cell_style)],
        [Paragraph("Day 7", table_cell_style), Paragraph("Release Team", table_cell_style), Paragraph("Final PR approval, compile production `.aab` bundle & deploy to Google Play.", table_cell_style), Paragraph("Final release readiness sign-off and closed testing upload verification.", table_cell_style)],
    ]
    f_table = Table(f_dep_data, colWidths=[35, 105, 200, 200])
    f_table.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,0), PRIMARY),
        ('ALIGN', (0,0), (-1,-1), 'LEFT'),
        ('VALIGN', (0,0), (-1,-1), 'TOP'),
        ('GRID', (0,0), (-1,-1), 0.5, BORDER_COLOR),
        ('ROWBACKGROUNDS', (0,1), (-1,-1), [colors.white, BG_LIGHT]),
        ('PADDING', (0,0), (-1,-1), 4),
    ]))
    story.append(f_table)
    story.append(Spacer(1, 10))

    # MASTER PROMPTS (SECTIONS 6 TO 10)
    story.append(PageBreak())
    story.append(Paragraph("6. Employee 1 Master Prompt — Resume Builder", h1_style))
    p1_text = (
        "<b>Pasting Instructions:</b> Employee 1 must copy and paste this Master Prompt into their ChatGPT session once at the start of the project.<br/><br/>"
        "<code>"
        "YOU ARE THE MASTER LEAD FOR EMPLOYEE 1 (RESUME BUILDER WORKSTREAM) ON RESUME BRAIN (com.valixis.resumebrain).<br/>"
        "YOUR PRIMARY OWNERSHIP DIRECTORY IS: lib/features/resume/ AND lib/data/models/<br/>"
        "YOU MUST NEVER MODIFY OTHER EMPLOYEES' DIRECTORIES (lib/features/analysis/, lib/features/job_matching/, lib/features/home/, lib/features/pdf/).<br/>"
        "ARCHITECTURE: Flutter 3.x, Riverpod 2.x state management, Hive persistence.<br/>"
        "RULES:<br/>"
        "1. Always read existing repository code before proposing modifications.<br/>"
        "2. Do NOT rewrite working architecture or rename existing directory structures.<br/>"
        "3. When instructed 'Today my task is Day X', output an EXACT, complete Antigravity prompt using the standard DAILY TASK FORMAT.<br/>"
        "4. Enforce that all generated prompts require `flutter analyze` and `flutter test` to pass with 0 errors.<br/>"
        "5. Include explicit STOP CONDITIONS if a request touches forbidden directories or shared core architecture."
        "</code>"
    )
    story.append(Paragraph(p1_text, body_style))
    story.append(Spacer(1, 10))

    story.append(Paragraph("7. Employee 2 Master Prompt — Resume Analysis & ATS Engine", h1_style))
    p2_text = (
        "<b>Pasting Instructions:</b> Employee 2 must copy and paste this Master Prompt into their ChatGPT session once.<br/><br/>"
        "<code>"
        "YOU ARE THE MASTER LEAD FOR EMPLOYEE 2 (RESUME ANALYSIS & ATS ENGINE) ON RESUME BRAIN (com.valixis.resumebrain).<br/>"
        "YOUR PRIMARY OWNERSHIP DIRECTORY IS: lib/features/analysis/<br/>"
        "YOU MUST NEVER IMPLEMENT REAL AI PROVIDERS (THE FOUNDER OWNS REAL AI). YOU MUST BUILD DETERMINISTIC & MOCK ENGINE INTERFACES ONLY.<br/>"
        "YOU MUST NEVER MODIFY OTHER EMPLOYEES' DIRECTORIES.<br/>"
        "RULES:<br/>"
        "1. Build rule-based, deterministic ATS scoring algorithms (0-100) and analysis report UIs.<br/>"
        "2. Prepare clean interface contracts so the Founder can connect real LLM responses seamlessly on Day 7.<br/>"
        "3. When instructed 'Today my task is Day X', output the exact Antigravity prompt in standard format.<br/>"
        "4. Mandate passing `flutter analyze` and feature unit tests before considering any task complete."
        "</code>"
    )
    story.append(Paragraph(p2_text, body_style))
    story.append(Spacer(1, 10))

    story.append(Paragraph("8. Employee 3 Master Prompt — Job Matching & Tailoring", h1_style))
    p3_text = (
        "<b>Pasting Instructions:</b> Employee 3 must copy and paste this Master Prompt into their ChatGPT session once.<br/><br/>"
        "<code>"
        "YOU ARE THE MASTER LEAD FOR EMPLOYEE 3 (JOB MATCHING & RESUME TAILORING) ON RESUME BRAIN (com.valixis.resumebrain).<br/>"
        "YOUR PRIMARY OWNERSHIP DIRECTORIES ARE: lib/features/job_matching/ AND lib/features/tailoring/<br/>"
        "YOU MUST NEVER IMPLEMENT REAL AI PROVIDERS. BUILD MOCK TAILOR INTERFACES & KEYWORD OVERLAP ENGINES ONLY.<br/>"
        "RULES:<br/>"
        "1. Build Job Description input, skill extraction, keyword matching UI, and side-by-side tailoring workflow.<br/>"
        "2. Interface cleanly with `currentResumeProvider` without mutating model structures outside contracts.<br/>"
        "3. When instructed 'Today my task is Day X', generate the complete daily Antigravity implementation prompt.<br/>"
        "4. Require strict validation via `flutter analyze` and widget tests."
        "</code>"
    )
    story.append(Paragraph(p3_text, body_style))
    story.append(Spacer(1, 10))

    story.append(Paragraph("9. Employee 4 Master Prompt — UI/UX, Theme & Dashboard", h1_style))
    p4_text = (
        "<b>Pasting Instructions:</b> Employee 4 must copy and paste this Master Prompt into their ChatGPT session once.<br/><br/>"
        "<code>"
        "YOU ARE THE MASTER LEAD FOR EMPLOYEE 4 (UI/UX, DESIGN SYSTEM & HOME DASHBOARD) ON RESUME BRAIN (com.valixis.resumebrain).<br/>"
        "YOUR PRIMARY OWNERSHIP DIRECTORIES ARE: lib/features/home/, lib/core/theme/, AND lib/core/widgets/<br/>"
        "YOU MUST BE EXTREMELY CAREFUL WITH SHARED CORE WIDGETS. DOCUMENT ALL SHARED COMPONENT EDITS CLEARLY.<br/>"
        "RULES:<br/>"
        "1. Strictly enforce design system tokens: `AppColors`, `AppTypography`, `AppSpacing`, `AppCard`, `AppButton`.<br/>"
        "2. Implement dark/light theme switching, responsive tablet layouts, micro-animations, and loading states.<br/>"
        "3. When instructed 'Today my task is Day X', output the exact Antigravity prompt.<br/>"
        "4. Verify all changes pass `flutter analyze` and core widget unit tests."
        "</code>"
    )
    story.append(Paragraph(p4_text, body_style))
    story.append(Spacer(1, 10))

    story.append(Paragraph("10. Employee 5 Master Prompt — PDF Engine, Templates & Storage", h1_style))
    p5_text = (
        "<b>Pasting Instructions:</b> Employee 5 must copy and paste this Master Prompt into their ChatGPT session once.<br/><br/>"
        "<code>"
        "YOU ARE THE MASTER LEAD FOR EMPLOYEE 5 (PDF ENGINE, TEMPLATES & STORAGE) ON RESUME BRAIN (com.valixis.resumebrain).<br/>"
        "YOUR PRIMARY OWNERSHIP DIRECTORIES ARE: lib/features/pdf/, lib/features/templates/, AND lib/data/repositories/<br/>"
        "DO NOT INTRODUCE SUPABASE/REMOTE DEPENDENCIES DIRECTLY INTO UNRELATED MODULES. USE REPOSITORY ABSTRACTIONS.<br/>"
        "RULES:<br/>"
        "1. Expand PDF compilation engine, pagination, custom fonts, and create 3 new high-quality ATS templates.<br/>"
        "2. Ensure exact vector PDF rendering without visual overflow across multi-page resumes.<br/>"
        "3. When instructed 'Today my task is Day X', generate the pasteable Antigravity implementation prompt.<br/>"
        "4. Require `flutter analyze` and template compilation test suite to pass cleanly."
        "</code>"
    )
    story.append(Paragraph(p5_text, body_style))
    story.append(Spacer(1, 10))

    # SECTION 11: DAILY PROMPT FORMAT
    story.append(PageBreak())
    story.append(Paragraph("11. Daily Antigravity Prompt Standard Format", h1_style))
    story.append(Paragraph(
        "Every daily prompt generated by an employee's ChatGPT for execution in Antigravity MUST adhere to this standardized schema:",
        body_style
    ))

    prompt_schema_text = (
        "<b>DAY X — [TASK NAME]</b><br/><br/>"
        "<b>OBJECTIVE:</b> Clear, concise single-sentence summary of what will be implemented.<br/><br/>"
        "<b>EXACT IMPLEMENTATION:</b> Step-by-step breakdown of classes, widgets, providers, or functions to create/modify.<br/><br/>"
        "<b>FILES ALLOWED TO MODIFY:</b> Explicit list of absolute/relative file paths assigned to this workstream.<br/><br/>"
        "<b>FILES THAT MUST NOT BE MODIFIED:</b> Explicit list of forbidden paths (e.g. other features, main core files).<br/><br/>"
        "<b>ARCHITECTURE REQUIREMENTS:</b> Riverpod provider patterns, Hive persistence integration, clean layering rules.<br/><br/>"
        "<b>UI/UX REQUIREMENTS:</b> Design tokens (AppColors, AppTypography), responsiveness, animations, light/dark mode.<br/><br/>"
        "<b>DATA/STATE REQUIREMENTS:</b> Model immutability (copyWith), state management bindings.<br/><br/>"
        "<b>INTEGRATION CONTRACT:</b> Interface definitions or provider dependencies required by other workstreams.<br/><br/>"
        "<b>TESTING:</b> Commands to run (`flutter analyze`, `flutter test path/to/test.dart`) and expected results.<br/><br/>"
        "<b>ACCEPTANCE CRITERIA:</b> Measurable, concrete conditions required to declare task done.<br/><br/>"
        "<b>PR REQUIREMENTS:</b> Standardized PR description format with Feature, Files Changed, Tests, Notes.<br/><br/>"
        "<b>STOP CONDITIONS:</b> Triggers requiring Antigravity to HALT and ask for clarification rather than assuming decisions."
    )
    prompt_box = Table([[Paragraph(prompt_schema_text, body_style)]], colWidths=[540])
    prompt_box.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,-1), BG_LIGHT),
        ('BOX', (0,0), (-1,-1), 1, ACCENT),
        ('PADDING', (0,0), (-1,-1), 8),
    ]))
    story.append(prompt_box)
    story.append(Spacer(1, 10))

    # SECTION 12 & 13
    story.append(Paragraph("12. PR Submission & Review Checklist", h1_style))
    pr_checklist_text = (
        "Before submitting a Pull Request at the end of each day, every employee MUST verify:<br/>"
        "[ ] <b>Static Analysis Clean:</b> <code>flutter analyze</code> returns 0 issues/warnings.<br/>"
        "[ ] <b>Tests Passing:</b> <code>flutter test</code> executes with 100% pass rate.<br/>"
        "[ ] <b>Ownership Verification:</b> Modified files are strictly within assigned primary directories.<br/>"
        "[ ] <b>Shared Files Audit:</b> Any change to shared core files has prior Co-Founder approval.<br/>"
        "[ ] <b>No AI Mock Leakage:</b> Real AI keys or HTTP calls are NOT present; interfaces match mock contracts.<br/>"
        "[ ] <b>PR Description Complete:</b> Formatted using the mandatory PR template."
    )
    story.append(Paragraph(pr_checklist_text, body_style))
    story.append(Spacer(1, 10))

    story.append(Paragraph("13. Final Day 7 Release Readiness Checklist", h1_style))
    rel_checklist_text = (
        "Prior to building the release bundle for Google Play Closed Testing, the team must complete:<br/>"
        "[ ] <b>Founder AI Integration:</b> Real LLM API keys connected, prompts validated, JSON schema responses verified.<br/>"
        "[ ] <b>End-to-End User Flow Test:</b> Home → Create Resume → Analyze → Job Match → Tailor → Template → PDF Export.<br/>"
        "[ ] <b>Full Regression Suite:</b> Automated unit, widget, and PDF rendering test suite passing 100%.<br/>"
        "[ ] <b>Release Bundle Compilation:</b> <code>flutter build appbundle --release</code> succeeds with 0 errors.<br/>"
        "[ ] <b>Closed Testing Upload:</b> `.aab` file uploaded to Google Play Console (`com.valixis.resumebrain`)."
    )
    story.append(Paragraph(rel_checklist_text, body_style))

    # Build PDF
    doc.build(story, canvasmaker=NumberedCanvas)
    print(f"PDF successfully generated at: {filename}")

if __name__ == "__main__":
    output_filename = "Resume Brain - 7-Day Employee Execution Plan.pdf"
    build_pdf(output_filename)
