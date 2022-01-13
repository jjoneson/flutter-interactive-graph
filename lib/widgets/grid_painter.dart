import 'package:flutter/material.dart';

class GridPainter extends CustomPainter {
  GridPainter({required this.context, required this.scale, required this.origin}) : super();

  final BuildContext context;
  final double scale;
  final Offset origin;

  @override
  void paint(Canvas canvas, Size size) {
    double eWidth = 100*scale;
    double eHeight = 100*scale;

    //Grid background
    var paint = Paint()..isAntiAlias = true;

    //Grid style
    paint
      ..style = PaintingStyle.stroke //line
      ..color = Theme.of(context).dividerColor.withOpacity(0.05)
      ..strokeWidth = 1.1;

    for (int i = 0; i <= 100/scale; ++i) {
      double dy = eHeight * i;
      canvas.drawLine(Offset(0, dy), Offset(size.width, dy), paint);
    }

    for (int i = 0; i <= 100/scale; ++i) {
      double dx = eWidth * i;
      canvas.drawLine(Offset(dx, 0), Offset(dx, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
