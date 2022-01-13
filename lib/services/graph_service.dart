import 'package:flutter_interactive_graph/model/graph.dart';

abstract class GraphService {
  Future<Graph> getGraph(String id);
}
