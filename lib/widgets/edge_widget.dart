import 'package:flutter/cupertino.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_interactive_graph/model/graph.dart';

import 'edge_painter.dart';
import 'graph_node.dart';

class EdgeWidget extends StatefulWidget {
  Graph graph;
  BuildContext context;
  Size size;
  bool animate;

  EdgeWidget({Key? key, required this.graph, required this.context, required this.size, this.animate = false})
      : super(key: key);

  @override
  _EdgeWidgetState createState() => _EdgeWidgetState();
}

class _EdgeWidgetState extends State<EdgeWidget> with SingleTickerProviderStateMixin {
  AnimationController? _edgePulseController;
  Animation? _edgePulseAnimation;

  @override
  initState() {
    super.initState();
    // if (widget.animate) {
      _edgePulseController = AnimationController(duration: const Duration(milliseconds: 2000), vsync: this);
      _edgePulseAnimation = Tween(begin: 0.0, end: 1.0).animate(_edgePulseController!)
        ..addListener(() {
          setState(() {
            // repeat the animation if it is at the end
            if (_edgePulseAnimation!.status == AnimationStatus.completed) {
              _edgePulseController!.reverse();
            } else if (_edgePulseAnimation!.status == AnimationStatus.dismissed) {
              _edgePulseController!.forward();
            }
          });
        });
      _edgePulseController!.forward();
    // }
  }

  @override
  void dispose() {
    _edgePulseController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return
      // Flow(delegate: FlowEdgeDelegate(postFrameCallback: () => setState(() { })), children: [
      CustomPaint(
        size: widget.size,
        painter: EdgePainter(graph: widget.graph, context: context, pulsePosition: _edgePulseAnimation?.value ?? 0.0),
      // )]
    );
  }
}

class FlowEdgeDelegate extends FlowDelegate {
  void Function() postFrameCallback;

  FlowEdgeDelegate({required this.postFrameCallback});

  @override
  void paintChildren(FlowPaintingContext context) {
    for (int i = 0; i < context.childCount; i++) {
      context.paintChild(i, transform: Matrix4.identity());
    }
    context.paintChild(context.childCount, transform: Matrix4.identity());
    SchedulerBinding.instance!.addPostFrameCallback((Duration timeStamp) {
      postFrameCallback();
    });
  }

  @override
  bool shouldRepaint(FlowDelegate oldDelegate) {
    return true;
  }
}
