import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/data/models/transformation_photo_pair.dart';
import 'package:zirofit_fl/features/trainer/providers/trainer_transformation_photos_provider.dart';
import 'package:zirofit_fl/features/trainer/screens/trainer_transformation_photos_screen.dart';
import '../../helpers/test_setup.dart';

/// Fake notifier that tracks state synchronously without HTTP.
class FakeTP extends TrainerTransformationPhotosNotifier {
  TrainerTransformationPhotosState _s;
  FakeTP(this._s) : super(apiClient: ApiClient.instance) {
    super.state = _s;
  }

  @override
  TrainerTransformationPhotosState get state => _s;

  void emit(TrainerTransformationPhotosState ns) {
    _s = ns;
    super.state = ns;
  }

  @override
  Future<void> fetchPhotos() async {}

  @override
  Future<String?> uploadPhotos({
    required String beforeImagePath,
    required String afterImagePath,
    String? caption,
    DateTime? date,
  }) async {
    final pair = TransformationPhotoPair(
      id: 'new-${DateTime.now().millisecondsSinceEpoch}',
      beforeImageUrl: beforeImagePath,
      afterImageUrl: afterImagePath,
      caption: caption,
      createdAt: date ?? DateTime.now(),
    );
    emit(state.copyWith(photos: [...state.photos, pair]));
    return null;
  }

  @override
  Future<void> deletePhoto(String id) async {
    emit(state.copyWith(
      photos: state.photos.where((p) => p.id != id).toList(),
    ));
  }
}

Widget buildTestApp(TrainerTransformationPhotosState state) => ProviderScope(
      overrides: [
        trainerTransformationPhotosProvider
            .overrideWith((ref) => FakeTP(state)),
      ],
      child: const MaterialApp(
        home: TrainerTransformationPhotosScreen(),
      ),
    );

TransformationPhotoPair makePair({
  String id = '1',
  String beforeUrl = 'https://example.com/before.jpg',
  String afterUrl = 'https://example.com/after.jpg',
  String? caption = '12-week transformation',
}) =>
    TransformationPhotoPair(
      id: id,
      beforeImageUrl: beforeUrl,
      afterImageUrl: afterUrl,
      caption: caption,
      createdAt: DateTime(2024, 6, 15),
    );

void main() {
  setUpAll(() => configureTestApiClient());

  group('TrainerTransformationPhotosScreen', () {
    testWidgets('Test 1: Shows photo grid', (tester) async {
      final photos = [
        makePair(id: '1', caption: 'Client A'),
        makePair(id: '2', caption: 'Client B'),
      ];
      final state = TrainerTransformationPhotosState(
        photos: photos,
        isLoading: false,
      );

      await tester.pumpWidget(buildTestApp(state));
      await tester.pumpAndSettle();

      expect(find.text('Client A'), findsOneWidget);
      expect(find.text('Client B'), findsOneWidget);
      expect(find.text('Transformation Photos'), findsOneWidget);
    });

    testWidgets('Test 4: Empty state when no photos', (tester) async {
      const state = TrainerTransformationPhotosState(
        photos: [],
        isLoading: false,
      );

      await tester.pumpWidget(buildTestApp(state));
      await tester.pumpAndSettle();

      expect(
        find.text('No transformation photos yet'),
        findsOneWidget,
      );
      expect(find.text('Add Photos'), findsOneWidget);
    });

    testWidgets('Test 2: Add flow shows dialog', (tester) async {
      const state = TrainerTransformationPhotosState(
        photos: [],
        isLoading: false,
      );

      await tester.pumpWidget(buildTestApp(state));
      await tester.pumpAndSettle();

      // Tap the "Add" button in AppBar
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      // Dialog should appear
      expect(
        find.text('Add Transformation Photos'),
        findsOneWidget,
      );
      expect(find.text('Before Photo *'), findsOneWidget);
      expect(find.text('After Photo *'), findsOneWidget);
      expect(find.text('Upload'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('Test 3: Delete confirms and removes', (tester) async {
      final pair = makePair(
        id: '1',
        caption: 'To Delete',
      );
      final state = TrainerTransformationPhotosState(
        photos: [pair],
        isLoading: false,
      );

      await tester.pumpWidget(buildTestApp(state));
      await tester.pumpAndSettle();

      // Verify photo card exists
      expect(find.text('To Delete'), findsOneWidget);

      // Tap delete icon
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      // Confirmation dialog should appear
      expect(find.text('Delete Photos'), findsOneWidget);

      // Confirm delete
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pumpAndSettle();

      // Photo should be removed
      expect(find.text('To Delete'), findsNothing);
      // Should show empty state now
      expect(
        find.text('No transformation photos yet'),
        findsOneWidget,
      );
    });
  });
}
