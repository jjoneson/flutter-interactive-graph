import 'package:flutter/material.dart';
import 'package:flutter_interactive_graph/model/display_status.dart';
import 'package:flutter_interactive_graph/model/node.dart';
import 'package:path_drawing/path_drawing.dart';

import 'graph_node.dart';

class EdgePainter extends CustomPainter {
  EdgePainter(
      {required this.nodes,
      required this.origin,
      required this.scale,
      required this.context})
      : super();

  final List<GraphNodeWidget> nodes;
  final Offset origin;
  final double scale;
  final BuildContext context;
  double weight = 0.08;

  @override
  void paint(Canvas canvas, Size size) {
    const double dashSize = 10;
    const double gapSize = 4;

    for (var node in nodes) {
      for (var edge in node.graphNode!.outgoingEdges) {
        if (edge.displayStatus == DisplayStatus.hidden) {
          continue;
        }

        final start = (edge.sourceAnchor.offset + origin) * scale;
        final end = (edge.targetAnchor.offset + origin) * scale;

        final paint = Paint()
          ..color = Theme.of(context).primaryColorLight.withOpacity(edge.getOpacity())
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.0 * scale;

        Offset mid = (start + (end - start) / 8);

        GraphNode sourceNode = edge.sourceAnchor.node;
        GraphNode targetNode = edge.targetAnchor.node;

        Path path = orthogonalPath(start, end, mid, 10,
            sourceNode.size.height * scale, targetNode.size.height * scale);
        path = dashPath(path,
            dashArray: CircularIntervalList<double>([dashSize, gapSize]));
        canvas.drawPath(path, paint);
      }
    }
  }

  Path orthogonalPath(Offset start, Offset end, Offset mid, double padding,
      double sourceHeight, double targetHeight) {
    var curveDelta1 = padding;
    if ((start.dy - mid.dy).abs() < curveDelta1 * 4) {
      curveDelta1 = (start.dy - mid.dy).abs() / 4;
    }

    var curveDelta2 = padding;
    if ((end.dy - mid.dy).abs() < curveDelta2 * 4) {
      curveDelta2 = (end.dy - mid.dy).abs() / 4;
    }

    final startX1 = start.dx + padding;
    final startX2 = start.dx + padding * 2;
    final startX3 = start.dx + padding * 3;

    final endX1 = end.dx - padding;
    final endX2 = end.dx - padding * 2;
    final endX3 = end.dx - padding * 3;

    var midCurveStartX1 = startX2;
    var midCurveStartX2 = startX3;

    var midCurveEndX1 = endX3;
    var midCurveEndX2 = endX2;

    var scaledPadding =
        ((end.dx - padding * 2) - (start.dx + padding * 2)).abs() / 2;
    if ((start.dx - end.dx).abs() < padding * 6) {
      midCurveStartX2 = startX2 - scaledPadding / 4;
      midCurveEndX1 = endX2 + scaledPadding / 4;
    } else if (start.dx > end.dx - padding * 3) {
      midCurveStartX2 = startX2 - padding;
      midCurveEndX1 = endX2 + padding;
    }

    if (start.dy > mid.dy) {
      curveDelta1 = -curveDelta1;
    }
    if (end.dy < mid.dy) {
      curveDelta2 = -curveDelta2;
    }

    return Path()
      ..moveTo(start.dx, start.dy)
      ..lineTo(startX1, start.dy)
      ..quadraticBezierTo(startX2, start.dy, startX2, start.dy + curveDelta1)
      ..lineTo(startX2, mid.dy - curveDelta1)
      ..quadraticBezierTo(midCurveStartX1, mid.dy, midCurveStartX2, mid.dy)
      ..lineTo(midCurveEndX1, mid.dy)
      ..quadraticBezierTo(
          midCurveEndX2, mid.dy, midCurveEndX2, mid.dy + curveDelta2)
      ..lineTo(midCurveEndX2, end.dy - curveDelta2)
      ..quadraticBezierTo(endX2, end.dy, endX1, end.dy)
      ..lineTo(end.dx, end.dy);
  }

  @override
  bool shouldRepaint(EdgePainter oldDelegate) {
    return true;
  }
}
