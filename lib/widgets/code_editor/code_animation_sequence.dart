class CodeAnimationSequence {
  CodeAnimationSequence({required this.animations, required this.duration});

  final List<CodeAnimationEvent> animations;
  final Duration duration;
}

class CodeAnimationEvent {
  int lineNumber;
  int columnNumber;
  int length;

  CodeAnimationEvent(this.lineNumber, this.columnNumber, this.length);
}
