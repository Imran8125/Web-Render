import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/web_app.dart';
import 'database_service.dart';

class AppState extends ChangeNotifier {
  List<WebApp> _apps = [];
  bool _isLoading = true;

  List<WebApp> get apps => _apps;
  bool get isLoading => _isLoading;

  final _uuid = const Uuid();

  // Predefined accent colors for app cards
  static const List<int> appColors = [
    0xFF00D2FF, // Electric Cyan
    0xFF7B2FF7, // Vibrant Purple
    0xFFFF6B6B, // Coral
    0xFF34D399, // Emerald
    0xFFFBBF24, // Amber
    0xFF38BDF8, // Sky Blue
    0xFFEC4899, // Pink
    0xFFF97316, // Orange
  ];

  Future<void> loadApps() async {
    _isLoading = true;
    notifyListeners();

    _apps = await DatabaseService.getAllApps();

    _isLoading = false;
    notifyListeners();
  }

  Future<WebApp> createApp(String title) async {
    final now = DateTime.now();
    final app = WebApp(
      id: _uuid.v4(),
      title: title,
      htmlCode: _defaultHtml(title),
      createdAt: now,
      updatedAt: now,
      iconColor: appColors[_apps.length % appColors.length],
    );

    await DatabaseService.insertApp(app);
    _apps.insert(0, app);
    notifyListeners();
    return app;
  }

  Future<void> updateApp(WebApp app) async {
    await DatabaseService.updateApp(app);
    final index = _apps.indexWhere((a) => a.id == app.id);
    if (index != -1) {
      _apps[index] = app;
      notifyListeners();
    }
  }

  Future<void> deleteApp(String id) async {
    await DatabaseService.deleteApp(id);
    _apps.removeWhere((a) => a.id == id);
    notifyListeners();
  }

  String _defaultHtml(String title) =>
      '''<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>$title</title>
  <style>
    * {
      margin: 0;
      padding: 0;
      box-sizing: border-box;
    }

    body {
      font-family: 'Segoe UI', sans-serif;
      background: #f0f4f8;
      display: flex;
      justify-content: center;
      align-items: center;
      min-height: 100vh;
    }

    .container {
      background: white;
      padding: 2rem;
      border-radius: 16px;
      box-shadow: 0 4px 24px rgba(0,0,0,0.1);
      text-align: center;
      max-width: 400px;
      width: 90%;
    }

    h1 { color: #1a1a2e; margin-bottom: 1rem; }
    p  { color: #64748b; margin-bottom: 1rem; }

    button {
      background: #00d2ff;
      color: white;
      border: none;
      padding: 12px 32px;
      border-radius: 8px;
      font-size: 1rem;
      cursor: pointer;
      transition: transform 0.2s;
    }
    button:hover { transform: scale(1.05); }

    #output { margin-top: 1rem; font-weight: bold; color: #7b2ff7; }
  </style>
</head>
<body>
  <div class="container">
    <h1>$title</h1>
    <p>Start building your app here!</p>
    <button id="btn" onclick="greet()">Click Me</button>
    <p id="output"></p>
  </div>

  <script>
    function greet() {
      document.getElementById('output').textContent = 'Hello from Web-Render! 🚀';
    }
  </script>
</body>
</html>''';
}
