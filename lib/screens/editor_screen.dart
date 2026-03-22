import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/web_app.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';
import 'preview_screen.dart';

class EditorScreen extends StatefulWidget {
  final String appId;

  const EditorScreen({super.key, required this.appId});

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  late TextEditingController _htmlController;
  late TextEditingController _titleController;
  WebApp? _app;
  bool _hasChanges = false;

  final List<String> _quickInsertChars = [
    '<',
    '>',
    '/',
    '=',
    '"',
    '{',
    '}',
    '(',
    ')',
    ';',
    ':',
    '.',
    '#',
  ];

  @override
  void initState() {
    super.initState();
    _htmlController = TextEditingController();
    _titleController = TextEditingController();
    _loadApp();
  }

  Future<void> _loadApp() async {
    final state = context.read<AppState>();
    final app = state.apps.firstWhere((a) => a.id == widget.appId);
    setState(() {
      _app = app;
      _htmlController.text = app.htmlCode;
      _titleController.text = app.title;
    });
  }

  void _markChanged() {
    if (!_hasChanges) setState(() => _hasChanges = true);
  }

  Future<void> _saveApp() async {
    if (_app == null) return;
    _app!.title = _titleController.text.trim();
    _app!.htmlCode = _htmlController.text;
    await context.read<AppState>().updateApp(_app!);
    setState(() => _hasChanges = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Saved!', style: GoogleFonts.spaceGrotesk()),
          backgroundColor: AppTheme.elevatedGray,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  void _runApp() {
    if (_app == null) return;
    // Update app with current editor contents before running
    _app!.title = _titleController.text.trim();
    _app!.htmlCode = _htmlController.text;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PreviewScreen(app: _app!)),
    );
  }

  void _insertChar(String char) {
    final controller = _htmlController;
    final text = controller.text;
    final selection = controller.selection;
    final newText = text.replaceRange(selection.start, selection.end, char);
    controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: selection.start + char.length),
    );
    _markChanged();
  }

  @override
  void dispose() {
    _htmlController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_app == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.primaryWhite),
        ),
      );
    }

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (_hasChanges) _saveApp();
      },
      child: Scaffold(
        appBar: AppBar(
          title: SizedBox(
            width: 200,
            child: TextField(
              controller: _titleController,
              style: GoogleFonts.spaceGrotesk(
                color: AppTheme.pureWhite,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                fillColor: Colors.transparent,
                filled: true,
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: (_) => _markChanged(),
            ),
          ),
          actions: [
            if (_hasChanges)
              IconButton(
                icon: const Icon(Icons.save_rounded),
                onPressed: _saveApp,
                tooltip: 'Save',
                color: AppTheme.primaryWhite,
              ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: AppTheme.lightSilver),
              color: AppTheme.elevatedGray,
              onSelected: (value) {
                if (value == 'save') _saveApp();
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'save',
                  child: Row(
                    children: [
                      Icon(Icons.save, color: AppTheme.lightSilver, size: 20),
                      SizedBox(width: 8),
                      Text('Save', style: TextStyle(color: AppTheme.pureWhite)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        body: Column(
          children: [
            // Code editor
            Expanded(
              child: _buildCodeEditor(_htmlController),
            ),
            // Quick insert toolbar
            _buildQuickInsertToolbar(),
          ],
        ),
        floatingActionButton: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryWhite.withAlpha(80),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: FloatingActionButton.extended(
            onPressed: _runApp,
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('Run'),
            tooltip: 'Run App',
          ),
        ),
      ),
    );
  }

  Widget _buildCodeEditor(TextEditingController controller) {
    return Container(
      color: AppTheme.editorBg,
      child: SingleChildScrollView(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Line numbers
            Container(
              width: 44,
              color: AppTheme.editorBg,
              padding: const EdgeInsets.only(top: 12, right: 8),
              child: ValueListenableBuilder(
                valueListenable: controller,
                builder: (context, value, _) {
                  final lines = '\n'.allMatches(value.text).length + 1;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: List.generate(
                      lines.clamp(1, 500),
                      (i) => SizedBox(
                        height: 20,
                        child: Text(
                          '${i + 1}',
                          style: GoogleFonts.jetBrainsMono(
                            color: AppTheme.syntaxGray,
                            fontSize: 13,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Container(width: 1, color: AppTheme.syntaxGray.withAlpha(40)),
            // Code text field
            Expanded(
              child: TextField(
                controller: controller,
                maxLines: null,
                keyboardType: TextInputType.multiline,
                style: GoogleFonts.jetBrainsMono(
                  color: AppTheme.pureWhite,
                  fontSize: 13,
                  height: 1.5,
                ),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  fillColor: Colors.transparent,
                  filled: true,
                  contentPadding: EdgeInsets.fromLTRB(12, 12, 12, 12),
                ),
                onChanged: (_) => _markChanged(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickInsertToolbar() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        border: Border(
          top: BorderSide(color: AppTheme.lightSilver.withAlpha(30)),
        ),
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        separatorBuilder: (_, _) => const SizedBox(width: 4),
        itemCount: _quickInsertChars.length,
        itemBuilder: (context, index) {
          final char = _quickInsertChars[index];
          return Material(
            color: AppTheme.elevatedGray,
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => _insertChar(char),
              child: Container(
                width: 36,
                alignment: Alignment.center,
                child: Text(
                  char,
                  style: GoogleFonts.jetBrainsMono(
                    color: AppTheme.primaryWhite,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
