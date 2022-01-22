import 'dart:ui';

import 'package:flutter/cupertino.dart';

import 'display_status.dart';
import 'edge.dart';
import 'node.dart';

class Graph {
  Graph(this._nodes, this._edges);

  static Graph empty() {
    return Graph({}, {});
  }

  Offset origin = const Offset(0, 0);
  double scale = 1.0;
  double defaultVerticalSpacing = 100.0;
  Map<String, Graph> subGraphs = {};

  final Map<String, GraphNode> _nodes;
  final Map<String, GraphEdge> _edges;
  final List<String> nodeOrder = [];

  Map<String, GraphNode> get nodeMap => _nodes;

  Iterable<GraphNode> get nodes => _nodes.values;

  Iterable<GraphEdge> get edges => _edges.values;

  GraphNode? getNode(String id) => _nodes[id];

  GraphEdge? getEdge(String id) => _edges[id];
  String graphType = "default";

  final GlobalKey key = GlobalKey();

  void addNode(GraphNode node) {
    node.offset ??=
        Offset(0, defaultVerticalSpacing * (_nodes.length.toDouble() + 1));

    _nodes[node.id] = node;
    addEdgesForNode(node);
    if (!nodeOrder.contains(node.id) && node.drawOnGraph) {
      nodeOrder.add(node.id);
    }
  }

  void addAllNodes(Iterable<GraphNode> nodes) {
    nodes.forEach(addNode);
  }

  // get all nodes with type
  List<GraphNode> getNodesByType(String type) {
    return _nodes.values.where((node) => node.type == type).toList();
  }

  @protected
  void addEdgeDirect(GraphEdge edge) {
    _edges[edge.id] = edge;
  }

  void addEdge(GraphEdge edge) {
    _edges[edge.id] = edge;
    getNode(edge.source)!.outgoingEdges.add(edge);
    getNode(edge.target)?.incomingEdges.add(edge);
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
    _edges
        .removeWhere((key, value) => value.source == id || value.target == id);
    nodeOrder.remove(id);
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
      element.translate(
          Offset(ancestorCount(element, 0) * defaultWidth, 0), element.size);
    }
  }

  int ancestorCount(GraphNode node, int count) {
    if (count > 100) {
      return count;
    }
    if (node.incomingEdges.isNotEmpty) {
      count++;
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

  void addChildNodesToGraph(GraphNode node, Graph subGraph) {
    for (var edge in getNode(node.id)!.outgoingEdges) {
      var target = getNode(edge.target)!;
      GraphNode? newTarget;

      if (subGraph.nodeMap.containsKey(target.id)) {
        newTarget = subGraph.nodeMap[target.id];
      } else {
        newTarget = GraphNode(
            id: target.id,
            type: target.type,
            data: target.data,
            scale: scale,
            order: subGraph.nodes.length);
        subGraph.addNode(newTarget);
      }

      // if (newTarget?.incomingEdges.any((element) => element.id == edge.id) ?? false) {
      //   continue;
      // }

      var newEdge = GraphEdge(
          id: edge.id,
          source: edge.source,
          target: edge.target,
          scale: scale,
          sourceAnchor: node.outputAnchors!.first,
          targetAnchor: newTarget!.inputAnchors!.first);
      subGraph.addEdge(newEdge);

      addChildNodesToGraph(newTarget, subGraph);
    }
  }

  void addSubGraph(String nodeId) {
    subGraphs[nodeId] = getSubGraph(nodeId)..setDefaultOffsets(400);
  }

  Graph getSubGraph(String nodeId) {
    var subGraph = Graph.empty();
    var node = getNode(nodeId)!;
    var newNode = GraphNode(
        id: node.id,
        type: node.type,
        data: node.data,
        scale: scale,
        order: subGraph.nodes.length);
    subGraph.addNode(newNode);
    addChildNodesToGraph(newNode, subGraph);
    return subGraph;
  }

  List<GraphNode> getExpandedNodes() {
    var nodes = <GraphNode>[];
    for (var node in this.nodes) {
      if (node.expanded) {
        nodes.add(node);
      }
    }
    return nodes;
  }

  void pop(String nodeId) {
    if (nodeOrder.remove(nodeId)) {
      nodeOrder.add(nodeId);
    }
  }

  void setDisplayStatusOnChildren(String nodeId, DisplayStatus displayStatus) {
    var node = getNode(nodeId)!;
    node.displayStatus = displayStatus;
    for (var edge in node.outgoingEdges) {
      edge.displayStatus = displayStatus;
      setDisplayStatusOnChildren(edge.target, displayStatus);
    }
  }

  void focusOnNodeTree(String nodeId) {
    fadeAll();
    setDisplayStatusOnChildren(nodeId, DisplayStatus.normal);
  }

  void focusOnNodeTrees(List<String> nodeIds) {
    fadeAll();
    for (var nodeId in nodeIds) {
      setDisplayStatusOnChildren(nodeId, DisplayStatus.normal);
    }
  }

  void focusOnExpandedNodes() {
    fadeAll();
    var expandedNodes = getExpandedNodes();
    if (expandedNodes.isNotEmpty) {
      for (var node in expandedNodes) {
        setDisplayStatusOnChildren(node.id, DisplayStatus.normal);
      }
    } else {
      resetDisplayStatus();
    }
  }

  void fadeAll() {
    for (var node in nodes) {
      node.displayStatus = DisplayStatus.faded;
      for (var edge in node.outgoingEdges) {
        edge.displayStatus = DisplayStatus.faded;
      }
      for (var edge in node.incomingEdges) {
        edge.displayStatus = DisplayStatus.faded;
      }
    }
  }

  void resetDisplayStatus() {
    for (var node in nodes) {
      node.displayStatus = DisplayStatus.normal;
    }
    for (var edge in edges) {
      edge.displayStatus = DisplayStatus.normal;
    }
  }
}
