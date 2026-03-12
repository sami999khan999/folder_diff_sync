class EnvEntry {
  final String rawLine;
  final String? key;
  final String? value;
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
    if (isBlank) return '';
    if (isComment) return rawLine;
    if (hideValues) return '$key=';
    return '$key=$value';
  }
}
