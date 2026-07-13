enum BabyGender {
  girl,
  boy,
  unknown;

  static BabyGender? fromApi(String? value) {
    switch (value) {
      case 'girl':
        return BabyGender.girl;
      case 'boy':
        return BabyGender.boy;
      case 'unknown':
        return BabyGender.unknown;
      default:
        return null;
    }
  }

  String get apiValue {
    switch (this) {
      case BabyGender.girl:
        return 'girl';
      case BabyGender.boy:
        return 'boy';
      case BabyGender.unknown:
        return 'unknown';
    }
  }

  String get label {
    switch (this) {
      case BabyGender.girl:
        return 'Girl';
      case BabyGender.boy:
        return 'Boy';
      case BabyGender.unknown:
        return 'Surprise!';
    }
  }

  String get emoji {
    switch (this) {
      case BabyGender.girl:
        return '💗';
      case BabyGender.boy:
        return '💙';
      case BabyGender.unknown:
        return '✨';
    }
  }

  String get hint {
    switch (this) {
      case BabyGender.girl:
        return 'Soft rose & blush tones';
      case BabyGender.boy:
        return 'Bold ocean blues';
      case BabyGender.unknown:
        return 'Golden plum & sparkle';
    }
  }
}

class BabyGenderOption {
  final BabyGender value;
  final String label;
  final String emoji;
  final String hint;

  const BabyGenderOption({
    required this.value,
    required this.label,
    required this.emoji,
    required this.hint,
  });
}

const babyGenderOptions = [
  BabyGenderOption(
    value: BabyGender.girl,
    label: 'Girl',
    emoji: '💗',
    hint: 'Soft rose & blush tones',
  ),
  BabyGenderOption(
    value: BabyGender.boy,
    label: 'Boy',
    emoji: '💙',
    hint: 'Bold ocean blues',
  ),
  BabyGenderOption(
    value: BabyGender.unknown,
    label: 'Surprise!',
    emoji: '✨',
    hint: 'Golden plum & sparkle',
  ),
];
