import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:highlight/highlight.dart' show highlight, Node;

/// Highlight Flutter Widget
class CustomHighlightView extends StatefulWidget {
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

  CustomHighlightView(
    String input, {
    Key? key,
    this.language,
    this.theme = const {},
    this.padding,
    this.textStyle,
    int tabSize = 8, // TODO: https://github.com/flutter/flutter/issues/50087
  })  : source = input.replaceAll('\t', ' ' * tabSize),
        super(key: key);

  @override
  _CustomHighlightViewState createState() => _CustomHighlightViewState();
}

class _CustomHighlightViewState extends State<CustomHighlightView> with SingleTickerProviderStateMixin {
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

  // static const _rootKey = 'root';
  static const _defaultFontColor = Color(0xff000000);
  static const _defaultBackgroundColor = Color(0xffffffff);

  // TODO: dart:io is not available at web platform currently
  // See: https://github.com/flutter/flutter/issues/39998
  // So we just use monospace here for now
  static const _defaultFontFamily = 'monospace';

  List<TextSpan>? _spans;
  int _globalSpanIndex = 0;
  final List<int> _mutatedSpans = [0];
  late final Ticker _ticker;
  Duration _elapsed = Duration.zero;
  double intervalMilliseconds = 50;
  List<GlobalKey> _keys = [];
  List<dynamic> addressableSpans = [];
  late TextStyle _textStyle;

  final whiteStyle = const TextStyle(backgroundColor: Colors.white24);
  late TextStyle normalStyle;
  late TextSpan _text;
  final GlobalKey _rootKey = GlobalKey();

  // OverlayEntry _overlayEntry;

  @override
  void initState() {
    super.initState();
    // normalStyle = TextStyle(backgroundColor: widget.theme[_rootKey]?.backgroundColor ?? _defaultBackgroundColor);

    _textStyle = TextStyle(
        fontFamily: _defaultFontFamily,
        color: widget.theme[_rootKey]?.color ?? _defaultFontColor,
        backgroundColor: widget.theme[_rootKey]?.backgroundColor ?? _defaultBackgroundColor);
    if (widget.textStyle != null) {
      _textStyle = _textStyle.merge(widget.textStyle);
    }
    //
    _spans ??= _convert(highlight.parse(widget.source, language: widget.language).nodes!);
    // _keys = List.generate(_spans!.length, (i) => GlobalKey());
    // for (var i = 0; i < _spans!.length; i++) {
    //   addressableSpans.add(_spans![i]);
    //   addressableSpans.add(WidgetSpan(child: SizedBox.fromSize(size: Size.zero, key: _keys[i])));
    // }

    // _text = TextSpan(children: List.from(addressableSpans), style: _textStyle);

    _ticker = createTicker((elapsed) {
      if (elapsed.inMilliseconds - _elapsed.inMilliseconds < intervalMilliseconds) {
        return;
      }
      _elapsed = elapsed;
      // if (_globalSpanIndex < addressableSpans.length) {
      //   setState(() {
      //     addressableSpans[_globalSpanIndex] =
      //         _copyTextSpanWithNewStyle(addressableSpans[_globalSpanIndex], whiteStyle);
      //     _mutatedSpans.add(_globalSpanIndex);
      //
      //     var keyIndex = _mutatedSpans.first ~/ 2;
      //     if (_keys[keyIndex].currentContext != null) {
      //       Scrollable.ensureVisible(_keys[keyIndex.toInt()].currentContext!,
      //           duration: const Duration(milliseconds: 500));
      //     }
      //
      //     if (_mutatedSpans.length > 5) {
      //       var mdx = _mutatedSpans.removeAt(0);
      //       addressableSpans[mdx] = _copyTextSpanWithNewStyle(addressableSpans[mdx], normalStyle);
      //     }
      //     _text = TextSpan(children: List.from(addressableSpans), style: _textStyle);
      //     _globalSpanIndex += 2;
      //   });
      // } else {
      //   setState(() {
      //     _globalSpanIndex = 0;
      //   });
      // }
    });
    _ticker.start();
  }

  TextSpan _copyTextSpanWithNewStyle(TextSpan textSpan, TextStyle? newStyle) {
    // if (textSpan.children == null) {
    return TextSpan(
      text: textSpan.text,
      style: textSpan.style != null ? textSpan.style!.merge(newStyle!) : newStyle,
      children: textSpan.children,
    );
    //}
    //
    // return TextSpan(
    //   text: textSpan.text,
    //   style: textSpan.style != null ? textSpan.style!.merge(newStyle!) : newStyle,
    //   children: List.from(textSpan.children!)
    //       .map((child) => _copyTextSpanWithNewStyle(child, newStyle))
    //       .toList(),
    // );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: widget.theme[_rootKey]?.backgroundColor ?? _defaultBackgroundColor,
      padding: widget.padding,
      child: RichText(
        key: _rootKey,
        text: TextSpan(children: _spans, style: _textStyle),
      ),
    );
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }
}
