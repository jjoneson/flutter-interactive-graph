import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:highlight/highlight.dart' show highlight, Node;

/// Highlight Flutter Widget
class HighlightViewWithOverlay extends StatefulWidget {
  /// The original code to be highlighted
  final String source;

  /// Highlight language
  ///
  /// It is recommended to give it a value for performance
  ///
  /// [All available languages](https://github.com/pd4d10/highlight/tree/master/highlight/lib/languages)
  final String? language;

  /// Highlight theme
  ///
  /// [All available themes](https://github.com/pd4d10/highlight/blob/master/flutter_highlight/lib/themes)
  final Map<String, TextStyle> theme;

  /// Padding
  final EdgeInsetsGeometry? padding;

  /// Text styles
  ///
  /// Specify text styles such as font family and font size
  final TextStyle? textStyle;
  final bool animating;

  HighlightViewWithOverlay(
    String input, {
    Key? key,
    this.language,
    this.theme = const {},
    this.padding,
    this.textStyle,
    this.animating = false,
    int tabSize = 8, // TODO: https://github.com/flutter/flutter/issues/50087
  })  : source = input.replaceAll('\t', ' ' * tabSize),
        super(key: key);

  @override
  _HighlightViewWithOverlayState createState() => _HighlightViewWithOverlayState();
}

class _HighlightViewWithOverlayState extends State<HighlightViewWithOverlay>
    with SingleTickerProviderStateMixin{
  static const _defaultFontColor = Color(0xff000000);
  static const _defaultBackgroundColor = Color(0xffffffff);

  double intervalMilliseconds = 50;
  Ticker? _ticker;
  Duration _elapsed = Duration.zero;


  // TODO: dart:io is not available at web platform currently
  // See: https://github.com/flutter/flutter/issues/39998
  // So we just use monospace here for now
  static const _rootKey = 'root';
  OverlayEntry? _overlayEntry;
  final GlobalKey _key = GlobalKey();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    if (widget.animating) {
      _ticker = createTicker((elapsed) {
        if (elapsed.inMilliseconds - _elapsed.inMilliseconds < intervalMilliseconds) {
          return;
        }
        _elapsed = elapsed;
      });

      if (_overlayEntry != null) {
        _overlayEntry?.remove();
      }
      _overlayEntry = OverlayEntry(
        builder: (context) {
          return _buildOverlayContent(context);
        },
      );
      SchedulerBinding.instance?.addPostFrameCallback((_) {
        Overlay.of(context)?.insert(_overlayEntry!);
      });
      _ticker!.start();
    }

  }

  @override
  dispose() {
    _overlayEntry?.remove();
    _ticker?.dispose();
    super.dispose();
  }

  static const _defaultFontFamily = 'monospace';

  @override
  Widget build(BuildContext context) {
    var _textStyle = TextStyle(
      fontFamily: _defaultFontFamily,
      color: widget.theme[_rootKey]?.color ?? _defaultFontColor,
    );
    if (widget.textStyle != null) {
      _textStyle = _textStyle.merge(widget.textStyle);
    }
    return Container(
      color: widget.theme[_rootKey]?.backgroundColor ?? _defaultBackgroundColor,
      padding: widget.padding,
      child: RichText(
        key: _key,
        text: TextSpan(
          style: _textStyle,
          children: _convert(highlight.parse(widget.source, language: widget.language).nodes!),
        ),
      ),
    );
  }

  List<TextSpan> _convert(List<Node> nodes) {
    List<TextSpan> spans = [];
    var currentSpans = spans;
    List<List<TextSpan>> stack = [];

    _traverse(Node node) {
      if (node.value != null) {
        currentSpans.add(node.className == null
            ? TextSpan(text: node.value)
            : TextSpan(text: node.value, style: widget.theme[node.className!]));
      } else if (node.children != null) {
        List<TextSpan> tmp = [];
        currentSpans.add(TextSpan(children: tmp, style: widget.theme[node.className!]));
        stack.add(currentSpans);
        currentSpans = tmp;

        for (var n in node.children!) {
          _traverse(n);
          if (n == node.children!.last) {
            currentSpans = stack.isEmpty ? spans : stack.removeLast();
          }
        }
      }
    }

    for (var node in nodes) {
      _traverse(node);
    }

    return spans;
  }

  double charWidth = 8.25;
  double charHeight = 16;
  double topPadding = 5;

  Widget _buildOverlayContent(BuildContext context) {
    final keyContext = _key.currentContext;
    final RenderBox? renderBox = keyContext?.findRenderObject() as RenderBox?;
    final size = renderBox?.size;
    final offset = renderBox?.localToGlobal(Offset.zero);
    return  Positioned(
        top: offset!.dy  + topPadding,
        left: offset.dx,
        width: charWidth * 34,
        height: charHeight,
        child: IgnorePointer(child:Container(
            color: Colors.white.withOpacity(0.5))));
  }
}
