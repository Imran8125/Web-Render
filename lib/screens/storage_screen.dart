import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/web_app.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';

class StorageScreen extends StatefulWidget {
  final WebApp app;

  const StorageScreen({super.key, required this.app});

  @override
  State<StorageScreen> createState() => _StorageScreenState();
}

class _StorageScreenState extends State<StorageScreen> {
  late StorageService _storage;
  Map<String, String> _items = {};
  bool _isLoading = true;
  String _formattedSize = '0 B';

  @override
  void initState() {
    super.initState();
    _storage = StorageService(widget.app.id);
    _loadItems();
  }

  Future<void> _loadItems() async {
    setState(() => _isLoading = true);
    final items = await _storage.getAllItems();
    final size = await _storage.getFormattedSize();
    if (mounted) {
      setState(() {
        _items = items;
        _formattedSize = size;
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteItem(String key) async {
    await _storage.removeItem(key);
    _loadItems();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Removed "$key"', style: GoogleFonts.spaceGrotesk()),
          backgroundColor: AppTheme.elevatedGray,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  void _confirmClearAll() {
    if (_items.isEmpty) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear All Storage'),
        content: Text(
          'Delete all ${_items.length} stored items for "${widget.app.title}"?',
          style: const TextStyle(color: AppTheme.lightSilver),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: AppTheme.lightSilver)),
          ),
          FilledButton(
            style:
                FilledButton.styleFrom(backgroundColor: AppTheme.errorColor),
            onPressed: () async {
              Navigator.pop(ctx);
              await _storage.clear();
              _loadItems();
            },
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  void _showValueDialog(String key, String value) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(key,
            style: GoogleFonts.jetBrainsMono(
                color: AppTheme.primaryWhite, fontSize: 14)),
        content: SingleChildScrollView(
          child: Container(
            width: double.maxFinite,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.editorBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: SelectableText(
              value,
              style: GoogleFonts.jetBrainsMono(
                  color: AppTheme.pureWhite, fontSize: 12),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
          FilledButton(
            style:
                FilledButton.styleFrom(backgroundColor: AppTheme.errorColor),
            onPressed: () {
              Navigator.pop(ctx);
              _deleteItem(key);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.app.title,
              style: GoogleFonts.spaceGrotesk(
                  fontSize: 16, fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              'Storage · $_formattedSize',
              style: GoogleFonts.spaceGrotesk(
                  fontSize: 12, color: AppTheme.lightSilver),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_rounded),
            onPressed: _confirmClearAll,
            tooltip: 'Clear All',
            color: _items.isNotEmpty
                ? AppTheme.errorColor
                : AppTheme.syntaxGray,
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadItems,
            tooltip: 'Refresh',
            color: AppTheme.lightSilver,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryWhite))
          : _items.isEmpty
              ? _buildEmptyState()
              : _buildItemsList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.elevatedGray.withAlpha(120),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.storage_rounded,
                size: 48, color: AppTheme.syntaxGray),
          ),
          const SizedBox(height: 20),
          Text(
            'No stored data',
            style: GoogleFonts.spaceGrotesk(
                color: AppTheme.pureWhite,
                fontSize: 18,
                fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'This app hasn\'t stored anything in localStorage yet.',
            style: GoogleFonts.spaceGrotesk(
                color: AppTheme.lightSilver, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildItemsList() {
    final keys = _items.keys.toList();
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: keys.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final key = keys[index];
        final value = _items[key]!;
        return GestureDetector(
          onTap: () => _showValueDialog(key, value),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.elevatedGray.withAlpha(200),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.lightSilver.withAlpha(30)),
            ),
            child: Row(
              children: [
                const Icon(Icons.vpn_key_rounded,
                    size: 16, color: AppTheme.primaryWhite),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        key,
                        style: GoogleFonts.jetBrainsMono(
                            color: AppTheme.primaryWhite, fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        value.length > 80
                            ? '${value.substring(0, 80)}...'
                            : value,
                        style: GoogleFonts.jetBrainsMono(
                            color: AppTheme.lightSilver, fontSize: 11),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      size: 18, color: AppTheme.errorColor),
                  onPressed: () => _deleteItem(key),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'Delete',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
