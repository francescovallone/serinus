extension NullIfEmpty on String? {
  String? get nullIfEmpty => (this?.isEmpty ?? true) ? null : this;
}
