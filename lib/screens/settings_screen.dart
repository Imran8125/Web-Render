import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        final devMode = state.developerMode;
        return ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            _buildSectionHeader('Developer'),
            _buildDevModeToggle(context, devMode),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                devMode
                    ? 'Console, code editor shortcuts and running status are visible in Preview.'
                    : 'Developer tools are hidden. Preview shows the app without any dev overlays.',
                style: GoogleFonts.spaceGrotesk(
                  color: AppTheme.lightSilver,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 32),
            _buildSectionHeader('About'),
            _buildInfoTile(Icons.info_outline, 'Version', '1.0.0'),
            _buildInfoTile(Icons.code_rounded, 'Built with', 'Flutter + Web'),
          ],
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.spaceGrotesk(
          color: AppTheme.lightSilver,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildDevModeToggle(BuildContext context, bool devMode) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.elevatedGray,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.lightSilver.withAlpha(30)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: devMode
                ? AppTheme.primaryWhite.withAlpha(20)
                : AppTheme.surfaceDark,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            Icons.developer_mode_rounded,
            color: devMode ? AppTheme.primaryWhite : AppTheme.lightSilver,
            size: 20,
          ),
        ),
        title: Text(
          'Developer Mode',
          style: GoogleFonts.spaceGrotesk(
            color: AppTheme.pureWhite,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        subtitle: Text(
          devMode ? 'On' : 'Off',
          style: GoogleFonts.spaceGrotesk(
            color: devMode ? AppTheme.primaryWhite : AppTheme.lightSilver,
            fontSize: 12,
          ),
        ),
        trailing: Switch(
          value: devMode,
          onChanged: (_) => context.read<AppState>().toggleDeveloperMode(),
          activeThumbColor: AppTheme.primaryWhite,
          activeTrackColor: AppTheme.lightSilver.withAlpha(100),
          inactiveThumbColor: AppTheme.lightSilver,
          inactiveTrackColor: AppTheme.surfaceDark,
        ),
        onTap: () => context.read<AppState>().toggleDeveloperMode(),
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.elevatedGray,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.lightSilver.withAlpha(30)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.surfaceDark,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppTheme.lightSilver, size: 20),
        ),
        title: Text(
          label,
          style: GoogleFonts.spaceGrotesk(
            color: AppTheme.pureWhite,
            fontSize: 14,
          ),
        ),
        trailing: Text(
          value,
          style: GoogleFonts.spaceGrotesk(
            color: AppTheme.lightSilver,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
