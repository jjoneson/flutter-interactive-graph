import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_dropzone/flutter_dropzone.dart';
import 'package:flutter_interactive_graph/model/display_status.dart';
import 'package:flutter_interactive_graph/model/graph.dart';
import 'package:flutter_interactive_graph/model/node.dart';
import 'package:flutter_interactive_graph/widgets/edge_widget.dart';
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

  Widget Function(
          GlobalKey key, String name, dynamic data, Graph graph, VoidCallback notify, GraphNode node, dynamic dataset)
      graphChildBuilder;

  Widget Function(GlobalKey key, String name, dynamic data, Graph graph, dynamic dataset)? menuChildBuilder;

  Widget Function(BuildContext context, String nodeType)? addNodeDialogBuilder;

  void Function(String fileContents, String fileExtension, String graphType)? handleFileDrop;

  // GraphNode Function(String type)? addNode;
  List<String>? nodeTypes;

  @override
  GraphWidgetState createState() => GraphWidgetState();
}

class GraphWidgetState extends State<GraphWidget> with SingleTickerProviderStateMixin {
  final GlobalKey _edgeKey = GlobalKey();
  final GlobalKey _flowKey = GlobalKey();
  late DropzoneViewController _dropzoneController;
  bool _dropZoneHighlighted = false;
  bool sidePanelOpen = false;
  ValueNotifier<bool> isDialOpen = ValueNotifier(false);
  AnimationController? _graphNodeMoveController;
  Animation? _graphNodeMoveAnimation;

  @override
  void initState() {
    super.initState();
    _graphNodeMoveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _graphNodeMoveAnimation = Tween(begin: 0.0, end: 1.0).animate(_graphNodeMoveController!);
    _graphNodeMoveAnimation!.addListener(() {
      setState(() {
        if (_graphNodeMoveAnimation!.status == AnimationStatus.completed) {
          _graphNodeMoveController!.reset();
          widget.graph!.adjustingNodes = false;
          for (final node in widget.graph!.nodes) {
            node.targetOffset = null;
          }
        } else if (widget.graph!.adjustingNodes && _graphNodeMoveAnimation!.status != AnimationStatus.completed) {
          for (final node in widget.graph!.nodes) {
            if (node.targetOffset == null) {
              continue;
            }
            node.translate(
              Offset(
                _graphNodeMoveAnimation?.value * (node.targetOffset!.dx - node.offset!.dx),
                _graphNodeMoveAnimation?.value * (node.targetOffset!.dy - node.offset!.dy),
              ), node.size * widget.graph!.scale);
            // node.targetOffset = Offset(node.targetOffset!.dx - node.targetOffset!.dx * _graphNodeMoveAnimation!.value,
            //     node.targetOffset!.dy - node.targetOffset!.dy * _graphNodeMoveAnimation!.value);

          }
          _graphNodeMoveController!.forward();
         }
      });
    });
    sidePanelOpen = widget.startWithExpandedMenu;
  }

  @override
  void dispose() {
    _graphNodeMoveController!.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double xMax = MediaQuery.of(context).size.width;
    double yMax = MediaQuery.of(context).size.height - widget.topMargin;

    if (widget.graph!.adjustingNodes && _graphNodeMoveAnimation!.status != AnimationStatus.completed) {
      _graphNodeMoveController!.forward();
    }

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
                      widget.graph!.origin = widget.graph!.origin + details.delta / widget.graph!.scale;
                    });
                  },
                  child:
                      Stack(alignment: Alignment.center, fit: StackFit.loose, clipBehavior: Clip.hardEdge, children: [
                    Flow(
                        key: _flowKey,
                        delegate: FlowGraphDelegate(
                          pushPullAnimation: _graphNodeMoveAnimation!,
                            graph: widget.graph,
                            adjustAnchors: () =>
                                // setState(() {
                                  widget.graph!.updateAllAnchors()
                                // })
                                ),
                        children: [
                          CustomPaint(
                            size: Size(xMax, yMax),
                            painter:
                                GridPainter(context: context, scale: widget.graph!.scale, origin: widget.graph!.origin),
                          ),
                          EdgeWidget(
                              graph: widget.graph!,
                              context: context,
                              size: Size(xMax, yMax)),
                          // CustomPaint(
                          //   key: _edgeKey,
                          //   size: Size(xMax, yMax),
                          //   painter: EdgePainter(
                          //       nodes: graphNodes,
                          //       origin: widget.graph!.origin,
                          //       scale: widget.graph!.scale,
                          //       context: context,
                          //       pulsePosition: _edgePulseAnimation!.value),
                          // ),
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
                                  context: context, builder: (context) => widget.addNodeDialogBuilder!(context, type));
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
                      color: _dropZoneHighlighted ? Colors.black38 : Colors.black12,
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
              final fileName = await _dropzoneController.getFilename(data);
              var fileExtension = fileName.split('.').last;


              widget.handleFileDrop!(String.fromCharCodes(bytes), fileExtension, widget.graph!.graphType);
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
              child:
                  widget.graphChildBuilder(node.key, node.id, node.data, widget.graph!, notify, node, widget.dataset),
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
    GestureBinding.instance!.pointerSignalResolver.register(pointerSignal, (PointerSignalEvent pointerSignal) {
      if (pointerSignal is PointerScrollEvent) {
        if (pointerSignal.scrollDelta.dy == 1) {
          return;
        }

        //pointer offset relative to origin
        final Offset offset = pointerSignal.position / widget.graph!.scale - widget.graph!.origin;

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
          widget.graph!.origin = pointerSignal.position / widget.graph!.scale - offset;
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
  final Function() adjustAnchors;
  final Animation pushPullAnimation;

  FlowGraphDelegate({this.graph, required this.adjustAnchors, required this.pushPullAnimation}) : super();

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
    //draw the background and the edges
    context.paintChild(0);
    context.paintChild(1);

    // need to paint the nodes in the order of nodeOrder

    for (var nodeId in graph!.nodeOrder) {
      var node = graph!.nodeMap[nodeId];
      if (node?.displayStatus == DisplayStatus.hidden) continue;
      context.paintChild(node!.order + 2,
          transform: Matrix4.translationValues((node.offset!.dx + graph!.origin.dx) * graph!.scale,
              ( node.offset!.dy + graph!.origin.dy) * graph!.scale, 0));
    }

    if (!graph!.anchorsAreCorrectlyPositioned()) {
      SchedulerBinding.instance?.addPostFrameCallback((_) {
        adjustAnchors();
      });
    }
  }

  @override
  bool shouldRepaint(covariant FlowGraphDelegate oldDelegate) {
    return true;
  }
}
