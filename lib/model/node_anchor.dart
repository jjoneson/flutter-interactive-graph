import 'package:flutter_interactive_graph/model/node.dart';
import 'package:flutter/material.dart';

class NodeAnchor {
  NodeAnchor(this.node, this.offset, this.id, this.type);

  final GraphNode node;
  final String id;
  Offset offset;
  NodeAnchorType type;

  void updatePosition(Offset offset) {
    this.offset = offset;
  }

  void translate(Offset offset) {
    this.offset += offset;
  }
}

enum NodeAnchorType {
  input,
  output,
}
