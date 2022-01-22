import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dropzone/flutter_dropzone.dart';
import 'package:flutter_interactive_graph/model/graph.dart';
import 'package:flutter_interactive_graph/model/node.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';

import 'edge_painter.dart';
import 'graph_menu.dart';
import 'graph_node.dart';
import 'grid_painter.dart';

class GraphWidget extends StatefulWidget {
  final Graph? graph;

  final num topMargin;

  // final TrackedAPIDocument tracker;

  final dynamic dataset;

  bool startWithExpandedMenu;

  GraphWidget(
      {Key? key,
      required this.topMargin,
      required this.graph,
      required this.graphChildBuilder,
      required this.menuChildBuilder,
      required this.dataset,
      this.addNodeDialogBuilder,
      this.nodeTypes,
      this.handleFileDrop,
      this.startWithExpandedMenu = false})
      : super(key: key);

  Widget Function(GlobalKey key, String name, dynamic data, Graph graph,
      VoidCallback notify, GraphNode node, dynamic dataset) graphChildBuilder;

  Widget Function(GlobalKey key, String name, dynamic data, Graph graph,
      dynamic dataset)? menuChildBuilder;

  Widget Function(BuildContext context, String nodeType)? addNodeDialogBuilder;

  void Function(String fileContents, String graphType)? handleFileDrop;

  // GraphNode Function(String type)? addNode;
  List<String>? nodeTypes;

  @override
  GraphWidgetState createState() => GraphWidgetState();
}

class GraphWidgetState extends State<GraphWidget> {
  final GlobalKey _edgeKey = GlobalKey();
  final GlobalKey _flowKey = GlobalKey();
  late DropzoneViewController _dropzoneController;
  bool _dropZoneHighlighted = false;
  bool sidePanelOpen = false;
  ValueNotifier<bool> isDialOpen = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
    sidePanelOpen = widget.startWithExpandedMenu;
  }

  @override
  Widget build(BuildContext context) {
    double xMax = MediaQuery.of(context).size.width;
    double yMax = MediaQuery.of(context).size.height - widget.topMargin;

    List<GraphNodeWidget> graphNodes = _children(context);

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
              bottom: MediaQuery.of(context).size.height / 20,
              right: MediaQuery.of(context).size.height / 20 +
                  (sidePanelOpen ? MediaQuery.of(context).size.width * 0.3 : 0),
              child: SpeedDial(
                backgroundColor: Theme.of(context).primaryColorDark,
                icon: const Icon(Icons.add).icon,
                direction: SpeedDialDirection.up,
                openCloseDial: isDialOpen,
                children: widget.nodeTypes?.map((type) {
                      return SpeedDialChild(
                          child: const Icon(Icons.add),
                          backgroundColor: Theme.of(context).primaryColor,
                          label: type,
                          onTap: () {
                            if (widget.addNodeDialogBuilder != null) {
                              showDialog<void>(
                                  context: context,
                                  builder: (context) => widget
                                      .addNodeDialogBuilder!(context, type));
                            }
                          });
                    }).toList() ??
                    [],
              )),
          GraphMenuWidget(
              sidePanelOpen: sidePanelOpen,
              topMargin: widget.topMargin.toDouble(),
              graph: widget.graph,
              menuChildBuilder: widget.menuChildBuilder,
              dataset: widget.dataset),
          Positioned(
              bottom: MediaQuery.of(context).size.height / 20,
              left: MediaQuery.of(context).size.height / 20,
              width: 160,
              height: 120,
              child: DottedBorder(
                  borderType: BorderType.RRect,
                  strokeWidth: 4,
                  dashPattern: const [10, 10],
                  color: _dropZoneHighlighted ? Colors.black38 : Colors.black12,
                  radius: const Radius.circular(8),
                  child: Stack(children: [
                    _buildDropZone(context),
                    Center(
                        child: Icon(
                      Icons.add,
                      color: _dropZoneHighlighted
                          ? Colors.black38
                          : Colors.black12,
                      size: 40,
                    )),
                  ])))
        ]));
  }

  Widget _buildDropZone(BuildContext context) => Builder(
        builder: (context) => DropzoneView(
          onCreated: (ctrl) => _dropzoneController = ctrl,
          onHover: () {
            setState(() => _dropZoneHighlighted = true);
          },
          onLeave: () {
            setState(() => _dropZoneHighlighted = false);
          },
          onDrop: (data) async {
            if (widget.handleFileDrop != null) {
              final bytes = await _dropzoneController.getFileData(data);
              widget.handleFileDrop!(
                  String.fromCharCodes(bytes), widget.graph!.graphType);
            }
          },
        ),
      );

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
