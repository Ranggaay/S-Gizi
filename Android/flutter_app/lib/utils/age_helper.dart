class AgeParts {
  const AgeParts({
    required this.years,
    required this.months,
    required this.days,
  });

  final int years;
  final int months;
  final int days;

  String get yearsMonthsLabel {
    if (years <= 0) return '$months Bulan';
    if (months <= 0) return '$years Tahun';
    return '$years Tahun $months Bulan';
  }
}

AgeParts calculateAgeParts(DateTime birthDate, DateTime referenceDate) {
  var years = referenceDate.year - birthDate.year;
  var months = referenceDate.month - birthDate.month;
  var days = referenceDate.day - birthDate.day;

  if (days < 0) {
    months -= 1;
    final previousMonth = DateTime(referenceDate.year, referenceDate.month, 0);
    days += previousMonth.day;
  }

  if (months < 0) {
    years -= 1;
    months += 12;
  }

  if (years < 0) {
    return const AgeParts(years: 0, months: 0, days: 0);
  }

  return AgeParts(years: years, months: months, days: days);
}

String formatAgeFromDates(DateTime birthDate, DateTime referenceDate) {
  return calculateAgeParts(birthDate, referenceDate).yearsMonthsLabel;
}

String formatAgeFromDateStrings(
  String rawBirthDate, {
  String? onDate,
  String source = 'unknown',
}) {
  final birthDate = DateTime.tryParse(rawBirthDate);
  final referenceDate = DateTime.tryParse(onDate ?? '') ?? DateTime.now();
  if (birthDate == null) return '-';
  return formatAgeFromDates(birthDate, referenceDate);
}

int wholeDaysBetween(DateTime from, DateTime to) {
  final start = DateTime(from.year, from.month, from.day);
  final end = DateTime(to.year, to.month, to.day);
  return end.difference(start).inDays;
}
