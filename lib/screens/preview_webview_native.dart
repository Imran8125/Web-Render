// Native implementation: renders HTML using webview_flutter + local HTTP server
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:webview_flutter/webview_flutter.dart';
import '../services/storage_service.dart';

/// Builds a native WebView widget to render HTML content.
Widget buildPreviewWidget({
  required String html,
  required void Function(String) onLog,
  required String appId,
  Key? key,
}) {
  return _NativePreview(key: key, html: html, onLog: onLog, appId: appId);
}

class _NativePreview extends StatefulWidget {
  final String html;
  final void Function(String) onLog;
  final String appId;

  const _NativePreview({
    super.key,
    required this.html,
    required this.onLog,
    required this.appId,
  });

  @override
  State<_NativePreview> createState() => _NativePreviewState();
}

class _NativePreviewState extends State<_NativePreview> {
  late WebViewController _controller;
  late StorageService _storage;
  bool _isLoading = true;
  HttpServer? _server;
  int _port = 0;

  @override
  void initState() {
    super.initState();
    _storage = StorageService(widget.appId);
    _startServerAndInit();
  }

  @override
  void dispose() {
    _server?.close(force: true);
    super.dispose();
  }

  Future<void> _startServerAndInit() async {
    // Pre-load all storage items for synchronous JS access
    final items = await _storage.getAllItems();
    final storageJson = jsonEncode(items);
    final injectedHtml = _injectScripts(widget.html, storageJson);

    // Start a local HTTP server on a random available port
    final handler = const shelf.Pipeline().addHandler((shelf.Request request) {
      return shelf.Response.ok(
        injectedHtml,
        headers: {
          'Content-Type': 'text/html; charset=utf-8',
          // Allow the page to fetch any origin
          'Access-Control-Allow-Origin': '*',
        },
      );
    });

    _server = await shelf_io.serve(handler, InternetAddress.loopbackIPv4, 0);
    _port = _server!.port;
    debugPrint('Preview server running on http://127.0.0.1:$_port');

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (_) {
          if (mounted) setState(() => _isLoading = false);
        },
        onNavigationRequest: (NavigationRequest request) {
          // Let the preview page navigate freely (opens links, etc.)
          return NavigationDecision.navigate;
        },
      ))
      // Console capture channel
      ..addJavaScriptChannel(
        'ConsoleLog',
        onMessageReceived: (message) {
          widget.onLog(message.message);
        },
      )
      // Storage bridge channels
      ..addJavaScriptChannel(
        'StorageSetItem',
        onMessageReceived: (message) {
          try {
            final data = jsonDecode(message.message);
            _storage.setItem(data['key'] as String, data['value'] as String);
          } catch (e) {
            debugPrint('StorageSetItem error: $e');
          }
        },
      )
      ..addJavaScriptChannel(
        'StorageRemoveItem',
        onMessageReceived: (message) {
          _storage.removeItem(message.message);
        },
      )
      ..addJavaScriptChannel(
        'StorageClear',
        onMessageReceived: (message) {
          _storage.clear();
        },
      )
      ..loadRequest(Uri.parse('http://127.0.0.1:$_port/'));

    if (mounted) setState(() {});
  }

  String _injectScripts(String htmlContent, String storageJson) {
    final script = '''
<script>
(function() {
  // ── Console capture ──
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

  // ── localStorage bridge ──
  var _store = $storageJson;
  var _localStorage = {
    getItem: function(key) {
      return _store.hasOwnProperty(key) ? _store[key] : null;
    },
    setItem: function(key, value) {
      key = String(key);
      value = String(value);
      _store[key] = value;
      if (window.StorageSetItem) {
        StorageSetItem.postMessage(JSON.stringify({key: key, value: value}));
      }
    },
    removeItem: function(key) {
      key = String(key);
      delete _store[key];
      if (window.StorageRemoveItem) {
        StorageRemoveItem.postMessage(key);
      }
    },
    clear: function() {
      _store = {};
      if (window.StorageClear) {
        StorageClear.postMessage('clear');
      }
    },
    get length() {
      return Object.keys(_store).length;
    },
    key: function(index) {
      var keys = Object.keys(_store);
      return index >= 0 && index < keys.length ? keys[index] : null;
    }
  };

  // Also provide sessionStorage (same backing, since apps are short-lived)
  try {
    Object.defineProperty(window, 'localStorage', {
      get: function() { return _localStorage; },
      configurable: true
    });
    Object.defineProperty(window, 'sessionStorage', {
      get: function() { return _localStorage; },
      configurable: true
    });
  } catch(e) {
    window.localStorage = _localStorage;
    window.sessionStorage = _localStorage;
  }
})();
</script>
''';
    // Inject before </head>; if no </head>, prepend the script
    if (htmlContent.contains('</head>')) {
      return htmlContent.replaceFirst('</head>', '$script</head>');
    }
    return '$script$htmlContent';
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (_port > 0) WebViewWidget(controller: _controller),
        if (_isLoading)
          const Center(
            child: CircularProgressIndicator(color: Color(0xFFFFFFFF)),
          ),
      ],
    );
  }
}
