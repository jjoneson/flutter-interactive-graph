import 'package:flutter/material.dart';
import 'package:flutter_interactive_graph/helpers/pointer_scroll_behavior.dart';
import 'package:flutter_interactive_graph/model/graph.dart';
import 'package:flutter_interactive_graph/model/node.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';


import 'graph.dart';

class MetaGraphWidget extends StatefulWidget {
  final dynamic dataset;

  final double topMargin;
  final Widget Function(
          GlobalKey key, String name, dynamic data, Graph graph, VoidCallback notify, GraphNode node, dynamic tracker)
      graphChildBuilder;

  final Widget Function(GlobalKey key, String name, dynamic data, Graph graph, dynamic dataset)? menuChildBuilder;

  final Widget Function(BuildContext context, String nodeType)? addNodeDialogBuilder;

  final Function(String fileContents, String fileExtension, String graphType)? handleFileDrop;

  final Function(String searchString) onSearch;
  final Graph graph;

  final String? error;
  final List<String>? nodeTypes;

  final bool startWithExpandedMenu;

  const MetaGraphWidget({
    Key? key,
    required this.topMargin,
    required this.graphChildBuilder,
    required this.menuChildBuilder,
    required this.onSearch,
    required this.graph,
    required this.error,
    required this.dataset,
    this.handleFileDrop,
    this.addNodeDialogBuilder,
    this.nodeTypes,
    this.startWithExpandedMenu = false,
  }) : super(key: key);

  @override
  _MetaGraphWidgetState createState() => _MetaGraphWidgetState();
}

class _MetaGraphWidgetState extends State<MetaGraphWidget> {
  bool sidePanelOpen = false;
  GlobalKey _graphContainerKey = GlobalKey();
  String _selectedSubGraph = "";
  String _searchString = "";
  Graph? _graph;
  final GlobalKey _subGraphListKey = GlobalKey();
  // final ScrollController _subGraphListController = ScrollController();
  final Map<String, GlobalKey> _subGraphKeys = {};

  @override
  void initState() {
    super.initState();
    if (widget.graph.subGraphs.isNotEmpty) {
      _selectedSubGraph = widget.graph.subGraphs.keys.first;
    }
    _graph = widget.graph;
  }

  @override
  Widget build(BuildContext context) {
    double xMax = MediaQuery.of(context).size.width;
    double yMax = MediaQuery.of(context).size.height - widget.topMargin;
    _graphContainerKey = _graph!.key;
    if (widget.graph.subGraphs.isNotEmpty && !widget.graph.subGraphs.containsKey(_selectedSubGraph)) {
      _selectedSubGraph = widget.graph.subGraphs.keys.first;
    }

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
                  startWithExpandedMenu: widget.startWithExpandedMenu,
                  handleFileDrop: widget.handleFileDrop,
                  graph: widget.graph.subGraphs[_selectedSubGraph] ?? widget.graph,
                  graphChildBuilder: widget.graphChildBuilder,
                  menuChildBuilder: widget.menuChildBuilder,
                  addNodeDialogBuilder: widget.addNodeDialogBuilder,
                  dataset: widget.dataset)
              : Positioned(top: widget.topMargin * 3, child: Text(widget.error!)),
          Positioned(
            child: Container(
              height: widget.topMargin.toDouble(),
              width: xMax,
              decoration: const BoxDecoration(
                  color: Colors.white,
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, spreadRadius: 5)],
                  border: Border(bottom: BorderSide(color: Colors.white70, width: 1.0))),
              child: Row(
                children: [
                  SizedBox(
                    width: xMax / 6,
                    child: TypeAheadField(
                      textFieldConfiguration: TextFieldConfiguration(
                          autofocus: false,
                          style: DefaultTextStyle.of(context).style.copyWith(
                                fontSize: 16,
                                fontStyle: FontStyle.italic,
                              ),
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                          )),
                      suggestionsCallback: (searchString) {
                        return _getSuggestedSubGraphs(searchString);
                        // return widget.graph.subGraphs.keys
                        //     .where((subGraph) => subGraph.toLowerCase().contains(searchString.toLowerCase()))
                        //     .toList();
                      },
                      itemBuilder: (context, suggestion) {
                        return ListTile(
                          title: Text(suggestion.toString()),
                        );
                      },
                      onSuggestionSelected: (suggestion) {
                        setState(() {
                          _selectedSubGraph = suggestion.toString();
                          Scrollable.ensureVisible(_subGraphKeys[suggestion.toString()]!.currentContext!, duration: const Duration(milliseconds: 1000));
                        });
                      },
                    ),
                    // TextField(
                    //   decoration: const InputDecoration(
                    //       contentPadding: EdgeInsets.all(18),
                    //       border: InputBorder.none,
                    //       hintText: 'Enter Search String'),
                    //   onChanged: (value) {
                    //     _searchString = value;
                    //   },
                    // )
                  ),
                  // IconButton(
                  //     onPressed: () {
                  //       if (_searchString.isNotEmpty) {
                  //         // widget.onSearch(_searchString);
                  //       }
                  //     },
                  //     icon: const Icon(Icons.search)),
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
                          child: SingleChildScrollView(
                            primary: false,
                              key: _subGraphListKey,
                              scrollDirection: Axis.horizontal,
                              child: Row(children: [
                                ...widget.graph.subGraphs.entries.map((e) {
                                  if (!_subGraphKeys.containsKey(e.key)) {
                                    _subGraphKeys[e.key] = GlobalKey();
                                  }
                                  return TextButton(
                                      key: _subGraphKeys[e.key],
                                      style: TextButton.styleFrom(
                                        backgroundColor:
                                            _selectedSubGraph == e.key ? Theme.of(context).highlightColor : null,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _selectedSubGraph = e.key;
                                          _graph = widget.graph.subGraphs[e.key];
                                          Future.delayed(const Duration(milliseconds: 500), () {
                                            _graphContainerKey.currentState?.setState(() {});
                                          });
                                        });
                                      },
                                      child: Text(e.key));
                                }).toList()
                              ])))),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.menu),
                        onPressed: () {
                          (_graphContainerKey.currentState! as GraphWidgetState).toggleSidePanel();
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

  List<String> _getSuggestedSubGraphs(String searchContents) {
    return widget.graph.subGraphs.entries
        .where((subGraph) {
          if (subGraph.key.toLowerCase().contains(searchContents.toLowerCase())) {
            return true;
          }

          if (subGraph.value.nodes.any((node) => node.id.toLowerCase().contains(searchContents.toLowerCase()))) {
            return true;
          }

          return false;
        })
        .map((e) => e.key)
        .toList();
  }
}
