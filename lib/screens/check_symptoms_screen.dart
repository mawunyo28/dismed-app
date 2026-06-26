import 'dart:convert';
import 'package:avatar_glow/avatar_glow.dart';
import 'package:dismed/utils/context_theme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:speech_to_text/speech_to_text.dart';


class DetectedIndicator {
  final String indicator;
  final String status;
  final String recommendedAction;

  DetectedIndicator({
    required this.indicator,
    required this.status,
    required this.recommendedAction,
  });

  factory DetectedIndicator.fromJson(Map<String, dynamic> json) {
    return DetectedIndicator(
      indicator: json['indicator'] ?? '',
      status: json['status'] ?? '',
      recommendedAction: json['recommended_action'] ?? '',
    );
  }
}

class TechnicalAnalysis {
  final String clinicalReasoning;
  final List<String> differentialConsiderations;

  TechnicalAnalysis({required this.clinicalReasoning, required this.differentialConsiderations});

  factory TechnicalAnalysis.fromJson(Map<String, dynamic> json) {
    return TechnicalAnalysis(
      clinicalReasoning: json['clinical_reasoning'] ?? '',
      differentialConsiderations: List<String>.from(json['differential_considerations'] ?? []),
    );
  }
}

class AnalysisResult {
  final List<DetectedIndicator> detectedIndicators;
  final String riskLevel;
  final TechnicalAnalysis technicalAnalysis;
  final String certaintyScore;
  final String disclaimer;

  AnalysisResult({
    required this.detectedIndicators,
    required this.riskLevel,
    required this.technicalAnalysis,
    required this.certaintyScore,
    required this.disclaimer,
  });

  factory AnalysisResult.fromJson(Map<String, dynamic> json) {
    return AnalysisResult(
      detectedIndicators: (json['detected_indicators'] as List? ?? [])
          .map((e) => DetectedIndicator.fromJson(e))
          .toList(),
      riskLevel: json['risk_level'] ?? 'Unknown',
      technicalAnalysis: TechnicalAnalysis.fromJson(json['technical_analysis'] ?? {}),
      certaintyScore: json['certainty_score'] ?? '',
      disclaimer: json['disclaimer'] ?? '',
    );
  }
}

// ── Risk level colours ───────────────────────────────────────────────────────

Map<String, Color> _riskColors(BuildContext context, String level) {
  switch (level.toLowerCase()) {
    case 'low':
      return {'bg': Colors.green.shade50, 'fg': Colors.green.shade700};
    case 'moderate':
      return {'bg': Colors.amber.shade50, 'fg': Colors.amber.shade700};
    case 'severe':
      return {'bg': Colors.orange.shade50, 'fg': Colors.orange.shade700};
    case 'critical':
      return {'bg': context.colors.errorContainer, 'fg': context.colors.onErrorContainer};
    default:
      return {'bg': context.colors.surfaceContainerHighest, 'fg': context.colors.onSurface};
  }
}

// ── Main page ────────────────────────────────────────────────────────────────

class CheckSymptoms extends StatefulWidget {
  const CheckSymptoms({super.key});

  @override
  State<CheckSymptoms> createState() => _CheckSymptomsState();
}

class _CheckSymptomsState extends State<CheckSymptoms> with SingleTickerProviderStateMixin {
  // Controllers
  final _descController = TextEditingController();
  final _tempController = TextEditingController(text: '37');
  final _bpController = TextEditingController(text: '118/75');
  final _symptomController = TextEditingController();
  final _durationController = TextEditingController();
  final _severityController = TextEditingController();
  final _weightController = TextEditingController(text: '58');



  // State
  double _painLevel = 4;
  bool _loading = false;
  String? _error;
  AnalysisResult? _result;
  bool _showTechnical = false;
  double _weight = 58.0;

  // Speech
  final _speech = SpeechToText();
  bool _speechReady = false;
  bool _listening = false;
  TextEditingController? _activeController;
  String _listeningLabel = '';

