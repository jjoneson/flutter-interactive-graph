import 'package:flutter_interactive_graph/model/graph.dart';
import 'package:flutter_interactive_graph/helpers/pointer_scroll_behavior.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class GraphMenuWidget extends StatefulWidget {
  final bool sidePanelOpen;
  final double topMargin;
  final Graph? graph;
  Widget Function(GlobalKey key, String name, dynamic data, Graph graph)?
      menuChildBuilder;

  GraphMenuWidget(
      {Key? key,
      required this.sidePanelOpen,
      required this.topMargin,
      required this.graph,
      required this.menuChildBuilder})
      : super(key: key);

  @override
  _GraphMenuWidgetState createState() => _GraphMenuWidgetState();
}

class _GraphMenuWidgetState extends State<GraphMenuWidget> {
  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: MediaQuery.of(context).size.width * 0.7,
      top: widget.topMargin.toDouble(),
      child: widget.sidePanelOpen
          ? SizedBox(
              width: MediaQuery.of(context).size.width * 0.3,
              height: MediaQuery.of(context).size.height - widget.topMargin *2,
              child: Column(
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                      child: Container(
                          decoration: const BoxDecoration(
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 10,
                                    spreadRadius: 5)
                              ],
                              border: Border(
                                left: BorderSide(
                                    color: Colors.white70, width: 1.0),
                              )),
                          child: ScrollConfiguration(
                            behavior: PointerScrollBehavior(),
                            child: ListView(
                              children: widget.graph!.nodes
                                  .map((e) => widget.menuChildBuilder!(
                                      GlobalKey(), e.id, e.data, widget.graph!))
                                  .toList(),
                            ),
                          ))),
                ],
              ),
            )
          : const Offstage(),
    );
  }
}
