import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zirofit_fl/features/voice_coach/voice_coach_provider.dart';

// =============================================================================
// Voice Coach Settings Screen
//
// iOS-aligned settings screen matching VoiceSettingsView.swift:
//   - Voice mode picker (Command Dictation / Conversational AI Coach)
//   - Active coach card with gender/accent badges
//   - Fine-tuning sliders (stability, clarity, speed)
//   - Available voices grid with selection
// =============================================================================

class VoiceCoachSettingsScreen extends ConsumerStatefulWidget {
  const VoiceCoachSettingsScreen({super.key});

  @override
  ConsumerState<VoiceCoachSettingsScreen> createState() =>
      _VoiceCoachSettingsScreenState();
}

class _VoiceCoachSettingsScreenState
    extends ConsumerState<VoiceCoachSettingsScreen> {
  static const Color _indigo = Color(0xFF4F46E5);

  // Track which voice is currently "previewing" (decorative play icon)
  String? _previewingVoiceId;

  @override
  void initState() {
    super.initState();
    // Simulate loading voices (in production, this would call an API)
    Future.microtask(() => _loadVoices());
  }

  Future<void> _loadVoices() async {
    final manager = ref.read(voiceCoachProvider.notifier);
    manager.setLoadingVoices();

    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 600));

    // Seed with sample voices matching ElevenLabs style
    final sampleVoices = [
      const VoiceModel(
        voiceId: 'rachel',
        name: 'Rachel',
        description: 'Warm, professional, and clear',
        labels: VoiceLabels(gender: 'female', accent: 'american'),
        category: 'professional',
        previewUrl: null,
      ),
      const VoiceModel(
        voiceId: 'antoni',
        name: 'Antoni',
        description: 'Deep, resonant, and authoritative',
        labels: VoiceLabels(gender: 'male', accent: 'british'),
        category: 'professional',
        previewUrl: null,
      ),
      const VoiceModel(
        voiceId: 'bella',
        name: 'Bella',
        description: 'Soft, friendly, and motivating',
        labels: VoiceLabels(gender: 'female', accent: 'american'),
        category: 'motivational',
        previewUrl: null,
      ),
      const VoiceModel(
        voiceId: 'elli',
        name: 'Elli',
        description: 'Youthful, energetic, and upbeat',
        labels: VoiceLabels(gender: 'female', accent: 'american'),
        category: 'energetic',
        previewUrl: null,
      ),
      const VoiceModel(
        voiceId: 'domi',
        name: 'Domi',
        description: 'Athletic, bold, and intense',
        labels: VoiceLabels(gender: 'male', accent: 'american'),
        category: 'energetic',
        previewUrl: null,
      ),
      const VoiceModel(
        voiceId: 'patrick',
        name: 'Patrick',
        description: 'Calm, precise, and instructional',
        labels: VoiceLabels(gender: 'male', accent: 'british'),
        category: 'professional',
        previewUrl: null,
      ),
    ];

    manager.setVoices(sampleVoices);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(voiceCoachProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Coach Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 24),
        children: [
          // ── Voice Mode Selection ──
          _buildModeSection(context, theme, state),

          const SizedBox(height: 24),

          // ── Dictation Explanation or Active Coach Card / Sliders ──
          if (state.voiceMode == VoiceMode.dictation)
            _buildDictationExplanation(theme)
          else ...[
            // Active AI Coach Card
            if (state.selectedVoice != null)
              _buildActiveCoachCard(context, theme, state.selectedVoice!),

            const SizedBox(height: 24),

            // Voice Fine-Tuning
            _buildFineTuningSection(theme, state),

            const SizedBox(height: 24),

            // Available Voices
            _buildAvailableVoicesSection(theme, state),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Voice Mode Section
  // ---------------------------------------------------------------------------

  Widget _buildModeSection(
    BuildContext context,
    ThemeData theme,
    VoiceCoachState state,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Active Voice Feature',
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              // Command Dictation card
              _ModeCard(
                isSelected: state.voiceMode == VoiceMode.dictation,
                icon: Icons.list_alt_rounded,
                iconColor: Colors.blue,
                selectedColor: Colors.blue,
                title: 'Command Dictation',
                subtitle: 'Log exercises, weight, and reps via speech',
                onTap: () {
                  ref.read(voiceCoachProvider.notifier).setVoiceMode(
                        VoiceMode.dictation,
                      );
                },
              ),
              const SizedBox(height: 12),
              // Conversational AI Coach card
              _ModeCard(
                isSelected: state.voiceMode == VoiceMode.coach,
                icon: Icons.auto_awesome,
                iconColor: _indigo,
                selectedColor: _indigo,
                title: 'Conversational AI Coach',
                subtitle: 'Verbal advice and motivation from an AI coach',
                onTap: () {
                  ref.read(voiceCoachProvider.notifier).setVoiceMode(
                        VoiceMode.coach,
                      );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Dictation Mode Explanation
  // ---------------------------------------------------------------------------

  Widget _buildDictationExplanation(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            const Icon(
              Icons.list_alt_rounded,
              size: 48,
              color: Colors.blue,
            ),
            const SizedBox(height: 12),
            Text(
              'Command Dictation',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Log your workout entirely hands-free using quick, on-device '
              'voice commands. Simply say your exercise, weight, and reps '
              'during a set, or speak to manage rest timers.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TRY SAYING SENTENCES LIKE:',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const _ExampleRow(text: 'Bench press 80 kg for 8 reps'),
                  const SizedBox(height: 8),
                  const _ExampleRow(text: 'Start rest for 90 seconds'),
                  const SizedBox(height: 8),
                  const _ExampleRow(text: 'Repeat last set'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Active Coach Card
  // ---------------------------------------------------------------------------

  Widget _buildActiveCoachCard(
    BuildContext context,
    ThemeData theme,
    VoiceModel voice,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              'ACTIVE AI COACH',
              style: theme.textTheme.labelSmall?.copyWith(
                color: _indigo,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              voice.name,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (voice.description != null) ...[
              const SizedBox(height: 8),
              Text(
                voice.description!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                if (voice.labels?.gender != null)
                  _Badge(
                    text: voice.labels!.gender!,
                    color: Colors.blue,
                  ),
                if (voice.labels?.accent != null)
                  _Badge(
                    text: voice.labels!.accent!,
                    color: Colors.purple,
                  ),
                if (voice.category != null)
                  _Badge(
                    text: voice.category!,
                    color: Colors.orange,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Fine-Tuning Sliders
  // ---------------------------------------------------------------------------

  Widget _buildFineTuningSection(ThemeData theme, VoiceCoachState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Voice Fine-Tuning',
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                // Stability slider
                _SliderRow(
                  label: 'Stability',
                  value: state.voiceSettings.stability,
                  displayValue: '${(state.voiceSettings.stability * 100).round()}%',
                  min: 0.0,
                  max: 1.0,
                  divisions: 100,
                  hint: 'Lower values are more expressive; higher values are more consistent.',
                  onChanged: (v) {
                    ref.read(voiceCoachProvider.notifier).setStability(v);
                  },
                ),
                const Divider(height: 32),
                // Clarity & Similarity slider
                _SliderRow(
                  label: 'Clarity & Similarity',
                  value: state.voiceSettings.similarityBoost,
                  displayValue:
                      '${(state.voiceSettings.similarityBoost * 100).round()}%',
                  min: 0.0,
                  max: 1.0,
                  divisions: 100,
                  hint: 'Controls how closely the model matches the original speaker\'s accent and clarity.',
                  onChanged: (v) {
                    ref
                        .read(voiceCoachProvider.notifier)
                        .setSimilarityBoost(v);
                  },
                ),
                const Divider(height: 32),
                // Speed slider
                _SliderRow(
                  label: 'Speaking Speed',
                  value: state.voiceSettings.speed,
                  displayValue: '${state.voiceSettings.speed.toStringAsFixed(2)}x',
                  min: 0.5,
                  max: 2.0,
                  divisions: 150,
                  hint: null,
                  onChanged: (v) {
                    ref.read(voiceCoachProvider.notifier).setSpeed(v);
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Available Voices Grid
  // ---------------------------------------------------------------------------

  Widget _buildAvailableVoicesSection(ThemeData theme, VoiceCoachState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Text(
                'Available Voices',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Tap to preview',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (state.isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (state.voices.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Text(
                'No voices available',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          )
        else
          ...state.voices.map(
            (voice) => _VoiceCard(
              voice: voice,
              isSelected: voice.voiceId == state.selectedVoiceId,
              isPreviewing: _previewingVoiceId == voice.voiceId,
              onTap: () {
                ref
                    .read(voiceCoachProvider.notifier)
                    .selectVoice(voice.voiceId);
              },
              onPreviewTap: () {
                setState(() {
                  if (_previewingVoiceId == voice.voiceId) {
                    _previewingVoiceId = null;
                  } else {
                    _previewingVoiceId = voice.voiceId;
                  }
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Preview coming soon'),
                    duration: Duration(seconds: 1),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

// =============================================================================
// Sub-widgets
// =============================================================================

/// A selectable card for picking voice mode (dictation / coach).
class _ModeCard extends StatelessWidget {
  final bool isSelected;
  final IconData icon;
  final Color iconColor;
  final Color selectedColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ModeCard({
    required this.isSelected,
    required this.icon,
    required this.iconColor,
    required this.selectedColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? selectedColor.withValues(alpha: 0.8)
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected ? selectedColor : iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: isSelected ? Colors.white : iconColor),
            ),
            const SizedBox(width: 16),
            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Checkmark / circle
            if (isSelected)
              Icon(Icons.check_circle, color: selectedColor, size: 22)
            else
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Example command row used in dictation explanation.
class _ExampleRow extends StatelessWidget {
  final String text;
  const _ExampleRow({required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        const Icon(Icons.chat_bubble_outline_rounded, size: 14, color: Colors.blue),
        const SizedBox(width: 8),
        Text(
          text,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

/// A small colored badge (gender, accent, category).
class _Badge extends StatelessWidget {
  final String text;
  final Color color;
  const _Badge({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text[0].toUpperCase() + text.substring(1).toLowerCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}

/// A labeled slider row with value display.
class _SliderRow extends StatelessWidget {
  final String label;
  final double value;
  final String displayValue;
  final double min;
  final double max;
  final int? divisions;
  final String? hint;
  final ValueChanged<double> onChanged;

  const _SliderRow({
    required this.label,
    required this.value,
    required this.displayValue,
    required this.min,
    required this.max,
    this.divisions,
    this.hint,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            Text(
              displayValue,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: const Color(0xFF4F46E5),
            thumbColor: const Color(0xFF4F46E5),
            overlayColor: const Color(0xFF4F46E5).withValues(alpha: 0.12),
            inactiveTrackColor:
                theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.12),
          ),
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
        if (hint != null)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              hint!,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
            ),
          ),
      ],
    );
  }
}

/// A single voice card in the available voices list.
class _VoiceCard extends StatelessWidget {
  final VoiceModel voice;
  final bool isSelected;
  final bool isPreviewing;
  final VoidCallback onTap;
  final VoidCallback onPreviewTap;

  const _VoiceCard({
    required this.voice,
    required this.isSelected,
    required this.isPreviewing,
    required this.onTap,
    required this.onPreviewTap,
  });

  static const Color _indigo = Color(0xFF4F46E5);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? _indigo.withValues(alpha: 0.5)
                  : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              // Selection dot
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? _indigo
                        : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? Center(
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: _indigo,
                          ),
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              // Voice info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      voice.name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (voice.description != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        voice.description!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Preview button
              GestureDetector(
                onTap: onPreviewTap,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _indigo.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isPreviewing ? Icons.stop : Icons.play_arrow_rounded,
                    size: 16,
                    color: isPreviewing ? Colors.red : _indigo,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
