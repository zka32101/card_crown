import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../l10n/app_localizations.dart';
import '../providers/locale_provider.dart';
import '../theme/kingdom_theme.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final locale = ref.watch(localeProvider);

    return Scaffold(
      backgroundColor: Kingdom.night,
      appBar: AppBar(
        title: Text(t.settings_title, style: Kingdom.title(size: 17)),
        backgroundColor: Kingdom.nightDeep,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Kingdom.gilt),
          onPressed: () => context.pop(),
        ),
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: EmotionMoteField(count: 10)),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(Kingdom.spaceLg),
              children: [
                _SectionLabel(t.settings_bonusSection),
                const SizedBox(height: Kingdom.spaceMd),
                _SettingsCard(
                  children: [
                    _SettingsTile(
                      title: t.settings_myBonus,
                      onTap: () => _showComingSoon(context, t.settings_bonusComingSoon),
                    ),
                  ],
                ),
                const SizedBox(height: Kingdom.spaceXxl),

                _SectionLabel(t.settings_purchaseHistorySection),
                const SizedBox(height: Kingdom.spaceMd),
                _SettingsCard(
                  children: [
                    _SettingsTile(
                      title: t.settings_purchaseHistory,
                      onTap: () => _showComingSoon(context, t.settings_purchaseHistoryComingSoon),
                    ),
                  ],
                ),
                const SizedBox(height: Kingdom.spaceXxl),

                _SectionLabel(t.settings_languageSection),
                const SizedBox(height: Kingdom.spaceMd),
                _SettingsCard(
                  children: [
                    _SettingsTile(
                      title: t.settings_japanese,
                      trailingIcon: locale.languageCode == 'ja' ? Icons.check : null,
                      selected: locale.languageCode == 'ja',
                      onTap: () => ref.read(localeProvider.notifier).state = const Locale('ja'),
                    ),
                    _divider(),
                    _SettingsTile(
                      title: t.settings_english,
                      trailingIcon: locale.languageCode == 'en' ? Icons.check : null,
                      selected: locale.languageCode == 'en',
                      onTap: () => ref.read(localeProvider.notifier).state = const Locale('en'),
                    ),
                  ],
                ),
                const SizedBox(height: Kingdom.spaceXxl),

                _SectionLabel(t.settings_infoSection),
                const SizedBox(height: Kingdom.spaceMd),
                _SettingsCard(
                  children: [
                    _SettingsTile(
                      title: t.settings_privacyPolicy,
                      trailingIcon: Icons.open_in_new,
                      onTap: () => _showComingSoon(context, t.settings_linkComingSoon),
                    ),
                    _divider(),
                    _SettingsTile(
                      title: t.settings_termsOfService,
                      trailingIcon: Icons.open_in_new,
                      onTap: () => _showComingSoon(context, t.settings_linkComingSoon),
                    ),
                    _divider(),
                    _SettingsTile(
                      title: t.settings_contactUs,
                      trailingIcon: Icons.open_in_new,
                      onTap: () => _showComingSoon(context, t.settings_contactComingSoon),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() => Divider(height: 1, color: Kingdom.parchment.withValues(alpha: 0.1));

  void _showComingSoon(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(text, style: Kingdom.title(size: Kingdom.textSubheading));
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Kingdom.nightDeep,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Kingdom.parchment.withValues(alpha: 0.12)),
      ),
      child: Column(children: children),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final String title;
  final IconData? trailingIcon;
  final bool selected;
  final VoidCallback? onTap;

  const _SettingsTile({required this.title, this.trailingIcon, this.selected = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title, style: TextStyle(color: Kingdom.parchment)),
      trailing: Icon(
        trailingIcon ?? Icons.chevron_right,
        color: selected ? Kingdom.gilt : Kingdom.parchment.withValues(alpha: 0.4),
      ),
      onTap: onTap,
    );
  }
}
