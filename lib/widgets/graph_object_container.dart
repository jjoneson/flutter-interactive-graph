import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_interactive_graph/model/display_status.dart';
import 'package:flutter_interactive_graph/model/graph.dart';
import 'package:flutter_interactive_graph/model/node.dart';

class GraphObjectContainer extends StatefulWidget {
  const GraphObjectContainer(
      {Key? key,
      required this.children,
      required this.title,
      required this.node,
      this.subtitle,
      required this.minWidth,
      required this.maxWidth,
      required this.notify,
      this.startExpanded = false,
      required this.icon,
      required this.graph})
      : super(key: key);

  final List<Widget> children;

  final String title;
  final String? subtitle;
  final double minWidth;
  final double maxWidth;
  final GraphNode node;

  final VoidCallback? notify;
  final bool startExpanded;
  final Graph graph;
  final IconData icon;

  @override
  _GraphObjectContainerState createState() => _GraphObjectContainerState();
}

class _GraphObjectContainerState extends State<GraphObjectContainer>
    with SingleTickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Flexible(
            fit: FlexFit.loose,
            child: Opacity(
              opacity: widget.node.getOpacity(),
              child: Container(
                decoration: BoxDecoration(
                    color: Colors.white70.withOpacity(1),
                    border: Border.all(color: Colors.black12),
                    borderRadius: BorderRadius.circular(5)),
                alignment: Alignment.centerLeft,
                constraints: BoxConstraints(
                  maxWidth:
                      widget.node.expanded ? widget.maxWidth : widget.minWidth,
                  minWidth: widget.minWidth,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    RawGestureDetector(
                      gestures: {
                        AllowMultipleGestureRecognizer:
                            GestureRecognizerFactoryWithHandlers<
                                    AllowMultipleGestureRecognizer>(
                                () => AllowMultipleGestureRecognizer(),
                                (AllowMultipleGestureRecognizer instance) {
                          instance.onTap = () => toggleExpanded();
                        }),
                      },
                      child: ListTile(
                        minVerticalPadding: 0,
                        leading: Icon(
                          widget.node.expanded
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                          color: Colors.black87,
                        ),
                        minLeadingWidth: 0,
                        horizontalTitleGap: 5,
                        trailing: Icon(widget.icon,
                            color: Theme.of(context).primaryColor),
                        title: Text(widget.title),
                        subtitle: Text(widget.subtitle ?? ''),
                      ),
                    ),
                    AnimatedSize(
                        curve: Curves.easeIn,
                        duration: const Duration(milliseconds: 100),
                        child: widget.node.expanded
                            ? Column(
                                mainAxisSize: MainAxisSize.min,
                                children: widget.children,
                              )
                            : const Offstage())
                  ],
                ),
              ),
            )),
      ],
    );
  }

  void toggleExpanded() {
    setState(() {
      widget.graph.pop(widget.node.id);
      widget.node.expanded = !widget.node.expanded;
      widget.graph.focusOnExpandedNodes();
      if (!widget.node.expanded) {
        pullChildNodes(widget.node);
      }

      Future.delayed(const Duration(milliseconds: 200), () {
        if (widget.node.expanded) {
          pushChildNodes(widget.node);
        }
        widget.notify?.call();
      });
    });
  }

  void pushChildNodes(GraphNode parent) {
    for (var child in widget.graph.getChildren(parent.id)) {
      child.translate(
          Offset(parent.size.width, 0), child.size * widget.graph.scale);
    }
  }

  void pullChildNodes(GraphNode parent) {
    for (var child in widget.graph.getChildren(parent.id)) {
      child.translate(
          Offset(parent.size.width, 0) * -1, child.size * widget.graph.scale);
    }
  }
}

class AllowMultipleGestureRecognizer extends TapGestureRecognizer {
  @override
  void rejectGesture(int pointer) {
    acceptGesture(pointer);
  }
}
