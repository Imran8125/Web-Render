import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/web_app.dart';
import 'database_service.dart';

class AppState extends ChangeNotifier {
  List<WebApp> _apps = [];
  bool _isLoading = true;

  List<WebApp> get apps => _apps;
  bool get isLoading => _isLoading;

  bool _developerMode = false;
  bool get developerMode => _developerMode;

  void toggleDeveloperMode() {
    _developerMode = !_developerMode;
    notifyListeners();
  }

  final _uuid = const Uuid();

  // Predefined accent colors for app cards (Black/White/Silver)
  static const List<int> appColors = [
    0xFFFFFFFF, // Pure White
    0xFFE0E0E0, // Light Silver
    0xFFD4D4D4, // Silver
    0xFFA3A3A3, // Gray
    0xFF737373, // Dark Gray
    0xFF525252, // Deep Gray
    0xFF404040, // Deeper Gray
    0xFF262626, // Almost Black
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
      font-family: 'Inter', 'Segoe UI', sans-serif;
      background: #000000;
      color: #FFFFFF;
      display: flex;
      justify-content: center;
      align-items: center;
      min-height: 100vh;
    }

    .container {
      background: #1A1A1A;
      padding: 2.5rem;
      border-radius: 12px;
      box-shadow: 0 8px 32px rgba(255, 255, 255, 0.05);
      border: 1px solid #333333;
      text-align: center;
      max-width: 420px;
      width: 90%;
    }

    h1 { color: #FFFFFF; margin-bottom: 1rem; font-weight: 600; letter-spacing: -0.5px; }
    p  { color: #A1A19A; margin-bottom: 1.5rem; line-height: 1.5; }

    button {
      background: #FFFFFF;
      color: #000000;
      border: none;
      padding: 12px 32px;
      border-radius: 8px;
      font-size: 1rem;
      font-weight: 600;
      cursor: pointer;
      transition: all 0.2s ease;
    }
    button:hover { 
      transform: translateY(-2px);
      box-shadow: 0 4px 12px rgba(255, 255, 255, 0.2);
    }

    #output { margin-top: 1.5rem; font-weight: 500; color: #E0E0E0; }
  </style>
</head>
<body>
  <div class="container">
    <h1>$title</h1>
    <p>A sophisticated canvas for your next creation.</p>
    <button id="btn" onclick="greet()">Initialize</button>
    <p id="output"></p>
  </div>

  <script>
    function greet() {
      document.getElementById('output').textContent = 'System initialized. ⚡';
    }
  </script>
</body>
</html>''';
}
