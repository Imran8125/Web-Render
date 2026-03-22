// Web implementation: renders HTML in an iframe using dart:html
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html_lib;
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';

/// Builds a web preview widget using an iframe to render HTML content.
/// On web, iframes already have access to real localStorage.
Widget buildPreviewWidget({
  required String html,
  required void Function(String) onLog,
  required String appId,
  Key? key,
}) {
  return _WebPreview(key: key, html: html, onLog: onLog, appId: appId);
}

class _WebPreview extends StatefulWidget {
  final String html;
  final void Function(String) onLog;
  final String appId;

  const _WebPreview({super.key, required this.html, required this.onLog, required this.appId});

  @override
  State<_WebPreview> createState() => _WebPreviewState();
}

class _WebPreviewState extends State<_WebPreview> {
  late String _viewType;

  @override
  void initState() {
    super.initState();
    _viewType = 'web-render-preview-${widget.appId}-${DateTime.now().microsecondsSinceEpoch}';
    _registerView();
  }

  void _registerView() {
    ui_web.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
      final iframe = html_lib.IFrameElement()
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.backgroundColor = 'black'
        ..srcdoc = widget.html;
      return iframe;
    });
  }

  @override
  void didUpdateWidget(covariant _WebPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.html != widget.html || oldWidget.appId != widget.appId) {
      _viewType = 'web-render-preview-${widget.appId}-${DateTime.now().microsecondsSinceEpoch}';
      _registerView();
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return HtmlElementView(viewType: _viewType);
  }
}
