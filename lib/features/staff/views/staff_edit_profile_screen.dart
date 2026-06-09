import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../shared/widgets/staff_premium_widgets.dart';
import '../repositories/staff_task_repository.dart';

class StaffEditProfileScreen extends StatefulWidget {
  const StaffEditProfileScreen({super.key});

  @override
  State<StaffEditProfileScreen> createState() => _StaffEditProfileScreenState();
}

class _StaffEditProfileScreenState extends State<StaffEditProfileScreen> {
  static const _repository = StaffTaskRepository();

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _serviceAreaController = TextEditingController();
  final _baseLocationController = TextEditingController();
  final _workScheduleController = TextEditingController();

  StaffOperationalProfile? _profile;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final profile = await _repository.getStaffOperationalProfile();
      if (profile == null) {
        throw StateError('Sesi petugas tidak ditemukan.');
      }
      if (!mounted) return;

      _nameController.text = profile.fullName;
      _emailController.text = profile.email;
      _phoneController.text = profile.phone ?? '';
      _serviceAreaController.text = profile.serviceArea ?? '';
      _baseLocationController.text = profile.baseLocation ?? '';
      _workScheduleController.text = profile.workSchedule ?? '';
      setState(() => _profile = profile);
    } catch (error, stackTrace) {
      debugPrint('STAFF EDIT PROFILE LOAD ERROR: $error');
      debugPrint('STAFF EDIT PROFILE LOAD STACKTRACE: $stackTrace');
      if (!mounted) return;
      setState(() {
        _errorMessage =
            'Data profil petugas belum dapat dimuat. Silakan coba lagi.';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    if (_isSaving || !_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      await _repository.updateStaffOperationalProfile(
        fullName: _nameController.text,
        phone: _phoneController.text,
        serviceArea: _serviceAreaController.text,
        baseLocation: _baseLocationController.text,
        workSchedule: _workScheduleController.text,
      );

      if (!mounted) return;
      await _loadProfile();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Profil petugas berhasil diperbarui.'),
            backgroundColor: AppColors.primary,
          ),
        );
    } catch (error, stackTrace) {
      debugPrint('STAFF EDIT PROFILE SAVE ERROR: $error');
      debugPrint('STAFF EDIT PROFILE SAVE STACKTRACE: $stackTrace');
      if (!mounted) return;
      final message = error.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              message.isEmpty ? 'Profil petugas gagal diperbarui.' : message,
            ),
            backgroundColor: AppColors.error,
          ),
        );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _serviceAreaController.dispose();
    _baseLocationController.dispose();
    _workScheduleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: PremiumStaffBackground(
        child: SafeArea(
          child: Center(
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 460),
              child: _buildBody(),
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white.withValues(alpha: 0.95),
      elevation: 0,
      scrolledUnderElevation: 1,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: AppColors.onSurfaceVariant),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'Data Pribadi',
        style: AppTextStyles.headlineSmall.copyWith(
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        ),
      ),
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(height: 1, color: AppColors.outlineVariant),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: staffPremiumCardDecoration(radius: 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: AppColors.error,
                  size: 36,
                ),
                const SizedBox(height: 10),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 14),
                OutlinedButton(
                  onPressed: _loadProfile,
                  child: const Text('Coba Lagi'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Stack(
      children: [
        ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 120),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildPhotoSection(),
                  const SizedBox(height: 20),
                  _buildPersonalSection(),
                  const SizedBox(height: 20),
                  _buildOperationalSection(),
                ],
              ),
            ),
          ),
        ),
        Positioned(bottom: 0, left: 0, right: 0, child: _buildSaveButton()),
      ],
    );
  }

  Widget _buildPhotoSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: staffPremiumCardDecoration(radius: 22),
      child: Column(
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withValues(alpha: 0.1),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.2),
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                _profile?.initials ?? 'P',
                style: AppTextStyles.headlineLarge.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                  fontSize: 32,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _profile?.fullName ?? 'Petugas Bersihuy',
            style: AppTextStyles.headlineSmall.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.2),
              ),
            ),
            child: Text(
              'Petugas',
              style: AppTextStyles.labelSmall.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalSection() {
    return _buildSection(
      title: 'INFORMASI PRIBADI',
      children: [
        _buildTextField(
          label: 'Nama Lengkap',
          controller: _nameController,
          validator: (value) => value == null || value.trim().isEmpty
              ? 'Nama lengkap wajib diisi'
              : null,
        ),
        const SizedBox(height: 14),
        _buildTextField(
          label: 'Email',
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          readOnly: true,
        ),
        const SizedBox(height: 14),
        _buildTextField(
          label: 'Nomor WhatsApp',
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          hintText: 'Telepon belum diatur',
        ),
      ],
    );
  }

  Widget _buildOperationalSection() {
    return _buildSection(
      title: 'INFORMASI OPERASIONAL',
      children: [
        _buildTextField(
          label: 'Area Layanan',
          controller: _serviceAreaController,
          hintText: 'Area belum diatur',
        ),
        const SizedBox(height: 14),
        _buildTextField(
          label: 'Lokasi Base',
          controller: _baseLocationController,
          hintText: 'Base belum diatur',
          maxLines: 2,
        ),
        const SizedBox(height: 14),
        _buildTextField(
          label: 'Jadwal Kerja',
          controller: _workScheduleController,
          hintText: 'Jadwal belum diatur',
          maxLines: 2,
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: staffPremiumCardDecoration(radius: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.onSurfaceVariant,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    String? hintText,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    bool readOnly = false,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          readOnly: readOnly,
          validator: validator,
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.onSurface),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.outline,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            filled: true,
            fillColor: readOnly
                ? AppColors.outlineVariant.withValues(alpha: 0.2)
                : const Color(0xFFF4FAF9),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.outlineVariant),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: AppColors.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: AppColors.outlineVariant)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isSaving ? null : _saveProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.6),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: const StadiumBorder(),
          elevation: 0,
        ),
        child: _isSaving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.4,
                ),
              )
            : Text(
                'Simpan Perubahan',
                style: AppTextStyles.labelMedium.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }
}
