class StatItem {
  final String label;
  final String value;
  final String description;

  const StatItem({
    required this.label,
    required this.value,
    required this.description,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StatItem &&
          runtimeType == other.runtimeType &&
          label == other.label &&
          value == other.value &&
          description == other.description;

  @override
  int get hashCode => label.hashCode ^ value.hashCode ^ description.hashCode;
}
