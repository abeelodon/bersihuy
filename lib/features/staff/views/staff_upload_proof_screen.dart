import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/routes/app_routes.dart';
import '../../../shared/widgets/staff_premium_widgets.dart';

class StaffUploadProofScreen extends StatefulWidget {
  const StaffUploadProofScreen({super.key});

  @override
  State<StaffUploadProofScreen> createState() => _StaffUploadProofScreenState();
}

class _StaffUploadProofScreenState extends State<StaffUploadProofScreen> {
  // Upload statuses
  bool _hasBeforePhoto = false;
  bool _hasAfterPhoto = false;
  bool _isAreaDoubleChecked = false;

  // Note controller
  final TextEditingController _noteController = TextEditingController();

  // Loading indicator for submission button
  bool _isSubmitting = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  bool get _canSubmit => _hasBeforePhoto && _hasAfterPhoto;

  void _handleSubmit() {
    // Validate checklists
    if (!_hasBeforePhoto || !_hasAfterPhoto || !_isAreaDoubleChecked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Harap lengkapi semua checklist akhir terlebih dahulu!',
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    // Simulate submission loading
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
        showStaffInfoSnackBar(
          context,
          'Bukti berhasil dikirim dan pekerjaan selesai.',
        );
        // Navigate to history
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.staffHistory,
          ModalRoute.withName(AppRoutes.staffHome),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white.withValues(alpha: 0.9),
        elevation: 0,
        scrolledUnderElevation: 1,
        titleSpacing: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
        ),
        title: Text(
          'Upload Bukti',
          style: AppTextStyles.headlineSmall.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.onSurface,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: AppColors.outlineVariant,
            height: 1.0,
          ),
        ),
      ),
      body: PremiumStaffBackground(
        child: SafeArea(
          child: Center(
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 460),
              child: Stack(
                children: [
                  // Scrollable main content
                  ScrollConfiguration(
                    behavior: ScrollConfiguration.of(
                      context,
                    ).copyWith(scrollbars: false),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.only(
                        left: 22.0,
                        right: 22.0,
                        top: 20.0,
                        bottom: 160.0, // Large bottom space for floating sticky footer
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Task Summary Card
                          _buildTaskSummaryCard(),
                          const SizedBox(height: 20),

                          // Before Photo Card
                          _buildBeforePhotoSection(),
                          const SizedBox(height: 16),

                          // After Photo Card
                          _buildAfterPhotoSection(),
                          const SizedBox(height: 16),

                          // Notes Area
                          _buildNotesSection(),
                          const SizedBox(height: 16),

                          // Completion Checklist
                          _buildChecklistSection(),
                        ],
                      ),
                    ),
                  ),

                  // Floating Sticky Footer Actions
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: _buildFooterActions(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTaskSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: staffPremiumCardDecoration(radius: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Deep Cleaning',
                      style: AppTextStyles.headlineSmall.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Fathan Nabil',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              StaffStatusBadge(label: 'Dalam Proses'),
            ],
          ),
          const SizedBox(height: 12),
          Divider(height: 1, color: AppColors.outlineVariant.withValues(alpha: 0.5)),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: 16,
                color: AppColors.outline,
              ),
              const SizedBox(width: 8),
              Text(
                'Hari ini, 14.00',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.outline,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.location_on_outlined,
                size: 16,
                color: AppColors.outline,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Jln. Sudirman No. 45, Jakarta Selatan',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.outline,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBeforePhotoSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: staffPremiumCardDecoration(radius: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              staffSoftIcon(icon: Icons.history_toggle_off, color: AppColors.primary, size: 40),
              const SizedBox(width: 12),
              Text(
                'Foto Sebelum',
                style: AppTextStyles.headlineSmall.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Upload kondisi area sebelum pekerjaan dimulai.',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.outline,
            ),
          ),
          Text(
            'Foto sebelum wajib',
            style: AppTextStyles.labelSmall.copyWith(
              color: _hasBeforePhoto ? Colors.transparent : AppColors.error,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () {
              setState(() {
                _hasBeforePhoto = !_hasBeforePhoto;
              });
            },
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                color: _hasBeforePhoto
                    ? AppColors.primary.withValues(alpha: 0.05)
                    : AppColors.outlineVariant.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _hasBeforePhoto
                      ? AppColors.primary
                      : AppColors.outlineVariant,
                  width: _hasBeforePhoto ? 2 : 1,
                ),
              ),
              child: _hasBeforePhoto
                  ? Stack(
                      children: [
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.check_circle,
                                color: AppColors.primary,
                                size: 36,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Foto Sebelum Terupload',
                                style: AppTextStyles.labelSmall.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary,
                                ),
                              ),
                              Text(
                                '(Sentuh untuk membatalkan)',
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: AppColors.outline,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_a_photo,
                          color: AppColors.outline.withValues(alpha: 0.7),
                          size: 28,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Ketuk untuk upload foto',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.outline,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () {
              setState(() {
                _hasBeforePhoto = true;
              });
              showStaffInfoSnackBar(
                context,
                'Simulasi: Foto sebelum terupload.',
              );
            },
            icon: const Icon(Icons.upload, size: 18),
            label: Text(
              'Upload Foto Sebelum',
              style: AppTextStyles.labelMedium.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              minimumSize: const Size.fromHeight(48),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAfterPhotoSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: staffPremiumCardDecoration(radius: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              staffSoftIcon(icon: Icons.task_alt, color: AppColors.primary, size: 40),
              const SizedBox(width: 12),
              Text(
                'Foto Sesudah',
                style: AppTextStyles.headlineSmall.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Upload kondisi area setelah pekerjaan selesai.',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.outline,
            ),
          ),
          Text(
            'Foto sesudah wajib',
            style: AppTextStyles.labelSmall.copyWith(
              color: _hasAfterPhoto ? Colors.transparent : AppColors.error,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () {
              setState(() {
                _hasAfterPhoto = !_hasAfterPhoto;
              });
            },
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                color: _hasAfterPhoto
                    ? AppColors.primary.withValues(alpha: 0.05)
                    : AppColors.outlineVariant.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _hasAfterPhoto
                      ? AppColors.primary
                      : AppColors.outlineVariant,
                  width: _hasAfterPhoto ? 2 : 1,
                ),
              ),
              child: _hasAfterPhoto
                  ? Stack(
                      children: [
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.check_circle,
                                color: AppColors.primary,
                                size: 36,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Foto Sesudah Terupload',
                                style: AppTextStyles.labelSmall.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary,
                                ),
                              ),
                              Text(
                                '(Sentuh untuk membatalkan)',
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: AppColors.outline,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_a_photo,
                          color: AppColors.outline.withValues(alpha: 0.7),
                          size: 28,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Ketuk untuk upload foto',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.outline,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () {
              setState(() {
                _hasAfterPhoto = true;
              });
              showStaffInfoSnackBar(
                context,
                'Simulasi: Foto sesudah terupload.',
              );
            },
            icon: const Icon(Icons.upload, size: 18),
            label: Text(
              'Upload Foto Sesudah',
              style: AppTextStyles.labelMedium.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              minimumSize: const Size.fromHeight(48),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: staffPremiumCardDecoration(radius: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Catatan Pekerjaan',
            style: AppTextStyles.headlineSmall.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _noteController,
            maxLines: 4,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.onSurface,
            ),
            decoration: InputDecoration(
              hintText: 'Tambahkan catatan jika diperlukan',
              hintStyle: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.outline,
              ),
              fillColor: AppColors.outlineVariant.withValues(alpha: 0.1),
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppColors.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChecklistSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: staffPremiumCardDecoration(radius: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Checklist Akhir',
            style: AppTextStyles.headlineSmall.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),

          // Checklist Item 1
          _buildChecklistItem(
            value: _hasBeforePhoto,
            label: 'Foto sebelum sudah diupload',
            onChanged: (val) {
              setState(() {
                _hasBeforePhoto = val ?? false;
              });
            },
          ),
          Divider(height: 16, color: AppColors.outlineVariant.withValues(alpha: 0.5)),

          // Checklist Item 2
          _buildChecklistItem(
            value: _hasAfterPhoto,
            label: 'Foto sesudah sudah diupload',
            onChanged: (val) {
              setState(() {
                _hasAfterPhoto = val ?? false;
              });
            },
          ),
          Divider(height: 16, color: AppColors.outlineVariant.withValues(alpha: 0.5)),

          // Checklist Item 3
          _buildChecklistItem(
            value: _isAreaDoubleChecked,
            label: 'Area layanan sudah dicek ulang',
            onChanged: (val) {
              setState(() {
                _isAreaDoubleChecked = val ?? false;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildChecklistItem({
    required bool value,
    required String label,
    required ValueChanged<bool?> onChanged,
  }) {
    return InkWell(
      onTap: () => onChanged(!value),
      child: Row(
        children: [
          Checkbox(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                decoration: value ? TextDecoration.lineThrough : null,
                color: value ? AppColors.outline : AppColors.onSurface,
                fontWeight: value ? FontWeight.normal : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterActions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, -6),
          ),
        ],
        border: Border(
          top: BorderSide(
            color: AppColors.outlineVariant,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ElevatedButton(
            onPressed: _isSubmitting || !_canSubmit ? null : _handleSubmit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.4),
              elevation: 0,
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(vertical: 14),
              minimumSize: const Size.fromHeight(56),
            ),
            child: _isSubmitting
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Mengirim...',
                        style: AppTextStyles.labelMedium.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  )
                : Text(
                    'Kirim Bukti Pekerjaan',
                    style: AppTextStyles.labelMedium.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () {
              showStaffInfoSnackBar(
                context,
                'Draft bukti pekerjaan berhasil disimpan.',
              );
              Navigator.pop(context);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                'Simpan Draft',
                style: AppTextStyles.labelMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.outline,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}