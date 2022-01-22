import 'package:flutter/material.dart';
import 'package:tuple/tuple.dart';

class LineGraphPainter extends CustomPainter {
  LineGraphPainter({required this.context, required this.points}) : super();

  final List<Offset> points;
  final BuildContext context;

  @override
  void paint(Canvas canvas, Size size) {
    // Paint background = Paint()
    //   ..shader = const LinearGradient(
    //       colors: [Color.fromARGB(255, 88, 160, 120),Color.fromARGB(200, 48, 120, 80),],
    //       begin: Alignment.topCenter,
    //       end: Alignment.bottomCenter)
    //       .createShader(Rect.fromLTRB(size.width/2, size.height/2, size.width/2, size.height))
    //   ..style = PaintingStyle.fill
    //   ..strokeWidth = 1.0;
    //
    // canvas.drawRect(Rect.fromLTRB(0, 0, size.width, size.height), background);


    Paint fill = Paint()
      ..shader = LinearGradient(
          colors: [Theme.of(context).primaryColorLight, Theme.of(context).primaryColorLight],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter)
          .createShader(Rect.fromLTRB(0, points.last.dy, size.width, points.first.dy))
      ..style = PaintingStyle.fill;

    Paint topLine= Paint()
      ..color = Theme.of(context).primaryColor
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke;

    Path topLinePath = Path();

    Path path = Path()..fillType = PathFillType.evenOdd;
    const weight = 0.45;

    path.moveTo(0, size.height);
    path.lineTo(points.first.dx, points.first.dy);
    topLinePath.moveTo(points.first.dx, points.first.dy);

    for (int i = 0; i < points.length; i++) {
      Offset point = points[i];
      if (i == 0) {
        path.lineTo(point.dx, point.dy);
        topLinePath.lineTo(point.dx, point.dy);
      } else {
        Offset controlPoint1 =
        controlPoint(point, points[i - 1], const Tuple2(weight, weight));
        Offset controlPoint2 = controlPoint(
            point, points[i - 1], const Tuple2(1 - weight, 1 - weight));
        path.cubicTo(controlPoint1.dx, controlPoint1.dy, controlPoint2.dx,
            controlPoint2.dy, point.dx, point.dy);
        topLinePath.cubicTo(controlPoint1.dx, controlPoint1.dy, controlPoint2.dx,
            controlPoint2.dy, point.dx, point.dy);
      }
    }

    path.lineTo(points.last.dx, points.last.dy);
    topLinePath.lineTo(points.last.dx, points.last.dy);

    path.lineTo(size.width, size.height);

    canvas.drawPath(path, fill);
    canvas.drawPath(topLinePath, topLine);
  }

  Offset controlPoint(
      Offset previousPoint, Offset point, Tuple2<double, double> weight) {
    return smoothControlPoint(Offset(point.dx, previousPoint.dy),
        Offset(previousPoint.dx, point.dy), weight);
  }

  Offset smoothControlPoint(
      Offset point1, Offset point2, Tuple2<double, double> weight) {
    return Offset(point1.dx + (point2.dx - point1.dx) * weight.item1,
        point1.dy + (point2.dy - point1.dy) * weight.item2);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
