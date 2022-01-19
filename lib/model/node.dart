import 'package:flutter_interactive_graph/model/edge.dart';
import 'package:flutter_interactive_graph/model/node_anchor.dart';
import 'package:flutter/material.dart';

class GraphNode {
  GraphNode({required this.id, required this.type, this.offset, required this.data, required this.scale, required this.order, this.draggable = true});

  static GraphNode empty() {
    return GraphNode(id: '', type: '', offset: Offset.zero, data: '', scale: 1.0, order: 0);
  }

  final String id;
  final dynamic data;
  final String type;
  Offset? offset;
  double scale;
  GlobalKey key = GlobalKey();
  Size size = const Size(200, 100);
  final int order;
  final bool draggable;

  final Map<NodeAnchorType, List<NodeAnchor>> _anchors = {};
  final List<GraphEdge> _outgoingEdges = [];
  final List<GraphEdge> _incomingEdges = [];

  @override
  String toString() => 'Node $id';

  void addAnchor(NodeAnchorType type, NodeAnchor anchor) {
    _anchors.putIfAbsent(type, () => []);
    _anchors[type]!.add(anchor);
  }

  void addOutgoingEdge(GraphEdge edge) {
    _outgoingEdges.add(edge);
  }

  void addIncomingEdge(GraphEdge edge) {
    _incomingEdges.add(edge);
  }

  void removeAnchor(NodeAnchor anchor) {
    _anchors.remove(anchor);
  }

  void removeOutgoingEdge(GraphEdge edge) {
    _outgoingEdges.remove(edge);
  }

  void removeIncomingEdge(GraphEdge edge) {
    _incomingEdges.remove(edge);
  }

  void removeEdge(String id){
    _outgoingEdges.removeWhere((e) => e.id == id);
    _incomingEdges.removeWhere((e) => e.id == id);
  }

  List<GraphEdge> get outgoingEdges => _outgoingEdges;
  List<GraphEdge> get incomingEdges => _incomingEdges;

  void createDefaultAnchors(Size size) {
    addAnchor(NodeAnchorType.input, NodeAnchor(this, size.centerLeft(offset!),'left-middle',  NodeAnchorType.input));
    addAnchor(NodeAnchorType.output, NodeAnchor(this, size.centerRight(offset!),'right-middle', NodeAnchorType.output));
  }

  bool checkDefaultAnchorOffsets(Size size) {
    var centerLeft = size.centerLeft(offset!);
    var centerRight = size.centerRight(offset!);
    return _anchors[NodeAnchorType.input]!.first.offset == centerLeft &&
        _anchors[NodeAnchorType.output]!.first.offset == centerRight;
  }

  void updateDefaultAnchors(Size size) {
    _anchors[NodeAnchorType.input]?[0].updatePosition(size.centerLeft(offset!));
    _anchors[NodeAnchorType.output]?[0].updatePosition(size.centerRight(offset!));
    NodeAnchor? topCenter = getNodeAnchorById('top-center');
    if (topCenter != null) {
      topCenter.updatePosition(size.topCenter(offset!));
    }
  }

  // Returns all input anchors, but creates default anchors if none exist.
  List<NodeAnchor>? get inputAnchors {
    if (_anchors.containsKey(NodeAnchorType.input)) {
      return _anchors[NodeAnchorType.input];
    } else {
      createDefaultAnchors(size);
      return _anchors[NodeAnchorType.input];
    }
  }

  // Returns all output anchors, but creates default anchors if none exist.
  List<NodeAnchor>? get outputAnchors {
    if (_anchors.containsKey(NodeAnchorType.output)) {
      return _anchors[NodeAnchorType.output];
    } else {
      createDefaultAnchors(size);
      return _anchors[NodeAnchorType.output];
    }
  }

  NodeAnchor? getNodeAnchorById(String id) {
    for (var anchor in _anchors.values) {
      for (var a in anchor) {
        if (a.id == id) {
          return a;
        }
      }
    }
    return null;
  }

  void translate(Offset offset, Size size) {
    if (this.offset == null) {
      this.offset = offset;
    } else {
      this.offset = this.offset! + offset;
    }
    // Update anchors
    for (var anchor in inputAnchors!) {
      anchor.translate(offset);
    }
    for (var anchor in outputAnchors!) {
      anchor.translate(offset);
    }
    updateDefaultAnchors(size);
  }
}
