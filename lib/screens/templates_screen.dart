import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/app_prompt.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';

class TemplatesScreen extends StatefulWidget {
  const TemplatesScreen({super.key});

  @override
  State<TemplatesScreen> createState() => _TemplatesScreenState();
}

class _TemplatesScreenState extends State<TemplatesScreen> {

  void _showPromptDialog({AppPrompt? prompt}) {
    final titleController = TextEditingController(text: prompt?.title);
    final contentController = TextEditingController(text: prompt?.content);
    final isEditing = prompt != null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              isEditing ? 'Edit Prompt' : 'New Prompt',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 20,
                color: AppTheme.pureWhite,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: titleController,
              style: const TextStyle(color: AppTheme.pureWhite),
              decoration: const InputDecoration(
                labelText: 'Title',
                labelStyle: TextStyle(color: AppTheme.lightSilver),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.lightSilver)),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.pureWhite)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: contentController,
              maxLines: 8,
              style: const TextStyle(color: AppTheme.pureWhite),
              decoration: const InputDecoration(
                labelText: 'Prompt Content',
                labelStyle: TextStyle(color: AppTheme.lightSilver),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.lightSilver)),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.pureWhite)),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel', style: TextStyle(color: AppTheme.lightSilver)),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.pureWhite,
                    foregroundColor: AppTheme.deepBlack,
                  ),
                  onPressed: () {
                    final title = titleController.text.trim();
                    final content = contentController.text.trim();
                    if (title.isNotEmpty && content.isNotEmpty) {
                      if (isEditing) {
                        prompt.title = title;
                        prompt.content = content;
                        context.read<AppState>().updatePrompt(prompt);
                      } else {
                        context.read<AppState>().createPrompt(title, content);
                      }
                      Navigator.pop(ctx);
                    }
                  },
                  child: Text(isEditing ? 'Save' : 'Create'),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(AppPrompt prompt) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: Text('Delete Prompt', style: GoogleFonts.spaceGrotesk(color: AppTheme.pureWhite)),
        content: Text(
          'Are you sure you want to delete "${prompt.title}"?',
          style: GoogleFonts.inter(color: AppTheme.lightSilver),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.lightSilver)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppTheme.errorColor),
            onPressed: () {
              context.read<AppState>().deletePrompt(prompt.id);
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
    return Consumer<AppState>(
      builder: (context, state, child) {
        if (state.prompts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.description_outlined, size: 64, color: AppTheme.lightSilver),
                const SizedBox(height: 16),
                Text(
                  'No prompts found.',
                  style: GoogleFonts.spaceGrotesk(color: AppTheme.pureWhite, fontSize: 18),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.pureWhite,
                    foregroundColor: AppTheme.deepBlack,
                  ),
                  onPressed: () => _showPromptDialog(),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Prompt'),
                ),
              ],
            ),
          );
        }

        return Stack(
          children: [
            ListView.builder(
              padding: const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 80),
              itemCount: state.prompts.length,
              itemBuilder: (context, index) {
                final prompt = state.prompts[index];
                return _buildPromptCard(prompt);
              },
            ),
            Positioned(
              bottom: 16,
              right: 16,
              child: FloatingActionButton.extended(
                heroTag: 'add_prompt_fab',
                backgroundColor: AppTheme.pureWhite,
                foregroundColor: AppTheme.deepBlack,
                onPressed: () => _showPromptDialog(),
                icon: const Icon(Icons.add),
                label: const Text('New Prompt'),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPromptCard(AppPrompt prompt) {
    return Card(
      color: AppTheme.elevatedGray.withAlpha(150),
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppTheme.lightSilver.withAlpha(30)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showPromptDialog(prompt: prompt),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      prompt.title,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 18,
                        color: AppTheme.pureWhite,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.copy, color: AppTheme.lightSilver, size: 20),
                        onPressed: () async {
                          await Clipboard.setData(ClipboardData(text: prompt.content));
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Prompt copied!', style: GoogleFonts.inter(color: AppTheme.pureWhite)),
                                backgroundColor: AppTheme.surfaceDark,
                                behavior: SnackBarBehavior.floating,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                        tooltip: 'Copy',
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, color: AppTheme.lightSilver, size: 20),
                        onPressed: () => _showPromptDialog(prompt: prompt),
                        tooltip: 'Edit',
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: AppTheme.errorColor, size: 20),
                        onPressed: () => _showDeleteDialog(prompt),
                        tooltip: 'Delete',
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                prompt.content,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppTheme.lightSilver,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