  // Tab controller for result sections
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    _speechReady = await _speech.initialize(
      onError: (_) => setState(() => _listening = false),
      onStatus: (s) {
        if (s == 'done' || s == 'notListening') {
          setState(() => _listening = false);
        }
      },
    );
    setState(() {});
  }

  void _startListening(TextEditingController controller, String label) async {
    if (!_speechReady) return;
    setState(() {
      _listening = true;
      _activeController = controller;
      _listeningLabel = label;
    });
    await _speech.listen(
      onResult: (result) {
        if (result.finalResult) {
          setState(() {
            controller.text = result.recognizedWords;
            _listening = false;
          });
        }
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 4),
      localeId: 'en_US',
    );
  }

  void _stopListening() {
    _speech.stop();
    setState(() => _listening = false);
  }

  Future<void> _runAnalysis() async {
    if (_symptomController.text.trim().isEmpty) {
      setState(() => _error = 'Please enter a primary symptom');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
      _result = null;
    });

    try {
      final res = await http.post(
        Uri.parse('https://dismed.vercel.app/api/check-symptoms'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'description': _descController.text.trim(),
          'temperature_celsius': double.tryParse(_tempController.text) ?? 37,
          'bp': _bpController.text.trim(),
          'primarySymptom': _symptomController.text.trim(),
          'duration': _durationController.text.trim(),
          'severity': _severityController.text.trim(),
          'pain_scale': _painLevel.round(),
          'weight':  _weight,
        }),
      );

      if (res.statusCode == 200) {
        setState(() => _result = AnalysisResult.fromJson(jsonDecode(res.body)));
      } else {
        final body = jsonDecode(res.body);
        setState(() => _error = body['error'] ?? 'Analysis failed');
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _descController.dispose();
    _tempController.dispose();
    _bpController.dispose();
    _symptomController.dispose();
    _durationController.dispose();
    _severityController.dispose();
    _speech.cancel();
    super.dispose();
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('AI Symptom Checker', style: GoogleFonts.roboto(fontWeight: FontWeight.bold)),
        bottom: _result != null
            ? TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Input'),
                  Tab(text: 'Results'),
                ],
              )
            : null,
      ),
      body: _result != null
          ? TabBarView(controller: _tabController, children: [_buildForm(), _buildResults()])
          : _buildForm(),
    );
  }

  // ── Form ──────────────────────────────────────────────────────────────────

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Speech listening banner
          if (_listening) _ListeningBanner(label: _listeningLabel, onStop: _stopListening),

          // Info card
          _InfoCard(),
          const SizedBox(height: 16),

          // Vitals row
          Text(
            'Current Vitals',
            style: GoogleFonts.roboto(
              textStyle: context.textTheme.titleMedium,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _VoiceField(
                      controller: _tempController,
                      label: 'Temperature (°C)',
                      icon: Icons.thermostat_rounded,
                      keyboardType: TextInputType.number,
                      speechReady: _speechReady,
                      listening: _listening && _activeController == _tempController,
                      onMicTap: () => _startListening(_tempController, 'Temperature'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _VoiceField(
                      controller: _bpController,
                      label: 'Blood Pressure',
                      icon: Icons.favorite_rounded,
                      speechReady: _speechReady,
                      listening: _listening && _activeController == _bpController,
                      onMicTap: () => _startListening(_bpController, 'Blood Pressure'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              Row(
                children: [
                  Expanded(
                    child: _VoiceField(
                      controller: _weightController,
                      label: 'Weight (Kg)',
                      icon: Icons.thermostat_rounded,
                      keyboardType: TextInputType.number,
                      
                      speechReady: _speechReady,
                      listening: _listening && _activeController == _tempController,
                      onMicTap: () => _startListening(_tempController, 'Temperature'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Expanded(
                  //   child: _VoiceField(
                  //     controller: _bpController,
                  //     label: 'Blood Pressure',
                  //     icon: Icons.favorite_rounded,
                  //     speechReady: _speechReady,
                  //     listening: _listening && _activeController == _bpController,
                  //     onMicTap: () => _startListening(_bpController, 'Blood Pressure'),
                  //   ),
                  // ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Primary symptom
          Text(
            'Symptoms',
            style: GoogleFonts.roboto(
              textStyle: context.textTheme.titleMedium,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          _VoiceField(
            controller: _symptomController,
            label: 'Primary Symptom',
            hint: 'e.g. Persistent headache, nausea…',
            icon: Icons.sick_rounded,
            speechReady: _speechReady,
            listening: _listening && _activeController == _symptomController,
            onMicTap: () => _startListening(_symptomController, 'Primary Symptom'),
          ),
          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: _VoiceField(
                  controller: _durationController,
                  label: 'Duration',
                  hint: 'e.g. 2 days',
                  icon: Icons.schedule_rounded,
                  speechReady: _speechReady,
                  listening: _listening && _activeController == _durationController,
                  onMicTap: () => _startListening(_durationController, 'Duration'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _VoiceField(
                  controller: _severityController,
                  label: 'Severity',
                  hint: 'Mild / Moderate / Severe',
                  icon: Icons.signal_cellular_alt_rounded,
                  speechReady: _speechReady,
                  listening: _listening && _activeController == _severityController,
                  onMicTap: () => _startListening(_severityController, 'Severity'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Pain scale
          Text(
            'Pain Level',
            style: GoogleFonts.roboto(
              textStyle: context.textTheme.titleMedium,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          _PainSlider(value: _painLevel, onChanged: (v) => setState(() => _painLevel = v)),
          const SizedBox(height: 14),

          // Description
          Text(
            'Additional Details',
            style: GoogleFonts.roboto(
              textStyle: context.textTheme.titleMedium,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Stack(
            children: [
              TextField(
                controller: _descController,
                maxLines: 4,
                style: GoogleFonts.roboto(),
                decoration: InputDecoration(
                  hintText: 'Describe your symptoms in more detail…',
                  hintStyle: GoogleFonts.roboto(
                    textStyle: context.textTheme.bodySmall?.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                  filled: true,
                  fillColor: context.colors.surface,
                  contentPadding: const EdgeInsets.fromLTRB(20, 16, 56, 16),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                ),
              ),
              Positioned(
                right: 8,
                top: 8,
                child: _MicButton(
                  speechReady: _speechReady,
                  listening: _listening && _activeController == _descController,
                  onTap: () => _startListening(_descController, 'Description'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Error
          if (_error != null)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: context.colors.errorContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    color: context.colors.onErrorContainer,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error!,
                      style: GoogleFonts.roboto(color: context.colors.onErrorContainer),
                    ),
                  ),
                ],
              ),
            ),

          // Submit button
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: context.colors.secondaryContainer,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            onPressed: _loading ? null : _runAnalysis,
            icon: _loading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: context.colors.onSecondaryContainer,
                    ),
                  )
                : Icon(Icons.bolt_rounded, color: context.colors.onSecondaryContainer),
            label: Text(
              _loading ? 'Analysing…' : 'Run AI Health Analysis',
              style: GoogleFonts.roboto(
                color: context.colors.onSecondaryContainer,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ── Results ───────────────────────────────────────────────────────────────

  Widget _buildResults() {
    if (_result == null) return const SizedBox.shrink();
    final r = _result!;
    final colors = _riskColors(context, r.riskLevel);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Risk banner
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: colors['bg'], borderRadius: BorderRadius.circular(20)),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: colors['fg']!.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.warning_amber_rounded, color: colors['fg'], size: 26),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${r.riskLevel} Risk',
                        style: GoogleFonts.roboto(
                          color: colors['fg'],
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                      Text(
                        'Confidence: ${r.certaintyScore}',
                        style: GoogleFonts.roboto(
                          color: colors['fg']!.withOpacity(0.8),
                          textStyle: context.textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Detected indicators
          Text(
            'Detected Indicators',
            style: GoogleFonts.roboto(
              textStyle: context.textTheme.titleMedium,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          ...r.detectedIndicators.map(
            (ind) => Card(
              margin: const EdgeInsets.only(bottom: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.circle, size: 10, color: context.colors.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            ind.indicator,
                            style: GoogleFonts.roboto(
                              fontWeight: FontWeight.bold,
                              textStyle: context.textTheme.bodyLarge,
                            ),
                          ),
                        ),
                        if (ind.status.isNotEmpty)
                          Chip(
                            label: Text(ind.status, style: GoogleFonts.roboto(fontSize: 11)),
                            backgroundColor: context.colors.secondaryContainer,
                            padding: EdgeInsets.zero,
                          ),
                      ],
                    ),
                    if (ind.recommendedAction.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 12,
                            color: context.colors.onSurfaceVariant,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              ind.recommendedAction,
                              style: GoogleFonts.roboto(
                                textStyle: context.textTheme.bodySmall,
                                color: context.colors.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Technical analysis accordion
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(
                'Technical Analysis',
                style: GoogleFonts.roboto(fontWeight: FontWeight.w600),
              ),
              leading: Icon(Icons.biotech_rounded, color: context.colors.primary),
              initiallyExpanded: _showTechnical,
              onExpansionChanged: (v) => setState(() => _showTechnical = v),
              children: [
                Text(
                  r.technicalAnalysis.clinicalReasoning,
                  style: GoogleFonts.roboto(textStyle: context.textTheme.bodyMedium),
                ),
                if (r.technicalAnalysis.differentialConsiderations.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Differential Considerations',
                    style: GoogleFonts.roboto(
                      fontWeight: FontWeight.bold,
                      textStyle: context.textTheme.labelLarge,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ...r.technicalAnalysis.differentialConsiderations.map(
                    (d) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('• ', style: GoogleFonts.roboto(color: context.colors.primary)),
                          Expanded(
                            child: Text(
                              d,
                              style: GoogleFonts.roboto(textStyle: context.textTheme.bodySmall),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: context.colors.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    r.disclaimer,
                    style: GoogleFonts.roboto(
                      textStyle: context.textTheme.bodySmall,
                      fontStyle: FontStyle.italic,
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Disclaimer
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.colors.tertiaryContainer.withOpacity(0.4),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: context.colors.tertiary.withOpacity(0.3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded, color: context.colors.tertiary, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'This is AI-generated analysis for informational purposes only. Always consult a qualified healthcare professional.',
                    style: GoogleFonts.roboto(
                      textStyle: context.textTheme.bodySmall,
                      color: context.colors.onTertiaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Run again button
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            onPressed: () => _tabController.animateTo(0),
            icon: Icon(Icons.refresh_rounded, color: context.colors.primary),
            label: Text(
              'New Analysis',
              style: GoogleFonts.roboto(color: context.colors.primary, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ── Supporting widgets ────────────────────────────────────────────────────────

class _VoiceField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData icon;
  final TextInputType keyboardType;
  final bool speechReady;
  final bool listening;
  final VoidCallback onMicTap;

  const _VoiceField({
    required this.controller,
    required this.label,
    this.hint,
    required this.icon,
    this.keyboardType = TextInputType.text,
    required this.speechReady,
    required this.listening,
    required this.onMicTap,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: GoogleFonts.roboto(textStyle: context.textTheme.labelLarge),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: GoogleFonts.roboto(
          textStyle: context.textTheme.bodySmall?.copyWith(color: context.colors.onSurfaceVariant),
        ),
        filled: true,
        fillColor: listening
            ? context.colors.primaryContainer.withOpacity(0.3)
            : context.colors.surface,
        prefixIcon: Icon(icon, color: listening ? context.colors.primary : null),
        suffixIcon: speechReady
            ? _MicButton(speechReady: speechReady, listening: listening, onTap: onMicTap)
            : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(
            color: listening ? context.colors.primary : context.colors.outlineVariant,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: context.colors.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
    );
  }
}

class _MicButton extends StatelessWidget {
  final bool speechReady;
  final bool listening;
  final VoidCallback onTap;

  const _MicButton({required this.speechReady, required this.listening, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AvatarGlow(
      animate: listening,
      glowColor: context.colors.primary,
      duration: const Duration(milliseconds: 1500),
      repeat: true,
      child: GestureDetector(
        onTap: speechReady ? onTap : null,
        child: CircleAvatar(
          radius: 18,
          backgroundColor: listening ? context.colors.primary : context.colors.primaryContainer,
          child: Icon(
            listening ? Icons.mic_rounded : Icons.mic_none_rounded,
            size: 18,
            color: listening ? context.colors.onPrimary : context.colors.primary,
          ),
        ),
      ),
    );
  }
}

class _ListeningBanner extends StatelessWidget {
  final String label;
  final VoidCallback onStop;

  const _ListeningBanner({required this.label, required this.onStop});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: context.colors.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          AvatarGlow(
            animate: true,
            glowColor: context.colors.primary,
            duration: const Duration(milliseconds: 1200),
            repeat: true,
            child: CircleAvatar(
              radius: 14,
              backgroundColor: context.colors.primary,
              child: Icon(Icons.mic_rounded, size: 16, color: context.colors.onPrimary),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Listening…',
                  style: GoogleFonts.roboto(
                    fontWeight: FontWeight.bold,
                    color: context.colors.onPrimaryContainer,
                  ),
                ),
                Text(
                  'Speak your $label',
                  style: GoogleFonts.roboto(
                    textStyle: context.textTheme.bodySmall,
                    color: context.colors.onPrimaryContainer.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onStop,
            child: Text(
              'Stop',
              style: GoogleFonts.roboto(color: context.colors.primary, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

class _PainSlider extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;

  const _PainSlider({required this.value, required this.onChanged});

  Color _sliderColor(double v) {
    if (v <= 3) return Colors.green;
    if (v <= 6) return Colors.orange;
    return Colors.red;
  }

  String _painLabel(double v) {
    if (v <= 2) return 'No Pain';
    if (v <= 4) return 'Mild';
    if (v <= 6) return 'Moderate';
    if (v <= 8) return 'Severe';
    return 'Unbearable';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Pain Scale',
                  style: GoogleFonts.roboto(textStyle: context.textTheme.bodyMedium),
                ),
                Row(
                  children: [
                    Text(
                      '${value.round()}/10',
                      style: GoogleFonts.roboto(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: _sliderColor(value),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Chip(
                      label: Text(_painLabel(value), style: GoogleFonts.roboto(fontSize: 11)),
                      backgroundColor: _sliderColor(value).withOpacity(0.15),
                      side: BorderSide(color: _sliderColor(value).withOpacity(0.4)),
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ],
            ),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: _sliderColor(value),
                thumbColor: _sliderColor(value),
                overlayColor: _sliderColor(value).withOpacity(0.2),
              ),
              child: Slider(value: value, min: 0, max: 10, divisions: 10, onChanged: onChanged),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: ['No Pain', 'Moderate', 'Unbearable']
                  .map(
                    (l) => Text(
                      l,
                      style: GoogleFonts.roboto(
                        textStyle: context.textTheme.labelSmall,
                        color: context.colors.onSurfaceVariant,
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.colors.tertiaryContainer.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.tertiary.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: context.colors.tertiary, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.roboto(
                  textStyle: context.textTheme.bodySmall,
                  color: context.colors.onTertiaryContainer,
                ),
                children: const [
                  TextSpan(
                    text: 'Clinical Note: ',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(
                    text:
                        'This tool is for information only. If you are experiencing chest pain, difficulty breathing, or sudden numbness, call emergency services immediately.',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
