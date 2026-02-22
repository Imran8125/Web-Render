// Web implementation: renders HTML in an iframe using dart:html
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html_lib;
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';

/// Builds a web preview widget using an iframe to render HTML content.
Widget buildPreviewWidget({
  required String html,
  required void Function(String) onLog,
  Key? key,
}) {
  return _WebPreview(key: key, html: html, onLog: onLog);
}

class _WebPreview extends StatefulWidget {
  final String html;
  final void Function(String) onLog;

  const _WebPreview({super.key, required this.html, required this.onLog});

  @override
  State<_WebPreview> createState() => _WebPreviewState();
}

class _WebPreviewState extends State<_WebPreview> {
  late String _viewType;

  @override
  void initState() {
    super.initState();
    _viewType = 'web-render-preview-${DateTime.now().millisecondsSinceEpoch}';
    _registerView();
  }

  void _registerView() {
    ui_web.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
      final iframe = html_lib.IFrameElement()
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.backgroundColor = 'white'
        ..srcdoc = widget.html;
      return iframe;
    });
  }

  @override
  void didUpdateWidget(covariant _WebPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.html != widget.html) {
      _viewType = 'web-render-preview-${DateTime.now().millisecondsSinceEpoch}';
      _registerView();
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return HtmlElementView(viewType: _viewType);
  }
}
