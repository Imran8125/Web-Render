import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/web_app.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';
import 'preview_webview_native.dart' if (dart.library.html) 'preview_webview_web.dart';
import 'storage_screen.dart';

class PreviewScreen extends StatefulWidget {
  final WebApp app;

  const PreviewScreen({super.key, required this.app});

  @override
  State<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends State<PreviewScreen> {
  bool _consoleExpanded = false;
  final List<String> _consoleLogs = [];

  void _addLog(String message) {
    setState(() => _consoleLogs.add(message));
  }

  void _refresh() {
    setState(() => _consoleLogs.clear());
  }

  @override
  Widget build(BuildContext context) {
    final devMode = context.watch<AppState>().developerMode;
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.app.title,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              'Preview',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 12,
                color: AppTheme.lightSilver,
              ),
            ),
          ],
        ),
        actions: [
          if (devMode)
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: _refresh,
              tooltip: 'Refresh',
              color: AppTheme.lightSilver,
            ),
          if (devMode)
            IconButton(
              icon: const Icon(Icons.storage_rounded),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => StorageScreen(app: widget.app),
                ),
              ),
              tooltip: 'App Storage',
              color: AppTheme.lightSilver,
            ),
          if (devMode)
            IconButton(
              icon: const Icon(Icons.code_rounded),
              onPressed: () => Navigator.pop(context),
              tooltip: 'Edit Code',
              color: AppTheme.lightSilver,
            ),
        ],
      ),
      body: Column(
        children: [
          // Device info bar (only in dev mode)
          if (devMode)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              color: AppTheme.surfaceDark,
              child: Row(
                children: [
                  const Icon(
                    Icons.phone_android,
                    size: 14,
                    color: AppTheme.lightSilver,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Preview Mode',
                    style: GoogleFonts.spaceGrotesk(
                      color: AppTheme.lightSilver,
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.syntax1.withAlpha(30),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Running',
                      style: GoogleFonts.spaceGrotesk(
                        color: AppTheme.syntax1,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          // Rendered WebView / iframe content area
          Expanded(
            child: buildPreviewWidget(
              html: widget.app.htmlCode,
              onLog: _addLog,
              appId: widget.app.id,
              key: ValueKey('preview_${widget.app.id}'),
            ),
          ),
          // Console panel (dev only)
          if (devMode) _buildConsolePanel(),
          // Bottom action bar (dev only)
          if (devMode)
            SafeArea(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceDark,
                  border: Border(
                    top: BorderSide(color: AppTheme.lightSilver.withAlpha(30)),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.code, size: 18),
                        label: const Text('Edit Code'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.pureWhite,
                          side: const BorderSide(color: AppTheme.lightSilver),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Share coming soon!',
                                style: GoogleFonts.spaceGrotesk(),
                              ),
                              backgroundColor: AppTheme.elevatedGray,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        icon: const Icon(Icons.share, size: 18),
                        label: const Text('Share'),
                        style: FilledButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildConsolePanel() {
    final errorCount = _consoleLogs.where((l) => l.contains('[ERROR]')).length;
    final logCount = _consoleLogs.length - errorCount;

    return GestureDetector(
      onTap: () => setState(() => _consoleExpanded = !_consoleExpanded),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        height: _consoleExpanded ? 201 : 41,
        decoration: BoxDecoration(
          color: AppTheme.editorBg,
          border: Border(
            top: BorderSide(color: AppTheme.lightSilver.withAlpha(30)),
          ),
        ),
        child: Column(
          children: [
            Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  const Icon(
                    Icons.terminal,
                    size: 16,
                    color: AppTheme.lightSilver,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Console',
                    style: GoogleFonts.spaceGrotesk(
                      color: AppTheme.lightSilver,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '$logCount logs',
                    style: GoogleFonts.spaceGrotesk(
                      color: AppTheme.syntax1,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$errorCount errors',
                    style: GoogleFonts.spaceGrotesk(
                      color: errorCount > 0
                          ? AppTheme.errorColor
                          : AppTheme.syntaxGray,
                      fontSize: 11,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    _consoleExpanded
                        ? Icons.keyboard_arrow_down
                        : Icons.keyboard_arrow_up,
                    color: AppTheme.lightSilver,
                    size: 20,
                  ),
                ],
              ),
            ),
            if (_consoleExpanded)
              Expanded(
                child: _consoleLogs.isEmpty
                    ? Center(
                        child: Text(
                          'No console output',
                          style: GoogleFonts.jetBrainsMono(
                            color: AppTheme.syntaxGray,
                            fontSize: 12,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: _consoleLogs.length,
                        itemBuilder: (context, index) {
                          final log = _consoleLogs[index];
                          final isError = log.contains('[ERROR]');
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Text(
                              log,
                              style: GoogleFonts.jetBrainsMono(
                                color: isError
                                    ? AppTheme.errorColor
                                    : AppTheme.syntax1,
                                fontSize: 11,
                              ),
                            ),
                          );
                        },
                      ),
              ),
          ],
        ),
      ),
    );
  }
}
