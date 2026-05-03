import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zirofit_fl/features/ai_coach/providers/ai_coach_provider.dart';

class AiCoachScreen extends ConsumerStatefulWidget {
  const AiCoachScreen({super.key});

  @override
  ConsumerState<AiCoachScreen> createState() => _AiCoachScreenState();
}

class _AiCoachScreenState extends ConsumerState<AiCoachScreen> {
  final _goalController = TextEditingController();
  final _refineController = TextEditingController();

  @override
  void dispose() {
    _goalController.dispose();
    _refineController.dispose();
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

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(aiCoachProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Coach'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
                'What\'s your fitness goal?',
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
      ),
    );
  }
}
