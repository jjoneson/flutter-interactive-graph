import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_interactive_graph/model/graph.dart';
import 'package:flutter_interactive_graph/model/node.dart';
import 'package:flutter_interactive_graph/widgets/graph_menu.dart';
import 'package:flutter_interactive_graph/widgets/grid_painter.dart';

import 'edge_painter.dart';
import 'graph_node.dart';

class GraphWidget extends StatefulWidget {
  final Graph? graph;

  final num topMargin;

  // final TrackedAPIDocument tracker;

  final dynamic dataset;

  GraphWidget(
      {Key? key,
      required this.topMargin,
      required this.graph,
      required this.graphChildBuilder,
      required this.menuChildBuilder,
      required this.dataset,
      this.nodeTypes,
      this.addNode})
      : super(key: key);

  Widget Function(GlobalKey key, String name, dynamic data, Graph graph,
      VoidCallback notify, GraphNode node, dynamic dataset) graphChildBuilder;

  Widget Function(GlobalKey key, String name, dynamic data, Graph graph)?
      menuChildBuilder;

  GraphNode Function(String type)? addNode;
  List<String>? nodeTypes;

  @override
  GraphWidgetState createState() => GraphWidgetState();
}

class GraphWidgetState extends State<GraphWidget> {
  final GlobalKey _edgeKey = GlobalKey();
  final GlobalKey _flowKey = GlobalKey();
  bool sidePanelOpen = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    double xMax = MediaQuery.of(context).size.width;
    double yMax = MediaQuery.of(context).size.height - widget.topMargin;

    List<GraphNodeWidget> graphNodes = _children(context);
    // updateEdges();
    return Container(
        decoration: const BoxDecoration(
          color: Colors.white,
        ),
        width: xMax,
        height: yMax,
        child: Stack(children: [
          Listener(
              behavior: HitTestBehavior.opaque,
              onPointerSignal: _onPointerSignal,
              child: GestureDetector(
                  behavior: HitTestBehavior.deferToChild,
                  onPanUpdate: (details) {
                    setState(() {
                      widget.graph!.origin = widget.graph!.origin +
                          details.delta / widget.graph!.scale;
                    });
                  },
                  child: Stack(
                      alignment: Alignment.center,
                      fit: StackFit.loose,
                      clipBehavior: Clip.hardEdge,
                      children: [
                        // ...graphNodes,
                        Flow(
                            key: _flowKey,
                            delegate: FlowGraphDelegate(graph: widget.graph),
                            children: [
                              CustomPaint(
                                size: Size(xMax, yMax),
                                painter: GridPainter(
                                    context: context,
                                    scale: widget.graph!.scale,
                                    origin: widget.graph!.origin),
                              ),
                              CustomPaint(
                                key: _edgeKey,
                                size: Size(xMax, yMax),
                                painter: EdgePainter(
                                    nodes: graphNodes,
                                    origin: widget.graph!.origin,
                                    scale: widget.graph!.scale,
                                    context: context),
                              ),
                              ...graphNodes
                            ])
                      ]))),
          Positioned(
              bottom: 25,
              right: 25,
              child: PopupMenuButton(
                  itemBuilder: (context) => widget.nodeTypes?.map((type) {
                        return PopupMenuItem(
                          value: type,
                          child: Text(type),
                        );
                      }).toList() ??
                      [],
                  onSelected: (value) {
                    if (widget.addNode != null) {
                      String nodeType = value as String;
                      widget.addNode!(nodeType);
                    }
                  },
                  child: FloatingActionButton(
                    backgroundColor: Theme.of(context).primaryColorDark,
                    onPressed: () {},
                    child: const Icon(Icons.add),
                  ))),
          GraphMenuWidget(
              sidePanelOpen: sidePanelOpen,
              topMargin: widget.topMargin.toDouble(),
              graph: widget.graph,
              menuChildBuilder: widget.menuChildBuilder),
        ]));
  }

  List<GraphNodeWidget> _children(BuildContext context) {
    List<GraphNodeWidget> graphNodes = [];
    if (widget.graph == null) {
      return graphNodes;
    }
    graphNodes = widget.graph!.nodes
        .map((node) => GraphNodeWidget(
              graphNode: node,
              topMargin: widget.topMargin,
              scale: widget.graph!.scale,
              origin: widget.graph!.origin,
              child: widget.graphChildBuilder(node.key, node.id, node.data,
                  widget.graph!, notify, node, widget.dataset),
              pop: pop,
              notify: notify,
              childKey: node.key,
            ))
        .toList();
    return graphNodes;
  }

  @override
  void didUpdateWidget(covariant GraphWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  void _onPointerSignal(PointerSignalEvent pointerSignal) {
    GestureBinding.instance!.pointerSignalResolver.register(pointerSignal,
        (PointerSignalEvent pointerSignal) {
      if (pointerSignal is PointerScrollEvent) {
        if (pointerSignal.scrollDelta.dy == 1) {
          return;
        }

        //pointer offset relative to origin
        final Offset offset =
            pointerSignal.position / widget.graph!.scale - widget.graph!.origin;

        // zoom in
        if (pointerSignal.scrollDelta.dy < 0) {
          widget.graph!.scale += 0.06;

          // zoom out
        } else {
          widget.graph!.scale -= 0.06;
        }

        // move origin to keep pointer in same position

        // return if widget scale is out of bounds
        if (widget.graph!.scale < 0.1) {
          widget.graph!.scale = 0.1;
          return;
        } else if (widget.graph!.scale > 1) {
          widget.graph!.scale = 1;
          return;
        }

        setState(() {
          widget.graph!.scale = widget.graph!.scale.clamp(0.1, 1);
          widget.graph!.origin =
              pointerSignal.position / widget.graph!.scale - offset;
        });
      }
    });
  }

  void toggleSidePanel() {
    setState(() {
      sidePanelOpen = !sidePanelOpen;
    });
  }

  void notify() {
    setState(() {});
  }

  void pop(String nodeId) {
    widget.graph!.pop(nodeId);
  }
}

class FlowGraphDelegate extends FlowDelegate {
  final Graph? graph;

  FlowGraphDelegate({this.graph}) : super();

  @override
  void paintChildren(FlowPaintingContext context) {
    if (graph == null) {
      return;
    }
    //update all the child sizes of nodes
    var i = 2;
    for (var node in graph!.nodes) {
      var childSize = context.getChildSize(i);
      if (childSize != null) {
        node.size = childSize;
      }
      i++;
    }
    graph!.updateAllAnchors();
    //draw the background and the edges
    context.paintChild(0);
    context.paintChild(1);

    // need to paint the nodes in the order of nodeOrder

    for (var nodeId in graph!.nodeOrder) {
      var node = graph!.nodeMap[nodeId];
      context.paintChild(node!.order + 2,
          transform: Matrix4.translationValues(
              (node.offset!.dx + graph!.origin.dx) * graph!.scale,
              (node.offset!.dy + graph!.origin.dy) * graph!.scale,
              0));
    }
  }

  @override
  bool shouldRepaint(covariant FlowGraphDelegate oldDelegate) {
    return true;
  }
}
