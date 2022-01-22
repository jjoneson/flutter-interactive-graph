import 'package:flutter_interactive_graph/model/display_status.dart';
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

  DisplayStatus displayStatus = DisplayStatus.normal;

  double scale;

  double getOpacity() {
    if (displayStatus == DisplayStatus.normal || displayStatus == DisplayStatus.highlighted) {
      return 1;
    } else if (displayStatus == DisplayStatus.hidden) {
      return 0;
    } else  if (displayStatus == DisplayStatus.faded) {
      return 0.1;
    }
    return 1;
  }
}
