import 'package:flutter/material.dart';
import 'package:flutter_interactive_graph/widgets/line_graph/line_graph_crosshair_painter.dart';
import 'package:flutter_interactive_graph/widgets/line_graph/line_graph_painter.dart';

import 'line_graph_label_painter.dart';

class LineGraphWidget extends StatefulWidget {
  final Map<num, num> values;
  final List<String> labels;
  final bool enableZooming;
  final bool enablePanning;
  final Size size;

  const LineGraphWidget({
    Key? key,
    required this.values,
    required this.size,
    required this.labels,
    this.enableZooming = false,
    this.enablePanning = false,
  }) : super(key: key);

  @override
  _LineGraphWidgetState createState() => _LineGraphWidgetState();
}

class _LineGraphWidgetState extends State<LineGraphWidget> {
  late Size _size;
  Offset _offset = Offset.zero;
  Offset _initialFocalPoint = Offset.zero;
  Offset _sessionOffset = Offset.zero;
  double _scale = 1.0;
  double _initialScale = 1.0;
  Offset _cursorPosition = Offset.zero;

  @override
  Widget build(BuildContext context) {
    _size = widget.size;

    var currentOffset = _offset + _sessionOffset;
    currentOffset = Offset(
        currentOffset.dx.clamp(_scale * _size.width * -1 + _size.width, 0),
        currentOffset.dy.clamp(0, 0));

    var scaled = _scaleValues(widget.values, _size, currentOffset);
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(children: [
        Align(
          alignment: const Alignment(-1.0, -1.0),
          child: _buildPrimaryGraph(context, _size, currentOffset, scaled),
        ),
      ]),
    );
  }

  GestureDetector _buildPrimaryGraph(BuildContext context, Size size,
      Offset currentOffset, List<Offset> scaled) {
    return GestureDetector(
      onPanUpdate: (details) {
        setState(() {
          for (var i = 1; i < scaled.length; i++) {
            var midpoint = (scaled[i - 1].dx + scaled[i].dx) / 2;
            if (details.localPosition.dx > midpoint &&
                details.localPosition.dx < scaled[i].dx) {
              _cursorPosition = scaled[i];
              break;
            } else if (details.localPosition.dx < midpoint &&
                details.localPosition.dx > scaled[i - 1].dx) {
              _cursorPosition = scaled[i - 1];
              break;
            }
          }
        });
      },
      behavior: HitTestBehavior.translucent,
      child: Stack(children: [
        CustomPaint(
          painter: LineGraphPainter(context: context, points: scaled),
          size: size,
        ),
        CustomPaint(
          painter: LineGraphCrosshairPainter(
              context: context, points: scaled, cursorPosition: _cursorPosition, labels: widget.labels),
          size: size,
        ),
        CustomPaint(
          painter: LineGraphLabelPainter(
              points: scaled, cursorPosition: _cursorPosition, labels: widget.labels),
          size: size,
        ),
      ]),
    );
  }

  List<Offset> _scaleValues(Map<num, num> values, Size size, Offset offset) {
    num minY = values.values.reduce((previousValue, element) =>
        previousValue.compareTo(element) > 0 ? previousValue : element);

    num maxY = values.values.reduce((previousValue, element) =>
        previousValue.compareTo(element) < 0 ? previousValue : element);

    num maxX = values.keys.reduce((previousValue, element) =>
        previousValue.compareTo(element) > 0 ? previousValue : element);

    num minX = values.keys.reduce((previousValue, element) =>
        previousValue.compareTo(element) < 0 ? previousValue : element);

    return values.entries.map((entry) {
      var x =
          _scaleValue(entry.key, minX, maxX, size.width * _scale) + offset.dx;
      var y = size.height * 0.95 -
          _scaleValue(entry.value, minY/2, maxY * 1.5, size.height * 0.8);
      return Offset(x, y);
    }).toList();
  }

  double _scaleValue(num value, num min, num max, double size) {
    return (value - min) / (max - min) * size;
  }

  void _onScaleStart(ScaleStartDetails details) {
    if (widget.enableZooming == false) return;
    _initialFocalPoint = details.localFocalPoint;
    _initialScale = _scale;
    setState(() {
      _cursorPosition = details.localFocalPoint;
    });
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    if (widget.enableZooming == false) return;
    setState(() {
      _scale = _initialScale * details.scale;
      _scale = _scale.clamp(1, 5);
      _sessionOffset = details.localFocalPoint - _initialFocalPoint;

      _cursorPosition = details.localFocalPoint;
    });
  }

  void _onScaleEnd(ScaleEndDetails details) {
    if (widget.enableZooming == false) return;
    setState(() {
      _offset += _sessionOffset;
      _offset = Offset(
          _offset.dx.clamp(_scale * _size.width * -1 + _size.width, 0),
          _offset.dy.clamp(0, 0));
      _sessionOffset = Offset.zero;
    });
  }
}
