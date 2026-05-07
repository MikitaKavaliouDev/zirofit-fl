import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zirofit_fl/data/models/text_content.dart';
import 'package:zirofit_fl/features/trainer/providers/trainer_text_content_provider.dart';

class EditProfileTextScreen extends ConsumerStatefulWidget {
  const EditProfileTextScreen({super.key});

  @override
  ConsumerState<EditProfileTextScreen> createState() =>
      _EditProfileTextScreenState();
}

class _EditProfileTextScreenState
    extends ConsumerState<EditProfileTextScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _bioController;
  late TextEditingController _philosophyController;
  late TextEditingController _methodologyController;
  late TextEditingController _certificationsController;
  late TextEditingController _qualificationsController;

  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _bioController = TextEditingController();
    _philosophyController = TextEditingController();
    _methodologyController = TextEditingController();
    _certificationsController = TextEditingController();
    _qualificationsController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(trainerTextContentProvider.notifier).fetchTextContent();
    });
  }

  @override
  void dispose() {
    _bioController.dispose();
    _philosophyController.dispose();
    _methodologyController.dispose();
    _certificationsController.dispose();
    _qualificationsController.dispose();
    super.dispose();
  }

  void _syncControllersFromState(TextContent? textContent) {
    if (textContent == null || _initialized) return;
    _bioController.text = textContent.aboutMe ?? '';
    _philosophyController.text = textContent.philosophy ?? '';
    _methodologyController.text = textContent.methodology ?? '';
    _certificationsController.text = textContent.certifications ?? '';
    _qualificationsController.text = textContent.qualifications ?? '';
    _initialized = true;
  }

  void _onFieldChanged(String field, String value) {
    ref.read(trainerTextContentProvider.notifier).updateField(field, value);
  }

  Future<void> _onSave() async {
    if (!_formKey.currentState!.validate()) return;

    final notifier = ref.read(trainerTextContentProvider.notifier);

    // Sync latest text from controllers to provider
    notifier.updateField('aboutMe', _bioController.text);
    notifier.updateField('philosophy', _philosophyController.text);
    notifier.updateField('methodology', _methodologyController.text);
    notifier.updateField('certifications', _certificationsController.text);
    notifier.updateField('qualifications', _qualificationsController.text);

    await notifier.saveTextContent();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(trainerTextContentProvider);

    // Sync controllers from state data once loaded
    _syncControllersFromState(state.textContent);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile Text'),
        actions: [
          _SaveButton(
            isSaving: state.isSaving,
            onSave: _onSave,
          ),
        ],
      ),
      body: _buildBody(theme, state),
    );
  }

  Widget _buildBody(ThemeData theme, TrainerTextContentState state) {
    if (state.isLoading && state.textContent == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.textContent == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                state.error!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => ref
                    .read(trainerTextContentProvider.notifier)
                    .fetchTextContent(),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Form(
      key: _formKey,
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: RefreshIndicator(
          onRefresh: () => ref
              .read(trainerTextContentProvider.notifier)
              .fetchTextContent(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Success message
                if (state.successMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              state.successMessage!,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Error message
                if (state.error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error,
                            color: theme.colorScheme.onErrorContainer,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              state.error!,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onErrorContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // About Me / Bio
                _TextSectionCard(
                  title: 'About Me / Bio',
                  icon: Icons.person_outline,
                  maxLength: 500,
                  controller: _bioController,
                  onChanged: (v) => _onFieldChanged('aboutMe', v),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Bio cannot be empty';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Philosophy
                _TextSectionCard(
                  title: 'Philosophy',
                  icon: Icons.lightbulb_outline,
                  maxLength: 500,
                  controller: _philosophyController,
                  onChanged: (v) => _onFieldChanged('philosophy', v),
                ),
                const SizedBox(height: 16),

                // Methodology
                _TextSectionCard(
                  title: 'Methodology',
                  icon: Icons.school_outlined,
                  maxLength: 500,
                  controller: _methodologyController,
                  onChanged: (v) => _onFieldChanged('methodology', v),
                ),
                const SizedBox(height: 16),

                // Certifications
                _TextSectionCard(
                  title: 'Certifications',
                  icon: Icons.verified_outlined,
                  controller: _certificationsController,
                  onChanged: (v) => _onFieldChanged('certifications', v),
                ),
                const SizedBox(height: 16),

                // Qualifications
                _TextSectionCard(
                  title: 'Qualifications',
                  icon: Icons.card_membership_outlined,
                  controller: _qualificationsController,
                  onChanged: (v) => _onFieldChanged('qualifications', v),
                ),
                const SizedBox(height: 32),

                // Bottom save button
                FilledButton.icon(
                  onPressed: state.isSaving ? null : _onSave,
                  icon: state.isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save),
                  label: Text(state.isSaving ? 'Saving...' : 'Save All'),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// SaveButton (AppBar action)
// ---------------------------------------------------------------------------

class _SaveButton extends StatelessWidget {
  final bool isSaving;
  final VoidCallback onSave;

  const _SaveButton({
    required this.isSaving,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: isSaving ? null : onSave,
      icon: isSaving
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.check),
      tooltip: 'Save',
    );
  }
}

// ---------------------------------------------------------------------------
// TextSectionCard
// ---------------------------------------------------------------------------

class _TextSectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final int? maxLength;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final FormFieldValidator<String>? validator;

  const _TextSectionCard({
    required this.title,
    required this.icon,
    this.maxLength,
    required this.controller,
    required this.onChanged,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: theme.textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: controller,
              maxLines: 5,
              maxLength: maxLength,
              decoration: InputDecoration(
                hintText: 'Enter $title...',
                border: const OutlineInputBorder(),
                counterText: maxLength != null
                    ? '${controller.text.length}/${maxLength!}'
                    : null,
              ),
              onChanged: onChanged,
              validator: validator,
            ),
          ],
        ),
      ),
    );
  }
}
