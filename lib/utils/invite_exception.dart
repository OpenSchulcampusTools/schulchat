class InviteException implements Exception {
  final String reason;

  InviteException(this.reason);

  @override
  String toString() => reason;
}
