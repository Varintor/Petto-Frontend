/// Parsed view of the Gemini triage response (see backend prompt in
/// app/routers/assessments.py). Gemini is instructed to reply in this exact
/// shape:
///
///   1. OBSERVATIONS
///   ...
///   2. POTENTIAL CONCERNS
///   ...
///   3. RECOMMENDED ACTIONS
///   - DO: ...
///   - DO NOT: ...
///   - URGENCY: ...
///   4. DISCLAIMER
///   ...
///   Risk: HIGH|MODERATE|LOW
class AssessmentAnalysis {
  final List<String> observations;
  final List<String> concerns;
  final String? doAction;
  final String? doNotAction;
  final String? urgency;
  final String? disclaimer;

  /// True when at least one structured field was parsed out of the raw text.
  /// When false, the widget should treat the response as unstructured and
  /// display the raw text instead of empty sections.
  final bool structured;

  const AssessmentAnalysis({
    this.observations = const [],
    this.concerns = const [],
    this.doAction,
    this.doNotAction,
    this.urgency,
    this.disclaimer,
    this.structured = false,
  });

  static const AssessmentAnalysis empty = AssessmentAnalysis();

  static AssessmentAnalysis parse(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return empty;

    // Normalise line endings and strip the trailing "Risk: X" marker line —
    // the risk bucket is already exposed by the backend's risk_level field.
    final normalised = trimmed.replaceAll('\r\n', '\n');
    final withoutRisk = normalised
        .split('\n')
        .where(
          (l) => !RegExp(
            r'^\s*Risk\s*:\s*(LOW|MODERATE|HIGH)\s*$',
            caseSensitive: false,
          ).hasMatch(l),
        )
        .join('\n');

    // Section headers tolerate: optional numbering ("1."), optional markdown
    // bold ("**OBSERVATIONS**"), and an optional trailing colon.
    final headerPattern = RegExp(
      r'(?:^|\n)\s*(?:\*\*\s*)?(?:\d+\.\s*)?(?:\*\*\s*)?(OBSERVATIONS|POTENTIAL\s+CONCERNS|RECOMMENDED\s+ACTIONS|DISCLAIMER)(?:\s*\*\*)?\s*:?\s*(?=\n|$)',
      caseSensitive: false,
    );

    final matches = headerPattern.allMatches(withoutRisk).toList();
    if (matches.isEmpty) {
      return AssessmentAnalysis(
        observations: _toBullets(withoutRisk),
        structured: false,
      );
    }

    final sections = <String, String>{};
    for (var i = 0; i < matches.length; i++) {
      final header = matches[i]
          .group(1)!
          .toUpperCase()
          .replaceAll(RegExp(r'\s+'), ' ');
      final start = matches[i].end;
      final end = i + 1 < matches.length
          ? matches[i + 1].start
          : withoutRisk.length;
      sections[header] = withoutRisk.substring(start, end).trim();
    }

    final actionsText = sections['RECOMMENDED ACTIONS'] ?? '';
    final disclaimerText = sections['DISCLAIMER']?.trim();

    return AssessmentAnalysis(
      observations: _toBullets(sections['OBSERVATIONS'] ?? ''),
      concerns: _toBullets(sections['POTENTIAL CONCERNS'] ?? ''),
      doAction: _extractSubField(actionsText, ['DO']),
      doNotAction: _extractSubField(actionsText, ['DO NOT', "DON'T"]),
      urgency: _extractSubField(actionsText, ['URGENCY']),
      disclaimer: (disclaimerText == null || disclaimerText.isEmpty)
          ? null
          : disclaimerText,
      structured: true,
    );
  }

  /// Pull the value following one of [labels] (e.g. "DO:", "DO NOT:") out of
  /// a recommended-actions block. Stops at the next sibling label or EOF.
  static String? _extractSubField(String text, List<String> labels) {
    if (text.isEmpty) return null;
    // "DO NOT" must be tried before "DO" so it doesn't get swallowed by it.
    final ordered = [...labels]
      ..sort((a, b) => b.length.compareTo(a.length));
    for (final label in ordered) {
      final pattern = RegExp(
        r'(?:^|\n)\s*[-*•]?\s*(?:\*\*\s*)?' +
            RegExp.escape(label) +
            r'\s*(?:\*\*)?\s*:\s*([\s\S]*?)(?=\n\s*[-*•]?\s*(?:\*\*\s*)?(?:DO\s+NOT|DON' +
            "'" +
            r'T|DO|URGENCY)\s*(?:\*\*)?\s*:|$)',
        caseSensitive: false,
      );
      final m = pattern.firstMatch(text);
      if (m != null) {
        final value = _stripMarkdown(m.group(1)!).trim();
        if (value.isNotEmpty) return value;
      }
    }
    return null;
  }

  static List<String> _toBullets(String text) {
    final cleaned = text.trim();
    if (cleaned.isEmpty) return const [];

    final bullets = <String>[];
    for (final raw in cleaned.split('\n')) {
      var line = raw.trim();
      if (line.isEmpty) continue;
      line = line.replaceFirst(RegExp(r'^[-*•]\s*'), '');
      line = _stripMarkdown(line).trim();
      // Skip stray sub-headers that may appear inside a section body.
      if (RegExp(r'^(DO|DO NOT|URGENCY)\s*:', caseSensitive: false)
          .hasMatch(line)) {
        continue;
      }
      if (line.length > 3) bullets.add(line);
    }

    if (bullets.isNotEmpty) return bullets;

    // Last resort: split into sentences so something useful still shows.
    return cleaned
        .split(RegExp(r'(?<=[.!?])\s+'))
        .map((s) => _stripMarkdown(s).trim())
        .where((s) => s.length > 3)
        .toList();
  }

  static String _stripMarkdown(String value) {
    return value
        .replaceAll(RegExp(r'\*\*'), '')
        .replaceAll(RegExp(r'(?<!\w)\*(?!\s)'), '')
        .replaceAll(RegExp(r'(?<!\s)\*(?!\w)'), '');
  }
}
