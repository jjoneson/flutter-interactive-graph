import 'package:flutter/material.dart';

class LineGraphCrosshairPainter extends CustomPainter {
  LineGraphCrosshairPainter(
      {required this.context,
      required this.points,
      required this.cursorPosition,
      required this.labels})
      : super();

  final BuildContext context;
  final List<Offset> points;
  final Offset cursorPosition;
  final List<String> labels;

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = Theme.of(context).primaryColor
      ..strokeWidth = 3.0
      ..style = PaintingStyle.fill;

    for (int i = 0; i < points.length; i++) {
      var point = points[i];
      var nextPoint = points[(i + 1) % points.length];
      if (i == points.length - 1) {
        nextPoint = points.last;
      }
      if (cursorPosition.dx >= point.dx && cursorPosition.dx <= nextPoint.dx) {
        var onlinePoint = getPointOnLine(point, nextPoint, cursorPosition.dx);
        var labelIndex = (onlinePoint.dx > point.dx) ? i + 1 : i;
        drawCrosshair(canvas, paint, size, onlinePoint, labels[labelIndex]);
        break;
      }
    }
  }

  void drawCrosshair(
      Canvas canvas, Paint paint, Size size, Offset point, String label) {
    drawCrosshairCircle(canvas, paint, point);
    drawCrosshairLine(canvas, paint, size, point);
    drawCrosshairLabel(canvas, point, label);
  }

  void drawCrosshairCircle(Canvas canvas, Paint paint, Offset point) {
    canvas.drawCircle(Offset(point.dx, point.dy), 6, paint);
  }

  void drawCrosshairLabel(Canvas canvas, Offset point, String label) {
    TextPainter textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: const TextStyle(
          backgroundColor: Colors.white,
          color: Colors.black,
          fontSize: 14.0,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    Offset textOffset;
    if (point.dx + textPainter.width > points.last.dx) {
      textOffset = Offset(point.dx - textPainter.width, point.dy - textPainter.height / 2 - 36);
    } else {
      textOffset = Offset(point.dx, point.dy - textPainter.height / 2 - 24);
    }

    textPainter.paint(
        canvas,
       textOffset);
  }

  void drawCrosshairLine(Canvas canvas, Paint paint, Size size, Offset point) {
    canvas.drawLine(
        Offset(point.dx, size.height), Offset(point.dx, point.dy + 5), paint);
  }

  @override
  bool shouldRepaint(LineGraphCrosshairPainter oldDelegate) {
    return true;
  }

  // Given two points and an x coordinate, return a new point on the line between the two points
  Offset getPointOnLine(Offset point1, Offset point2, double x) {
    if (point1.dx == point2.dx) {
      return Offset(point1.dx, point1.dy);
    }

    double y =
        (point2.dy - point1.dy) / (point2.dx - point1.dx) * (x - point1.dx) +
            point1.dy;
    return Offset(x, y);
  }
}
