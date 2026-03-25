// Native implementation: renders HTML using flutter_inappwebview + local HTTP server
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as shelf_io;
import '../services/storage_service.dart';

/// Builds a native InAppWebView widget to render HTML content.
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
  InAppWebViewController? _controller;
  late StorageService _storage;
  bool _isLoading = true;
  HttpServer? _server;
  int _port = 0;

  @override
  void initState() {
    super.initState();
    _storage = StorageService(widget.appId);
    _startServer();
  }

  @override
  void dispose() {
    _server?.close(force: true);
    super.dispose();
  }

  Future<void> _startServer() async {
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
          'Access-Control-Allow-Origin': '*',
        },
      );
    });

    _server = await shelf_io.serve(handler, InternetAddress.loopbackIPv4, 0);
    _port = _server!.port;
    debugPrint('Preview server running on http://127.0.0.1:$_port');

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
    if (window.flutter_inappwebview) {
      window.flutter_inappwebview.callHandler('ConsoleLog', args);
    }
    origLog.apply(console, arguments);
  };
  console.error = function() {
    var args = Array.from(arguments).map(String).join(' ');
    if (window.flutter_inappwebview) {
      window.flutter_inappwebview.callHandler('ConsoleLog', '[ERROR] ' + args);
    }
  };
  window.onerror = function(msg) {
    if (window.flutter_inappwebview) {
      window.flutter_inappwebview.callHandler('ConsoleLog', '[ERROR] ' + msg);
    }
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
      if (window.flutter_inappwebview) {
        window.flutter_inappwebview.callHandler('StorageSetItem', JSON.stringify({key: key, value: value}));
      }
    },
    removeItem: function(key) {
      key = String(key);
      delete _store[key];
      if (window.flutter_inappwebview) {
        window.flutter_inappwebview.callHandler('StorageRemoveItem', key);
      }
    },
    clear: function() {
      _store = {};
      if (window.flutter_inappwebview) {
        window.flutter_inappwebview.callHandler('StorageClear', 'clear');
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
        if (_port > 0)
          InAppWebView(
            initialUrlRequest: URLRequest(
              url: WebUri('http://127.0.0.1:$_port/'),
            ),
            initialSettings: InAppWebViewSettings(
              javaScriptEnabled: true,
              mediaPlaybackRequiresUserGesture: false,
              allowFileAccessFromFileURLs: true,
              allowUniversalAccessFromFileURLs: true,
              useHybridComposition: true,
              // Allow mixed content (http:// resources from http:// origin)
              mixedContentMode: MixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW,
            ),
            onWebViewCreated: (controller) {
              _controller = controller;

              // Console capture handler
              controller.addJavaScriptHandler(
                handlerName: 'ConsoleLog',
                callback: (args) {
                  if (args.isNotEmpty) widget.onLog(args[0].toString());
                },
              );

              // Storage bridge handlers
              controller.addJavaScriptHandler(
                handlerName: 'StorageSetItem',
                callback: (args) {
                  if (args.isNotEmpty) {
                    try {
                      final data = jsonDecode(args[0].toString());
                      _storage.setItem(
                        data['key'] as String,
                        data['value'] as String,
                      );
                    } catch (e) {
                      debugPrint('StorageSetItem error: $e');
                    }
                  }
                },
              );

              controller.addJavaScriptHandler(
                handlerName: 'StorageRemoveItem',
                callback: (args) {
                  if (args.isNotEmpty) {
                    _storage.removeItem(args[0].toString());
                  }
                },
              );

              controller.addJavaScriptHandler(
                handlerName: 'StorageClear',
                callback: (args) {
                  _storage.clear();
                },
              );
            },
            onLoadStop: (controller, url) {
              if (mounted) setState(() => _isLoading = false);
            },
            shouldOverrideUrlLoading: (controller, navigationAction) async {
              // Let the preview page navigate freely
              return NavigationActionPolicy.ALLOW;
            },
          ),
        if (_isLoading)
          const Center(
            child: CircularProgressIndicator(color: Color(0xFFFFFFFF)),
          ),
      ],
    );
  }
}
