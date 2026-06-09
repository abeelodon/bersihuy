import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../services/customer_profile_service.dart';

class CustomerEditProfileScreen extends StatefulWidget {
  const CustomerEditProfileScreen({super.key});

  @override
  State<CustomerEditProfileScreen> createState() =>
      _CustomerEditProfileScreenState();
}

class _CustomerEditProfileScreenState extends State<CustomerEditProfileScreen> {
  static const _profileService = CustomerProfileService();

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _noteController = TextEditingController();

  CustomerProfileData? _profile;
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
      final profile = await _profileService.getCurrentProfile();
      if (!mounted) return;
      _nameController.text = profile.fullName;
      _emailController.text = profile.email;
      _phoneController.text = profile.phone;
      _addressController.text = profile.mainAddress;
      _cityController.text = profile.city;
      _noteController.text = profile.addressNote;
      setState(() => _profile = profile);
    } catch (error, stackTrace) {
      debugPrint('CUSTOMER EDIT PROFILE LOAD ERROR: $error');
      debugPrint('CUSTOMER EDIT PROFILE LOAD STACKTRACE: $stackTrace');
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Data pribadi belum dapat dimuat. Silakan coba lagi.';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveChanges() async {
    if (_isSaving || !_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      await _profileService.updateCurrentProfile(
        fullName: _nameController.text,
        phone: _phoneController.text,
        mainAddress: _addressController.text,
        city: _cityController.text,
        addressNote: _noteController.text,
      );

      if (!mounted) return;
      await _loadProfile();
      if (!mounted) return;
      _showSnackBar('Profil berhasil diperbarui.', isError: false);
    } catch (error, stackTrace) {
      debugPrint('CUSTOMER EDIT PROFILE SAVE ERROR: $error');
      debugPrint('CUSTOMER EDIT PROFILE SAVE STACKTRACE: $stackTrace');
      if (!mounted) return;
      final message = error.toString().replaceFirst('Exception: ', '');
      _showSnackBar(
        message.isEmpty ? 'Profil gagal diperbarui.' : message,
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? AppColors.error : AppColors.primary,
        ),
      );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: _PremiumCustomerBackground(
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
            decoration: _cardDecoration(radius: 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: AppColors.error,
                  size: 34,
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
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 118),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildPhotoSection(),
                  const SizedBox(height: 24),
                  _buildFormSection(),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: _buildBottomActionPanel(),
        ),
      ],
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white.withValues(alpha: 0.92),
      elevation: 0,
      scrolledUnderElevation: 1,
      titleSpacing: 0,
      centerTitle: false,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: AppColors.primary),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'Data Pribadi',
        style: AppTextStyles.headlineSmall.copyWith(
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          color: AppColors.outlineVariant.withValues(alpha: 0.3),
          height: 1,
        ),
      ),
    );
  }

  Widget _buildPhotoSection() {
    return Column(
      children: [
        Container(
          width: 98,
          height: 98,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.2),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Center(
            child: Text(
              _profile?.initials ?? 'PB',
              style: AppTextStyles.headlineSmall.copyWith(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Profil Pelanggan',
          style: AppTextStyles.labelMedium.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }

  Widget _buildFormSection() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(radius: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTextField(
            label: 'Nama Lengkap',
            controller: _nameController,
            placeholder: 'Masukkan nama lengkap',
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Nama wajib diisi'
                : null,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            label: 'Email',
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            readOnly: true,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            label: 'Nomor WhatsApp',
            controller: _phoneController,
            placeholder: 'Belum diisi',
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 18),
          Divider(color: AppColors.outlineVariant.withValues(alpha: 0.7)),
          const SizedBox(height: 18),
          Text(
            'Alamat Utama',
            style: AppTextStyles.headlineSmall.copyWith(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          _buildTextField(
            label: 'Detail Alamat',
            controller: _addressController,
            placeholder: 'Belum ada alamat utama',
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            label: 'Kota',
            controller: _cityController,
            placeholder: 'Belum diisi',
          ),
          const SizedBox(height: 16),
          _buildTextField(
            label: 'Catatan Alamat',
            controller: _noteController,
            placeholder: 'Contoh: Patokan dekat minimarket',
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    String? placeholder,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    bool readOnly = false,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel(label),
        const SizedBox(height: 7),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          readOnly: readOnly,
          maxLines: maxLines,
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.onSurface),
          decoration: _inputDecoration(
            hintText: placeholder,
            readOnly: readOnly,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomActionPanel() {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 14, 22, 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        border: Border(
          top: BorderSide(
            color: AppColors.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF247D78).withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isSaving ? null : _saveChanges,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.6),
          elevation: 0,
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(vertical: 15),
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
                style: AppTextStyles.buttonLabel.copyWith(
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  Widget _fieldLabel(String text) {
    return Text(
      text,
      style: AppTextStyles.labelMedium.copyWith(
        color: AppColors.onSurface,
        fontWeight: FontWeight.w800,
        letterSpacing: 0,
      ),
    );
  }

  InputDecoration _inputDecoration({String? hintText, bool readOnly = false}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.outline),
      filled: true,
      fillColor: readOnly
          ? AppColors.outlineVariant.withValues(alpha: 0.18)
          : const Color(0xFFFAFCFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: AppColors.outlineVariant.withValues(alpha: 0.8),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: AppColors.outlineVariant.withValues(alpha: 0.8),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
      ),
    );
  }

  BoxDecoration _cardDecoration({required double radius}) {
    return BoxDecoration(
      color: const Color(0xFFFEFFFF),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: AppColors.outlineVariant.withValues(alpha: 0.72),
      ),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF247D78).withValues(alpha: 0.055),
          blurRadius: 22,
          offset: const Offset(0, 10),
        ),
      ],
    );
  }
}

class _PremiumCustomerBackground extends StatelessWidget {
  final Widget child;

  const _PremiumCustomerBackground({required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFF8FAFB), Color(0xFFF4FAF9), Color(0xFFEEF8F7)],
            ),
          ),
          child: SizedBox.expand(),
        ),
        child,
      ],
    );
  }
}
