class EnvEntry {
  final String rawLine;
  String? key;
  String? value;
  final bool isComment;
  final bool isBlank;

  EnvEntry({
    required this.rawLine,
    this.key,
    this.value,
    this.isComment = false,
    this.isBlank = false,
  });

  String toOutputLine({bool hideValues = false}) {
    if (isBlank || isComment || key == null) return rawLine;
    if (hideValues) {
      final eqIndex = rawLine.indexOf('=');
      if (eqIndex >= 0) {
        return '${rawLine.substring(0, eqIndex + 1)}********';
      }
    }
    return rawLine;
  }
}
