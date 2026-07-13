import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/baby_gender.dart';
import '../utils/baby_theme.dart';
import 'profile_provider.dart';

/// Live preview while picking gender in onboarding/profile.
final previewBabyGenderProvider =
    NotifierProvider<PreviewBabyGenderNotifier, BabyGender?>(
  PreviewBabyGenderNotifier.new,
);

class PreviewBabyGenderNotifier extends Notifier<BabyGender?> {
  @override
  BabyGender? build() => null;

  void set(BabyGender? gender) => state = gender;

  void clear() => state = null;
}

final activeBabyGenderProvider = Provider<BabyGender?>((ref) {
  final preview = ref.watch(previewBabyGenderProvider);
  if (preview != null) return preview;
  return ref.watch(profileProvider).profile?.babyGender;
});

final babyThemePaletteProvider = Provider<BabyThemePalette?>((ref) {
  final gender = ref.watch(activeBabyGenderProvider);
  return babyThemePaletteFor(gender);
});
