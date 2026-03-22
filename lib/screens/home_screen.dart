import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/web_app.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';
import 'editor_screen.dart';
import 'preview_screen.dart';
import 'preview_webview_native.dart' if (dart.library.html) 'preview_webview_web.dart';
import 'settings_screen.dart';
import 'storage_screen.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedNavIndex = 0;

  @override
  void initState() {
    super.initState();
    context.read<AppState>().loadApps();
  }

  void _showCreateDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create New App'),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: AppTheme.pureWhite),
          decoration: const InputDecoration(hintText: 'Enter app name...'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppTheme.lightSilver),
            ),
          ),
          FilledButton(
            onPressed: () async {
              final title = controller.text.trim();
              if (title.isNotEmpty) {
                Navigator.pop(ctx);
                final app = await context.read<AppState>().createApp(title);
                if (mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EditorScreen(appId: app.id),
                    ),
                  );
                }
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(WebApp app) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete App'),
        content: Text(
          'Are you sure you want to delete "${app.title}"?',
          style: const TextStyle(color: AppTheme.lightSilver),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppTheme.lightSilver),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            onPressed: () {
              context.read<AppState>().deleteApp(app.id);
              Navigator.pop(ctx);
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
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/Logo.png',
                width: 32,
                height: 32,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 10),
            const Text('Web-Render'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: AppTheme.lightSilver),
            onPressed: () {},
            tooltip: 'Search',
          ),
        ],
      ),
      body: Consumer<AppState>(
        builder: (context, state, child) {
          if (_selectedNavIndex == 2) {
            return const SettingsScreen();
          }
          if (state.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryWhite),
            );
          }
          return _buildBody(state);
        },
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
          onPressed: _showCreateDialog,
          icon: const Icon(Icons.add),
          label: const Text('New App'),
          tooltip: 'Create New App',
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedNavIndex,
        onDestinationSelected: (i) => setState(() => _selectedNavIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.apps_rounded),
            selectedIcon: Icon(Icons.apps_rounded),
            label: 'My Apps',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_awesome_outlined),
            selectedIcon: Icon(Icons.auto_awesome),
            label: 'Templates',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  Widget _buildBody(AppState state) {
    if (state.apps.isEmpty) {
      return _buildEmptyState();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Stats row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Flexible(
                child: _buildChip(Icons.apps, '${state.apps.length} Apps'),
              ),
              const SizedBox(width: 8),
              if (state.apps.isNotEmpty)
                Flexible(
                  child: _buildChip(
                    Icons.access_time,
                    'Last edited: ${_timeAgo(state.apps.first.updatedAt)}',
                  ),
                ),
            ],
          ),
        ),
        // App grid
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.75,
            ),
            itemCount: state.apps.length,
            itemBuilder: (context, index) => _buildAppCard(state.apps[index]),
          ),
        ),
      ],
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
            child: const Icon(
              Icons.code_rounded,
              size: 64,
              color: AppTheme.primaryWhite,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No apps yet',
            style: GoogleFonts.spaceGrotesk(
              color: AppTheme.pureWhite,
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first HTML/CSS/JS app',
            style: GoogleFonts.spaceGrotesk(
              color: AppTheme.lightSilver,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: _showCreateDialog,
            icon: const Icon(Icons.add),
            label: const Text('Create App'),
          ),
        ],
      ),
    );
  }

  Widget _buildAppCard(WebApp app) {
    final cardColor = Color(app.iconColor);
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => PreviewScreen(app: app)),
      ),
      onLongPress: () => _showDeleteDialog(app),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.elevatedGray.withAlpha(200),
                  AppTheme.surfaceDark.withAlpha(160),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cardColor.withAlpha(50), width: 1),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 4, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Icon
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: cardColor.withAlpha(30),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.web, color: cardColor, size: 24),
                      ),
                      // Options menu
                      Theme(
                        data: Theme.of(context).copyWith(
                          splashColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                        ),
                        child: PopupMenuButton<String>(
                          icon: const Icon(Icons.more_horiz, color: AppTheme.lightSilver),
                          color: AppTheme.deepBlack,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: AppTheme.primaryWhite.withAlpha(30)),
                          ),
                          offset: const Offset(0, 40),
                          onSelected: (value) {
                            if (value == 'edit') {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => EditorScreen(appId: app.id)),
                              );
                            } else if (value == 'storage') {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => StorageScreen(app: app)),
                              );
                            } else if (value == 'delete') {
                              _showDeleteDialog(app);
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  const Icon(Icons.edit, color: AppTheme.lightSilver, size: 20),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Edit',
                                    style: GoogleFonts.spaceGrotesk(color: AppTheme.pureWhite),
                                  ),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'storage',
                              child: Row(
                                children: [
                                  const Icon(Icons.storage_rounded, color: AppTheme.lightSilver, size: 20),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Storage',
                                    style: GoogleFonts.spaceGrotesk(color: AppTheme.pureWhite),
                                  ),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  const Icon(Icons.delete, color: AppTheme.errorColor, size: 20),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Delete',
                                    style: GoogleFonts.spaceGrotesk(color: AppTheme.errorColor),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Title
                  Text(
                    app.title,
                    style: GoogleFonts.spaceGrotesk(
                      color: AppTheme.pureWhite,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _timeAgo(app.updatedAt),
                    style: GoogleFonts.spaceGrotesk(
                      color: AppTheme.lightSilver,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Code preview
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      clipBehavior: Clip.hardEdge,
                      decoration: BoxDecoration(
                        color: AppTheme.editorBg.withAlpha(180),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          buildPreviewWidget(
                            html: app.htmlCode,
                            onLog: (_) {},
                            appId: app.id,
                            key: ValueKey('preview_card_${app.id}'),
                          ),
                          Container(color: Colors.transparent),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.elevatedGray.withAlpha(150),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.lightSilver.withAlpha(40)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.primaryWhite),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: GoogleFonts.spaceGrotesk(
                color: AppTheme.lightSilver,
                fontSize: 12,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${date.day}/${date.month}/${date.year}';
  }
}
