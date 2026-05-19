import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zirofit_fl/features/ai_coach/providers/ai_coach_provider.dart';
import 'package:zirofit_fl/features/ai_coach/widgets/coaching_bubble.dart';

class AiCoachScreen extends ConsumerStatefulWidget {
  /// Optional workout session ID for live coaching during an active workout.
  final String? workoutSessionId;

  const AiCoachScreen({super.key, this.workoutSessionId});

  @override
  ConsumerState<AiCoachScreen> createState() => _AiCoachScreenState();
}

class _AiCoachScreenState extends ConsumerState<AiCoachScreen> {
  final _goalController = TextEditingController();
  final _refineController = TextEditingController();
  final _textInputController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isLiveMode = false;

  @override
  void initState() {
    super.initState();
    // If a workout session ID is provided, start in live coaching mode.
    if (widget.workoutSessionId != null) {
      _isLiveMode = true;
      Future.microtask(() {
        ref
            .read(aiCoachProvider.notifier)
            .startCoaching(widget.workoutSessionId!);
      });
    }
  }

  @override
  void dispose() {
    _goalController.dispose();
    _refineController.dispose();
    _textInputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _generate() {
    final goal = _goalController.text.trim();
    if (goal.isEmpty) return;
    ref.read(aiCoachProvider.notifier).generateProgram(goal);
  }

  void _refine() {
    final input = _refineController.text.trim();
    if (input.isEmpty) return;
    ref.read(aiCoachProvider.notifier).refineProgram(input);
    _refineController.clear();
  }

  void _sendTextInput() {
    final text = _textInputController.text.trim();
    if (text.isEmpty) return;
    _textInputController.clear();
    ref.read(aiCoachProvider.notifier).processTextInput(text);
  }

  void _enterLiveMode() {
    setState(() => _isLiveMode = true);
  }

  void _exitLiveMode() {
    ref.read(aiCoachProvider.notifier).stopCoaching();
    setState(() => _isLiveMode = false);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(aiCoachProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isLiveMode ? 'Live Coach' : 'AI Coach'),
        actions: [
          if (_isLiveMode)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: _exitLiveMode,
              tooltip: 'Exit live coaching',
            ),
        ],
      ),
      body: _isLiveMode ? _buildLiveMode(theme, state) : _buildStandardMode(theme, state),
    );
  }

  // ---------------------------------------------------------------------------
  // Standard mode (existing functionality)
  // ---------------------------------------------------------------------------

  Widget _buildStandardMode(ThemeData theme, AICoachState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 'Live Coach' button
          if (state.generatedProgram != null) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: FilledButton.icon(
                onPressed: _enterLiveMode,
                icon: const Icon(Icons.mic),
                label: const Text('Live Coach'),
              ),
            ),
          ],

          // -- Error banner --
          if (state.error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                state.error!,
                style: TextStyle(
                  color: theme.colorScheme.error,
                  fontSize: 14,
                ),
              ),
            ),

          // -- Goal input section --
          if (state.generatedProgram == null) ...[
            Text(
              "What's your fitness goal?",
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Describe your goal in detail — include your experience level, '
              'available equipment, training frequency, and any preferences.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _goalController,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: 'e.g. I want to build muscle and strength...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: state.isLoading ? null : _generate,
              child: state.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Generate Program'),
            ),
          ],

          // -- Results section --
          if (state.generatedProgram != null) ...[
            // The generated program
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: SelectableText(
                state.generatedProgram!,
                style: theme.textTheme.bodyLarge,
              ),
            ),
            const SizedBox(height: 16),

            // Loading indicator for refine
            if (state.isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: CircularProgressIndicator()),
              ),

            // Refine input
            Text(
              'Refine your program',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _refineController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'e.g. Add more leg exercises, reduce cardio...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: state.isLoading ? null : _refine,
              child: const Text('Refine Program'),
            ),

            const SizedBox(height: 16),

            // Start over
            TextButton(
              onPressed: () {
                ref.read(aiCoachProvider.notifier).reset();
                _goalController.clear();
                _refineController.clear();
              },
              child: const Text('Start Over'),
            ),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Live coaching mode
  // ---------------------------------------------------------------------------

  Widget _buildLiveMode(ThemeData theme, AICoachState state) {
    return Column(
      children: [
        // Coaching conversation history
        Expanded(
          child: state.coachResponses.isEmpty
              ? _buildEmptyLiveState(theme)
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: state.coachResponses.length,
                  itemBuilder: (context, index) {
                    final isLatest =
                        index == state.coachResponses.length - 1;
                    return CoachingBubble(
                      result: state.coachResponses[index],
                      isLatest: isLatest,
                    );
                  },
                ),
        ),

        // Processing indicator
        if (state.isProcessing)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: LinearProgressIndicator(),
          ),

        // Error banner
        if (state.error != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: theme.colorScheme.errorContainer,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    state.error!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onErrorContainer,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.close,
                    size: 18,
                    color: theme.colorScheme.onErrorContainer,
                  ),
                  onPressed: () =>
                      ref.read(aiCoachProvider.notifier).clearError(),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),

        // Input area
        _buildLiveInputBar(theme, state),
      ],
    );
  }

  Widget _buildEmptyLiveState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.auto_awesome,
            size: 64,
            color: theme.colorScheme.primary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'AI Coach Ready',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Speak or type to get coaching feedback',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveInputBar(ThemeData theme, AICoachState state) {
    return Container(
      padding: EdgeInsets.only(
        left: 12,
        right: 8,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        children: [
          // Mic button
          IconButton(
            onPressed: state.isProcessing
                ? null
                : () {
                    ref.read(aiCoachProvider.notifier).setListening(
                          !state.isListening,
                        );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          state.isListening
                              ? 'Voice input disabled'
                              : 'Voice input enabled — speak now',
                        ),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
            icon: Icon(
              state.isListening ? Icons.mic : Icons.mic_none,
              color: state.isListening
                  ? Colors.red
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),

          // Text input
          Expanded(
            child: TextField(
              controller: _textInputController,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendTextInput(),
              decoration: InputDecoration(
                hintText: 'Ask the coach...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Send button
          IconButton(
            onPressed: state.isProcessing ? null : _sendTextInput,
            icon: state.isProcessing
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: theme.colorScheme.primary,
                    ),
                  )
                : Icon(Icons.send_rounded, color: theme.colorScheme.primary),
          ),
        ],
      ),
    );
  }
}
