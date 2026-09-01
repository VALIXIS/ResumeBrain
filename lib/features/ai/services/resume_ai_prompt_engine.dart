import '../../../data/models/resume_models.dart';
import 'ai_service.dart';

/// Elite AI Prompt Engine for Resume Brain (VALIXIS Intelligence Core).
/// Implements Google XYZ Formula, Tier-1 Tech Recruiter heuristics,
/// strict passive-voice ban lists, and multi-dimensional ATS evaluation standards.
class ResumeAIPromptEngine {
  static const String systemPersona = '''
You are the Chief AI Resume Strategist and Principal ATS Auditor for Resume Brain (VALIXIS).
Your mission is to transform student and professional resumes into elite, interview-winning documents that pass Tier-1 Tech & Fortune 500 ATS scanners (Workday, Greenhouse, Lever, Taleo, Ashby).

CORE EXCELLENCE PRINCIPLES:
1. GOOGLE XYZ FORMULA: Every rewritten bullet MUST follow:
   "Accomplished [X] as measured by [Y], by doing [Z]"
   Example: "Architected real-time WebSocket messaging layer, reducing API latency by 42% and scaling to 15,000+ concurrent active sessions."

2. STRICT BANNED WEAK PHRASES:
   NEVER use passive, weak phrasing such as:
   - "responsible for", "worked on", "assisted in", "helped with", "handled duties"
   - "participated in", "good team player", "hard working", "passionate about"

3. ELITE POWER VERBS ONLY:
   Lead bullet points with high-impact executive verbs:
   - Leadership & Creation: Spearheaded, Architected, Engineered, Orchestrated, Pioneered, Deployed
   - Optimization & Speed: Optimized, Accelerated, Streamlined, Consolidated, Scaled, Overhauled
   - Impact & Growth: Boosted, Maximized, Reduced, Quantified, Generated, Automated

4. REALISTIC MEASURABLE METRICS:
   Every recommendation and rewrite MUST inject concrete, credible metrics (%, ms, DAU, coverage, RPS, cost savings, user retention).

5. STRICT JSON OUTPUT CONTRACT:
   You MUST return a raw valid JSON object (no markdown wrapping, no conversational filler) with this EXACT structure:
   {
     "outputText": string,
     "score": number (0 to 100),
     "suggestions": [string, string, string],
     "metricsApplied": [string, string],
     "powerVerbs": [string, string],
     "missingKeywords": [string, string],
     "subScores": {
       "impactQuantification": number (0-100),
       "atsReadability": number (0-100),
       "actionVerbs": number (0-100),
       "skillsRelevance": number (0-100)
     }
   }
''';

  /// Builds prompt for enhancing single or multiple bullet points / summary text
  static String buildTextImprovementPrompt(String inputText, {String sectionContext = 'Work Experience'}) {
    return '''
$systemPersona

TASK: ELITE BULLET POINT & CONTENT ENHANCEMENT
SECTION CONTEXT: $sectionContext
RAW INPUT CONTENT:
"$inputText"

INSTRUCTIONS:
1. Rewrite the input text using the Google XYZ Formula: [Power Verb] + [Specific Action/Technology] + [Quantified Result/Metric].
2. If the user provided a weak summary, transform it into a compelling 3-4 sentence value proposition highlighting core domain mastery, technical stack, and career impact.
3. In "outputText", provide the single best, most polished version ready for copy-pasting into a resume.
4. In "suggestions", provide 2-3 specific tactical tips on how the user can further elevate this section.
5. In "metricsApplied", list the specific quantified indicators added (e.g. "40% latency reduction", "10k+ users").
6. In "powerVerbs", list the elite verbs used.
''';
  }

