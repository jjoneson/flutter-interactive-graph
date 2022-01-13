import 'dart:ui';

import 'package:flutter/cupertino.dart';

import 'edge.dart';
import 'node.dart';

class Graph {
  Graph(this._nodes, this._edges);

  static Graph empty(){
    return Graph({}, {});
  }

  Offset origin = const Offset(0, 0);
  double scale = 1.0;

  final Map<String, GraphNode> _nodes;
  final Map<String, GraphEdge> _edges;

  Iterable<GraphNode> get nodes => _nodes.values;
  Iterable<GraphEdge> get edges => _edges.values;

  GraphNode? getNode(String id) => _nodes[id];
  GraphEdge? getEdge(String id) => _edges[id];

  final GlobalKey key = GlobalKey();

  void addNode(GraphNode node) {
    _nodes[node.id] = node;
    addEdgesForNode(node);
  }

  void addAllNodes(Iterable<GraphNode> nodes) {
    nodes.forEach(addNode);
  }

  // get all nodes with type
  List<GraphNode> getNodesByType(String type) {
    return _nodes.values.where((node) => node.type == type).toList();
  }

  void addEdge(GraphEdge edge) {
    _edges[edge.id] = edge;
    getNode(edge.source)!.outgoingEdges.add(edge);
    getNode(edge.target)!.incomingEdges.add(edge);
  }

  void addAllEdges(Iterable<GraphEdge> edges) {
    edges.forEach(addEdge);
  }

  void addEdgesForNode(GraphNode node) {
    node.incomingEdges.forEach(addEdge);
    node.outgoingEdges.forEach(addEdge);
  }

  void removeNode(String id) {
    _nodes.remove(id);
    _edges.removeWhere((key, value) => value.source == id || value.target == id);
  }
  void removeEdge(String id) {
    _edges.remove(id);
    _nodes.forEach((key, value) => value.removeEdge(id));
  }

  void clear() {
    _nodes.clear();
    _edges.clear();
  }

  bool checkDefaultAnchorOffsets() {
    for (var node in nodes) {
      if (!node.checkDefaultAnchorOffsets(node.size)) {
        return false;
      }
    }
    return true;
  }

  void updateAllAnchors() {
    _nodes.forEach((key, value) => value.updateDefaultAnchors(value.size));
  }

  void setDefaultOffsets(double defaultWidth) {
    for (var element in nodes) {
      element.translate(Offset(ancestorCount(element, 0) * defaultWidth, 0), element.size);
    }
  }

  int ancestorCount(GraphNode node, int count) {

    if (node.incomingEdges.isNotEmpty) {
      count ++;
    }

    var max = count;
    for (var element in node.incomingEdges) {
      if (element.source == node.id) {
        return count--;
      }
      var depth = ancestorCount(getNode(element.source)!, count);
      if (depth > max) {
        max = depth;
      }
    }

    return max;
  }


  void pop(String nodeId) {
    for (var node in nodes) {
      node.top = false;
    }
    getNode(nodeId)!.top = true;
  }
}
