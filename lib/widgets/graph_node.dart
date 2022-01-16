import 'package:flutter_interactive_graph/model/node.dart';
import 'package:flutter/material.dart';

class GraphNodeWidget extends StatefulWidget {
  const GraphNodeWidget(
      {Key? key,
      this.graphNode,
      required this.topMargin,
      required this.scale,
      required this.origin,
      required this.child,
      required this.pop,
      required this.childKey,
      this.notify})
      : super(key: key);

  final GraphNode? graphNode;
  final num topMargin;
  final double scale;
  final Offset origin;
  final Widget child;
  final Function(String nodeId) pop;
  final VoidCallback? notify;
  final GlobalKey childKey;

  @override
  State<GraphNodeWidget> createState() => _GraphNodeWidgetState();
}

class _GraphNodeWidgetState extends State<GraphNodeWidget> {

  @override
  Widget build(BuildContext context) {
    return
      Flex(
    direction: Axis.vertical,
    mainAxisSize: MainAxisSize.min,
    children:[
    Transform(
          transform: Matrix4.identity()..scale(widget.scale, widget.scale, 1.0),
          child: GestureDetector(
            behavior: HitTestBehavior.deferToChild,
            onPanUpdate: (details) {
              setState(() {
                widget.graphNode!.translate(Offset(
                    details.delta.dx,
                    details.delta.dy), widget.graphNode!.size);
                widget.pop(widget.graphNode!.id);
                widget.notify?.call();
              });
            },
            child: widget.child,
          ),
        )]);
  }
}