  /// Builds prompt for comprehensive ATS Resume Analysis
  static String buildResumeAnalysisPrompt(Resume resume) {
    final buffer = StringBuffer();
    buffer.writeln(systemPersona);
    buffer.writeln('\nTASK: COMPREHENSIVE ATS RESUME AUDIT & MULTI-DIMENSIONAL SCORING');
    buffer.writeln('\n=== CANDIDATE RESUME DATA ===');
    buffer.writeln('Job Title / Target Role: ${resume.personalInfo.jobTitle}');
    buffer.writeln('Full Name: ${resume.personalInfo.fullName}');
    buffer.writeln('Email: ${resume.personalInfo.email} | Phone: ${resume.personalInfo.phoneNumber}');
    buffer.writeln('Location: ${resume.personalInfo.location} | Website/GitHub: ${resume.personalInfo.website}');
    buffer.writeln('\nProfessional Summary:\n${resume.summary.summaryText}');

    buffer.writeln('\nWork Experiences (${resume.experiences.length}):');
    for (final exp in resume.experiences) {
      buffer.writeln('- Position: ${exp.position} at ${exp.company} (${exp.startDate} - ${exp.isCurrent ? "Present" : exp.endDate})');
      for (final b in exp.bulletPoints) {
        buffer.writeln('  * $b');
      }
    }

    buffer.writeln('\nEducation (${resume.educationList.length}):');
    for (final edu in resume.educationList) {
      buffer.writeln('- ${edu.degree} in ${edu.fieldOfStudy}, ${edu.institution} (${edu.startDate} - ${edu.endDate})');
    }

    buffer.writeln('\nSkills (${resume.skills.length}):');
    buffer.writeln(resume.skills.map((s) => s.name).join(', '));

    buffer.writeln('\nCertifications (${resume.certifications.length}):');
    for (final c in resume.certifications) {
      buffer.writeln('- ${c.name} by ${c.issuingOrganization} (${c.issueDate})');
    }

    buffer.writeln('\nProjects (${resume.projects.length}):');
    for (final p in resume.projects) {
      buffer.writeln('- ${p.title}: ${p.description} (Tech: ${p.technologies.join(", ")})');
      for (final b in p.bulletPoints) {
        buffer.writeln('  * $b');
      }
    }

    buffer.writeln('''
\nEVALUATION MATRIX:
- Overall Score (0-100): Calculated from weighted composite of subScores.
- SubScore 1: impactQuantification (0-100): Percentage of bullets with measurable metrics.
- SubScore 2: atsReadability (0-100): Clean structure, contact completeness, standard headers.
- SubScore 3: actionVerbs (0-100): Use of elite power verbs, zero passive voice.
- SubScore 4: skillsRelevance (0-100): Depth and organization of technical skills.

In "outputText", write a concise 2-sentence executive summary of the resume's market readiness.
In "suggestions", list the top 5 high-priority, actionable fixes the candidate MUST make to maximize interview callbacks.
In "missingKeywords", list high-demand industry skills missing from this profile.
''');

    return buffer.toString();
  }

  /// Builds prompt for Job Matching & Skill Gap Analysis
  static String buildJobMatchingPrompt(Resume resume, String jobDescription) {
    final buffer = StringBuffer();
    buffer.writeln(systemPersona);
    buffer.writeln('\nTASK: JOB DESCRIPTION MATCHING & SKILL GAP ANALYSIS');
    buffer.writeln('\n=== TARGET JOB DESCRIPTION ===\n"$jobDescription"');

    buffer.writeln('\n=== CANDIDATE RESUME SUMMARY ===');
    buffer.writeln('Target Title: ${resume.personalInfo.jobTitle}');
    buffer.writeln('Summary: ${resume.summary.summaryText}');
    buffer.writeln('Skills: ${resume.skills.map((s) => s.name).join(", ")}');
    buffer.writeln('Experience Highlights:');
    for (final exp in resume.experiences) {
      buffer.writeln('- ${exp.position} @ ${exp.company}: ${exp.bulletPoints.join(" ")}');
    }

    buffer.writeln('''
\nINSTRUCTIONS:
1. Calculate a realistic "score" (0-100) representing semantic match percentage against the Job Description.
2. In "outputText", summarize the candidate's core fit in 2 concise sentences.
3. In "suggestions", list 3-4 specific adjustments to bridge the gap.
4. In "missingKeywords", list the top critical keywords from the JD that are absent from the resume.
5. In "subScores", provide:
   - "skillsMatch": 0-100 percentage of required technical skills matched.
   - "experienceMatch": 0-100 relevance of past roles to JD seniority.
   - "domainFit": 0-100 alignment with industry domain terms.
''');

    return buffer.toString();
  }

  /// Builds prompt for 1-Click Resume Tailoring
  static String buildResumeTailoringPrompt(Resume resume, String jobDescription) {
    final buffer = StringBuffer();
    buffer.writeln(systemPersona);
    buffer.writeln('\nTASK: 1-CLICK RESUME TAILORING');
    buffer.writeln('\n=== TARGET JOB DESCRIPTION ===\n"$jobDescription"');

    buffer.writeln('\n=== CANDIDATE RESUME ===');
    buffer.writeln('Current Summary: ${resume.summary.summaryText}');
    buffer.writeln('Experiences:');
    for (final exp in resume.experiences) {
      buffer.writeln('- ${exp.position} @ ${exp.company}:');
      for (final b in exp.bulletPoints) {
        buffer.writeln('  * $b');
      }
    }

    buffer.writeln('''
\nINSTRUCTIONS:
1. Rewrite and tailor the Professional Summary and Experience bullet points to directly highlight keywords from the Job Description.
2. Use Google XYZ Formula for all tailored bullet points.
3. In "outputText", provide the tailored Professional Summary.
4. In "suggestions", list 3 tailored bullet points ready to replace generic experience bullets.
5. In "powerVerbs", list the power verbs introduced.
6. In "missingKeywords", list any remaining JD requirements that candidate should address in interview prep.
''');

    return buffer.toString();
  }
}
