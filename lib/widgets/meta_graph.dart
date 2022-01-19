import 'package:flutter/material.dart';
import 'package:flutter_interactive_graph/helpers/pointer_scroll_behavior.dart';
import 'package:flutter_interactive_graph/model/graph.dart';
import 'package:flutter_interactive_graph/model/node.dart';

import 'graph.dart';

class MetaGraphWidget extends StatefulWidget {
  final dynamic dataset;

  final double topMargin;
  final Widget Function(GlobalKey key, String name, dynamic data, Graph graph,
      VoidCallback notify, GraphNode node, dynamic tracker) graphChildBuilder;

  final Widget Function(GlobalKey key, String name, dynamic data, Graph graph)?
      menuChildBuilder;

  final Widget Function(BuildContext context, String nodeType)?
      addNodeDialogBuilder;

  final Function(String searchString) onSearch;
  final Graph graph;

  final String? error;
  final List<String>? nodeTypes;

  const MetaGraphWidget({
    Key? key,
    required this.topMargin,
    required this.graphChildBuilder,
    required this.menuChildBuilder,
    required this.onSearch,
    required this.graph,
    required this.error,
    required this.dataset,
    this.addNodeDialogBuilder,
    this.nodeTypes,
  }) : super(key: key);

  @override
  _MetaGraphWidgetState createState() => _MetaGraphWidgetState();
}

class _MetaGraphWidgetState extends State<MetaGraphWidget> {
  bool sidePanelOpen = false;
  GlobalKey _graphContainerKey = GlobalKey();
  String selectedSubGraph = "";
  String _searchString = "";
  Graph? _graph;

  @override
  void initState() {
    super.initState();
    if (widget.graph.subGraphs.isNotEmpty) {
      selectedSubGraph = widget.graph.subGraphs.keys.first;
    }
    _graph = widget.graph;
  }

  @override
  Widget build(BuildContext context) {
    double xMax = MediaQuery.of(context).size.width;
    double yMax = MediaQuery.of(context).size.height - widget.topMargin;
    _graphContainerKey = widget.graph.key;

    return Container(
        decoration: const BoxDecoration(
          color: Colors.white,
        ),
        width: xMax,
        height: yMax,
        child: Stack(children: [
          widget.error == null
              ? GraphWidget(
                  key: _graphContainerKey,
                  topMargin: widget.topMargin,
                  nodeTypes: widget.nodeTypes,
                  graph:
                      widget.graph.subGraphs[selectedSubGraph] ?? widget.graph,
                  graphChildBuilder: widget.graphChildBuilder,
                  menuChildBuilder: widget.menuChildBuilder,
                  addNodeDialogBuilder: widget.addNodeDialogBuilder,
                  dataset: widget.dataset)
              : Positioned(
                  top: widget.topMargin * 3, child: Text(widget.error!)),
          Positioned(
            child: Container(
              height: widget.topMargin.toDouble(),
              width: xMax,
              decoration: const BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black12, blurRadius: 10, spreadRadius: 5)
                  ],
                  border: Border(
                      bottom: BorderSide(color: Colors.white70, width: 1.0))),
              child: Row(
                children: [
                  SizedBox(
                      width: xMax / 10,
                      child: TextField(
                        decoration: const InputDecoration(
                            contentPadding: EdgeInsets.all(18),
                            border: InputBorder.none,
                            hintText: 'Enter Search String'),
                        onChanged: (value) {
                          _searchString = value;
                        },
                      )),
                  IconButton(
                      onPressed: () {
                        if (_searchString.isNotEmpty) {
                          widget.onSearch(_searchString);
                        }
                      },
                      icon: const Icon(Icons.search)),
                  IconButton(
                    onPressed: () {
                      setState(() {});
                    },
                    icon: const Icon(Icons.undo),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {});
                    },
                    icon: const Icon(Icons.redo),
                  ),
                  Expanded(
                      child: ScrollConfiguration(
                          behavior: PointerScrollBehavior(),
                          child: ListView(
                              scrollDirection: Axis.horizontal,
                              children: [
                                ...widget.graph.subGraphs.entries.map((e) {
                                  return TextButton(
                                      style: TextButton.styleFrom(
                                        backgroundColor: selectedSubGraph ==
                                                e.key
                                            ? Theme.of(context).highlightColor
                                            : null,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          selectedSubGraph = e.key;
                                          _graph =
                                              widget.graph.subGraphs[e.key];
                                          Future.delayed(
                                              const Duration(milliseconds: 500),
                                              () {
                                            _graphContainerKey.currentState
                                                ?.setState(() {});
                                          });
                                        });
                                      },
                                      child: Text(e.key));
                                }).toList()
                              ]))),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.menu),
                        onPressed: () {
                          (_graphContainerKey.currentState! as GraphWidgetState)
                              .toggleSidePanel();
                        },
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        ]));
  }
}
