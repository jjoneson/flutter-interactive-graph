import 'package:flutter_interactive_graph/model/node_anchor.dart';

class GraphEdge {
  GraphEdge(
      {required this.id,
      required this.source,
      required this.target,
      required this.sourceAnchor,
      required this.targetAnchor,
      required this.scale});

  final String id;

  final String source;
  final String target;

  NodeAnchor sourceAnchor;
  NodeAnchor targetAnchor;

  double scale;
}
