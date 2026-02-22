// Native implementation: renders HTML using webview_flutter
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Builds a native WebView widget to render HTML content.
Widget buildPreviewWidget({
  required String html,
  required void Function(String) onLog,
  Key? key,
}) {
  return _NativePreview(key: key, html: html, onLog: onLog);
}

class _NativePreview extends StatefulWidget {
  final String html;
  final void Function(String) onLog;

  const _NativePreview({super.key, required this.html, required this.onLog});

  @override
  State<_NativePreview> createState() => _NativePreviewState();
}

class _NativePreviewState extends State<_NativePreview> {
  late WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  void _initController() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (_) {
          if (mounted) setState(() => _isLoading = false);
        },
      ))
      ..addJavaScriptChannel(
        'ConsoleLog',
        onMessageReceived: (message) {
          widget.onLog(message.message);
        },
      )
      ..loadHtmlString(_injectConsoleCapture(widget.html));
  }

  String _injectConsoleCapture(String htmlContent) {
    const captureScript = '''
<script>
  (function() {
    var origLog = console.log;
    console.log = function() {
      var args = Array.from(arguments).map(String).join(' ');
      if (window.ConsoleLog) ConsoleLog.postMessage(args);
      origLog.apply(console, arguments);
    };
    console.error = function() {
      var args = Array.from(arguments).map(String).join(' ');
      if (window.ConsoleLog) ConsoleLog.postMessage('[ERROR] ' + args);
    };
    window.onerror = function(msg) {
      if (window.ConsoleLog) ConsoleLog.postMessage('[ERROR] ' + msg);
    };
  })();
</script>
''';
    return htmlContent.replaceFirst('</head>', '$captureScript</head>');
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        WebViewWidget(controller: _controller),
        if (_isLoading)
          const Center(
            child: CircularProgressIndicator(color: Color(0xFF00D2FF)),
          ),
      ],
    );
  }
}
