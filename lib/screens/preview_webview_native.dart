// Native implementation: renders HTML using webview_flutter
import 'dart:convert';
import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    _storage = StorageService(widget.appId);
    _initController();
  }

  Future<void> _initController() async {
    // Pre-load all storage items for synchronous JS access
    final items = await _storage.getAllItems();
    final storageJson = jsonEncode(items);

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (_) {
          if (mounted) setState(() => _isLoading = false);
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
      ..loadHtmlString(
          _injectScripts(widget.html, storageJson));

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
    return htmlContent.replaceFirst('</head>', '$script</head>');
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        WebViewWidget(controller: _controller),
        if (_isLoading)
          const Center(
            child: CircularProgressIndicator(color: Color(0xFFFFFFFF)),
          ),
      ],
    );
  }
}
