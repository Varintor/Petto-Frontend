class PetAgeFormatter {
  const PetAgeFormatter._();

  static String english(DateTime? birthday, {DateTime? now}) {
    if (birthday == null) return 'Not set';
    final today = now ?? DateTime.now();
    var years = today.year - birthday.year;
    var months = today.month - birthday.month;
    if (today.day < birthday.day) months -= 1;
    if (months < 0) {
      years -= 1;
      months += 12;
    }
    if (years <= 0) {
      return months <= 0 ? 'Less than 1 month' : '$months months';
    }
    return months == 0 ? '$years years' : '$years years $months months';
  }
}
