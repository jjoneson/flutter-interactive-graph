import 'package:flutter_interactive_graph/model/graph.dart';

abstract class GraphService {
  Future<Graph> getGraphForString(String string);
  Future<Graph> getGraphForData(dynamic data);
}
