import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_interactive_graph/widgets/code_editor/code_animation_sequence.dart';

class CodeEditorAnimationOverlay extends StatefulWidget {
  GlobalKey codeEditorKey;
  double charWidth;
  double charHeight;
  double topPadding;
  double charactersPerLine;
  double scale;
  CodeAnimationSequence animationSequence;

  CodeEditorAnimationOverlay({
    Key? key,
    required this.codeEditorKey,
    required this.charWidth,
    required this.charHeight,
    required this.topPadding,
    required this.charactersPerLine,
    required this.scale,
    required this.animationSequence,
  }) : super(key: key);

  @override
  _CodeEditorAnimationOverlayState createState() =>
      _CodeEditorAnimationOverlayState();
}

class _CodeEditorAnimationOverlayState
    extends State<CodeEditorAnimationOverlay> with SingleTickerProviderStateMixin {
  AnimationController? _controller;
  Animation<double>? _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.animationSequence.duration,
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0,
      end: widget.animationSequence.animations.length.toDouble(),
    ).animate(_controller!);
    _controller?.forward();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _CodeEditorAnimationOverlayPainter(
        codeEditorKey: widget.codeEditorKey,
        charWidth: widget.charWidth,
        charHeight: widget.charHeight,
        topPadding: widget.topPadding,
        charactersPerLine: widget.charactersPerLine,
        scale: widget.scale,
        animationSequence: widget.animationSequence,
        animation: _animation,
      ),
    );
    return Container();
  }
}

class _CodeEditorAnimationOverlayPainter extends CustomPainter {
  GlobalKey codeEditorKey;
  double charWidth;
  double charHeight;
  double topPadding;
  double charactersPerLine;
  double scale;
  CodeAnimationSequence animationSequence;
  Animation<double>? animation;

  _CodeEditorAnimationOverlayPainter({
    required this.codeEditorKey,
    required this.charWidth,
    required this.charHeight,
    required this.topPadding,
    required this.charactersPerLine,
    required this.scale,
    required this.animationSequence,
    required this.animation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (animation == null) {
      return;
    }
    final codeEditor = codeEditorKey.currentContext?.findRenderObject() as RenderBox;
    // final codeEditorSize = codeEditor.size;
    final codeEditorOffset = codeEditor.localToGlobal(Offset.zero);

    var animationEvent = animationSequence.animations[animation!.value.floor().toInt()];
    var targetCharacterNumber = animationEvent.lineNumber * charactersPerLine + animationEvent.columnNumber;
    var targetCharacterOffset = Offset(
      (targetCharacterNumber % charactersPerLine) * charWidth,
      (targetCharacterNumber ~/ charactersPerLine) * charHeight,
    );

    var targetCharacterPosition = codeEditorOffset + targetCharacterOffset * scale;
    var targetCharacterSize = Size(charWidth * scale, charHeight * scale);

    var paint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    canvas.drawRect(
      Rect.fromLTWH(
        targetCharacterPosition.dx,
        targetCharacterPosition.dy,
        targetCharacterSize.width,
        targetCharacterSize.height,
      ),
      paint,
    );

  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
