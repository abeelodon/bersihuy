import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/routes/app_routes.dart';
import '../../../shared/widgets/staff_premium_widgets.dart';

class StaffSettingsScreen extends StatefulWidget {
  const StaffSettingsScreen({super.key});

  @override
  State<StaffSettingsScreen> createState() => _StaffSettingsScreenState();
}

class _StaffSettingsScreenState extends State<StaffSettingsScreen> {
  bool _notifTugas = true;
  bool _notifJadwal = true;
  bool _notifAdmin = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Pengaturan',
          style: AppTextStyles.headlineSmall.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.onSurface,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: AppColors.outlineVariant, height: 1.0),
        ),
      ),
      body: PremiumStaffBackground(
        child: SafeArea(
          child: Center(
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 460),
              child: ScrollConfiguration(
                behavior: ScrollConfiguration.of(
                  context,
                ).copyWith(scrollbars: false),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(22, 24, 22, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // KEAMANAN
                      _buildSectionLabel('KEAMANAN'),
                      const SizedBox(height: 8),
                      _buildMenuCard(
                        children: [
                          _buildNavItem(
                            icon: Icons.security,
                            iconBgColor: AppColors.primary.withValues(
                              alpha: 0.12,
                            ),
                            iconColor: AppColors.primary,
                            label: 'Keamanan Akun',
                            onTap: () => Navigator.pushNamed(
                              context,
                              AppRoutes.securityAccount,
                            ),
                          ),
                          Divider(height: 1, color: AppColors.outlineVariant),
                          _buildNavItem(
                            customIcon: _buildGoogleIcon(),
                            iconBgColor: AppColors.outline.withValues(
                              alpha: 0.12,
                            ),
                            label: 'Kelola Login Google',
                            onTap: () {
                              // Future implementation: Google login management
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // NOTIFIKASI
                      _buildSectionLabel('NOTIFIKASI'),
                      const SizedBox(height: 8),
                      _buildMenuCard(
                        children: [
                          _buildToggleItem(
                            icon: Icons.assignment,
                            iconBgColor: AppColors.primary.withValues(
                              alpha: 0.12,
                            ),
                            iconColor: AppColors.primary,
                            label: 'Notifikasi Tugas',
                            value: _notifTugas,
                            onChanged: (v) => setState(() => _notifTugas = v),
                          ),
                          Divider(height: 1, color: AppColors.outlineVariant),
                          _buildToggleItem(
                            icon: Icons.event,
                            iconBgColor: AppColors.primary.withValues(
                              alpha: 0.12,
                            ),
                            iconColor: AppColors.primary,
                            label: 'Pengingat Jadwal',
                            value: _notifJadwal,
                            onChanged: (v) => setState(() => _notifJadwal = v),
                          ),
                          Divider(height: 1, color: AppColors.outlineVariant),
                          _buildToggleItem(
                            icon: Icons.admin_panel_settings,
                            iconBgColor: AppColors.primary.withValues(
                              alpha: 0.12,
                            ),
                            iconColor: AppColors.primary,
                            label: 'Notifikasi Admin',
                            value: _notifAdmin,
                            onChanged: (v) => setState(() => _notifAdmin = v),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // PREFERENSI APLIKASI
                      _buildSectionLabel('PREFERENSI APLIKASI'),
                      const SizedBox(height: 8),
                      _buildMenuCard(
                        children: [
                          _buildNavItem(
                            icon: Icons.language,
                            iconBgColor: AppColors.primary.withValues(
                              alpha: 0.12,
                            ),
                            iconColor: AppColors.primary,
                            label: 'Bahasa',
                            trailing: Text(
                              'Indonesia',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.onSurfaceVariant,
                                fontSize: 13,
                              ),
                            ),
                            onTap: () {},
                          ),
                          Divider(height: 1, color: AppColors.outlineVariant),
                          _buildNavItem(
                            icon: Icons.dark_mode,
                            iconBgColor: AppColors.primary.withValues(
                              alpha: 0.12,
                            ),
                            iconColor: AppColors.primary,
                            label: 'Tema',
                            trailing: Text(
                              'Sistem Default',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.onSurfaceVariant,
                                fontSize: 13,
                              ),
                            ),
                            onTap: () {},
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // INFORMASI LAINNYA
                      _buildSectionLabel('INFORMASI LAINNYA'),
                      const SizedBox(height: 8),
                      _buildMenuCard(
                        children: [
                          _buildNavItem(
                            icon: Icons.help_outlined,
                            iconBgColor: AppColors.primary.withValues(
                              alpha: 0.12,
                            ),
                            iconColor: AppColors.primary,
                            label: 'Pusat Bantuan Petugas',
                            onTap: () => Navigator.pushNamed(
                              context,
                              AppRoutes.staffHelp,
                            ),
                          ),
                          Divider(height: 1, color: AppColors.outlineVariant),
                          _buildNavItem(
                            icon: Icons.chat_outlined,
                            iconBgColor: AppColors.primary.withValues(
                              alpha: 0.12,
                            ),
                            iconColor: AppColors.primary,
                            label: 'Hubungi Admin',
                            onTap: () {
                              showStaffInfoSnackBar(
                                context,
                                'Hubungi admin segera hadir (dummy).',
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // KELUAR
                      _buildLogoutButton(context),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        label,
        style: AppTextStyles.labelSmall.copyWith(
          color: AppColors.onSurfaceVariant,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.6,
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _buildMenuCard({required List<Widget> children}) {
    return Container(
      decoration: staffPremiumCardDecoration(radius: 22),
      clipBehavior: Clip.hardEdge,
      child: Column(children: children),
    );
  }

  Widget _buildNavItem({
    IconData? icon,
    Widget? customIcon,
    required Color iconBgColor,
    Color iconColor = AppColors.onSurfaceVariant,
    required String label,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: iconBgColor,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: customIcon ?? Icon(icon!, color: iconColor, size: 18),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.onSurface,
                  fontSize: 15,
                ),
              ),
            ),
            if (trailing != null) ...[trailing, const SizedBox(width: 4)],
            Icon(Icons.chevron_right, color: AppColors.outline, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleItem({
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: iconBgColor,
              shape: BoxShape.circle,
            ),
            child: Center(child: Icon(icon, color: iconColor, size: 18)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.onSurface,
                fontSize: 15,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Colors.white,
            activeTrackColor: AppColors.primary,
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: AppColors.outlineVariant,
          ),
        ],
      ),
    );
  }

  Widget _buildGoogleIcon() {
    return Container(
      width: 20,
      height: 20,
      decoration: const BoxDecoration(shape: BoxShape.circle),
      child: Center(
        child: RichText(
          text: const TextSpan(
            children: [
              TextSpan(
                text: 'G',
                style: TextStyle(
                  color: Color(0xFF4285F4),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return InkWell(
      onTap: () => confirmStaffLogout(context),
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.logout, color: AppColors.error, size: 18),
            ),
            const SizedBox(width: 10),
            Text(
              'Keluar',
              style: AppTextStyles.labelMedium.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.error,
              ),
            ),
          ],
        ),
      ),
    );
  }
}