import 'package:flutter/material.dart';

class LineGraphLabelPainter extends CustomPainter {
  LineGraphLabelPainter({required this.points, required this.cursorPosition, required this.labels})
      : super();

  final List<Offset> points;
  final List<String> labels;
  final Offset cursorPosition;
  static const height = 10.0;

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    canvas.drawLine(Offset(points.first.dx, size.height),
        Offset(points.last.dx, size.height), paint);

    for (int i = 0; i < points.length - 1; i++) {
      canvas.drawLine(Offset(points[i].dx, size.height),
          Offset(points[i].dx + height/2, size.height - height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
