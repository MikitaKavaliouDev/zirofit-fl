import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zirofit_fl/data/models/testimonial.dart';
import 'package:zirofit_fl/features/trainer/providers/trainer_profile_provider.dart';

class TrainerTestimonialsScreen extends ConsumerStatefulWidget {
  const TrainerTestimonialsScreen({super.key});

  @override
  ConsumerState<TrainerTestimonialsScreen> createState() =>
      _TrainerTestimonialsScreenState();
}

class _TrainerTestimonialsScreenState
    extends ConsumerState<TrainerTestimonialsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(trainerProfileProvider.notifier).fetchProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(trainerProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Testimonials'),
        actions: [
          TextButton.icon(
            onPressed: () => _showAddTestimonialDialog(context),
            icon: const Icon(Icons.add, size: 20),
            label: const Text('Add'),
          ),
        ],
      ),
      body: state.isLoading && state.testimonials.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : state.testimonials.isEmpty
              ? _buildEmptyState(theme)
              : _buildTestimonialsList(theme, state.testimonials),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.format_quote,
            size: 64,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'No testimonials yet',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Add testimonials from your clients or request a review',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => _showAddTestimonialDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('Add Testimonial'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => _showRequestReviewDialog(context),
            icon: const Icon(Icons.send),
            label: const Text('Request Review from Client'),
          ),
        ],
      ),
    );
  }

  Widget _buildTestimonialsList(ThemeData theme, List<Testimonial> testimonials) {
    return RefreshIndicator(
      onRefresh: () => ref.read(trainerProfileProvider.notifier).fetchProfile(),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${testimonials.length} testimonial${testimonials.length == 1 ? '' : 's'}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _showRequestReviewDialog(context),
                  icon: const Icon(Icons.send, size: 16),
                  label: const Text('Request Review'),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: testimonials.length,
              itemBuilder: (context, index) {
                final testimonial = testimonials[index];
                return _TestimonialCard(
                  testimonial: testimonial,
                  onDelete: () => _showDeleteConfirmation(context, testimonial),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Add Testimonial Dialog
  // ---------------------------------------------------------------------------

  void _showAddTestimonialDialog(BuildContext context) {
    final clientNameController = TextEditingController();
    final testimonialTextController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    int rating = 5;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Testimonial'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: clientNameController,
                    decoration: const InputDecoration(
                      labelText: 'Client Name *',
                      hintText: 'John Doe',
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: testimonialTextController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Testimonial *',
                      hintText: 'What did the client say?',
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Text(
                        'Rating:',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(width: 12),
                      ...List.generate(5, (index) {
                        return IconButton(
                          icon: Icon(
                            index < rating
                                ? Icons.star
                                : Icons.star_border,
                            color: Colors.amber,
                          ),
                          onPressed: () {
                            setDialogState(() {
                              rating = index + 1;
                            });
                          },
                        );
                      }),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState?.validate() ?? false) {
                  final data = {
                    'clientName': clientNameController.text,
                    'testimonialText': testimonialTextController.text,
                    'rating': rating,
                  };
                  ref
                      .read(trainerProfileProvider.notifier)
                      .addTestimonial(data);
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Request Review Dialog
  // ---------------------------------------------------------------------------

  void _showRequestReviewDialog(BuildContext context) {
    final clientEmailController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Request Review'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Send a review request to a client.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: clientEmailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Client Email',
                  hintText: 'client@example.com',
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  if (!v.contains('@')) return 'Enter a valid email';
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                ref
                    .read(trainerProfileProvider.notifier)
                    .requestTestimonialReview(clientEmailController.text);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Review request sent to client'),
                  ),
                );
              }
            },
            icon: const Icon(Icons.send, size: 18),
            label: const Text('Send Request'),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Delete Confirmation
  // ---------------------------------------------------------------------------

  void _showDeleteConfirmation(
      BuildContext context, Testimonial testimonial) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Testimonial'),
        content: Text(
          'Are you sure you want to delete this testimonial from ${testimonial.clientName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              ref
                  .read(trainerProfileProvider.notifier)
                  .deleteTestimonial(testimonial.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content:
                      Text('Testimonial from ${testimonial.clientName} deleted'),
                ),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Testimonial Card
// ---------------------------------------------------------------------------

class _TestimonialCard extends StatelessWidget {
  final Testimonial testimonial;
  final VoidCallback onDelete;

  const _TestimonialCard({
    required this.testimonial,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Text(
                    testimonial.clientName.isNotEmpty
                        ? testimonial.clientName[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        testimonial.clientName,
                        style: theme.textTheme.titleMedium,
                      ),
                      if (testimonial.rating != null)
                        Row(
                          children: List.generate(
                            testimonial.rating!,
                            (index) => const Icon(
                              Icons.star,
                              size: 14,
                              color: Colors.amber,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.delete_outline,
                    color: theme.colorScheme.error,
                  ),
                  onPressed: onDelete,
                  tooltip: 'Delete',
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              testimonial.testimonialText,
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
