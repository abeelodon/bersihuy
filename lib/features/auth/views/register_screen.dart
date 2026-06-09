import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/services/supabase_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;

  Future<void> _handleRegister() async {
    final fullName = _fullNameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;
    final validationMessage = _validateInput(
      fullName: fullName,
      email: email,
      password: password,
      confirmPassword: confirmPassword,
    );

    if (validationMessage != null) {
      _showSnackBar(validationMessage, isError: true);
      return;
    }

    setState(() => _isLoading = true);
    debugPrint('REGISTER: fullName=$fullName');
    debugPrint('REGISTER: email=$email');

    try {
      final response = await SupabaseService.client.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName},
      );

      final user = response.user;
      if (user == null) {
        throw const _RegisterException(
          'Registrasi berhasil tetapi data pengguna tidak tersedia.',
        );
      }

      // Supabase may return an obfuscated user for an existing email when
      // email confirmation is enabled.
      if (user.identities != null && user.identities!.isEmpty) {
        throw const _EmailAlreadyRegisteredException();
      }

      debugPrint('REGISTER: userId=${user.id}');
      debugPrint('REGISTER: profile creation delegated to database trigger');

      if (!mounted) return;

      if (response.session != null) {
        debugPrint('REGISTER: signing out temporary registration session');
        await SupabaseService.client.auth.signOut();
      }

      if (!mounted) return;

      debugPrint('REGISTER: navigating to login after successful registration');
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.login,
        (route) => false,
        arguments: {'message': 'Akun berhasil dibuat. Silakan login kembali.'},
      );
    } catch (error, stackTrace) {
      final message = _friendlyError(error);
      debugPrint('REGISTER ERROR: $message');
      debugPrint('REGISTER STACKTRACE: $stackTrace');

      if (mounted) {
        _showSnackBar(message, isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String? _validateInput({
    required String fullName,
    required String email,
    required String password,
    required String confirmPassword,
  }) {
    if (fullName.isEmpty) {
      return 'Nama lengkap wajib diisi.';
    }
    if (email.isEmpty) {
      return 'Email wajib diisi.';
    }

    final emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailPattern.hasMatch(email)) {
      return 'Format email tidak valid.';
    }
    if (password.isEmpty) {
      return 'Password wajib diisi.';
    }
    if (password.length < 6) {
      return 'Password minimal 6 karakter.';
    }
    if (confirmPassword.isEmpty) {
      return 'Konfirmasi password wajib diisi.';
    }
    if (confirmPassword != password) {
      return 'Konfirmasi password tidak sama.';
    }

    return null;
  }

  String _friendlyError(Object error) {
    if (error is _EmailAlreadyRegisteredException) {
      return 'Email sudah terdaftar. Silakan masuk.';
    }

    final rawMessage = switch (error) {
      AuthException authError => authError.message,
      _RegisterException registerError => registerError.message,
      _ => error.toString(),
    };
    final lowerMessage = rawMessage.toLowerCase();

    if (lowerMessage.contains('already registered') ||
        lowerMessage.contains('already exists') ||
        lowerMessage.contains('user_already_exists') ||
        lowerMessage.contains('email_exists') ||
        lowerMessage.contains('duplicate')) {
      return 'Email sudah terdaftar. Silakan masuk.';
    }

    final cleanMessage = rawMessage.startsWith('Exception: ')
        ? rawMessage.substring(11)
        : rawMessage;
    return cleanMessage.isEmpty
        ? 'Registrasi gagal. Silakan coba lagi.'
        : cleanMessage;
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? AppColors.error : AppColors.primary,
          duration: const Duration(seconds: 4),
        ),
      );
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: _AuthBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 40.0,
              ),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 390),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header Section (Logo & Tagline)
                    Column(
                      children: [
                        Image.asset(
                          'assets/images/logo_full.png',
                          width: 226,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Text(
                              'Bersihuy',
                              style: AppTextStyles.headlineLarge.copyWith(
                                fontSize: 34,
                                color: AppColors.primary,
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 14),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 18.0),
                          child: Text(
                            'Daftar untuk mulai memesan layanan kebersihan',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: const Color(0xFF5B6974),
                              fontSize: 13.5,
                              fontWeight: FontWeight.w400,
                              height: 1.58,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 38),

                    // Register Card
                    Container(
                      padding: const EdgeInsets.fromLTRB(28, 30, 28, 28),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30.0),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF247D78,
                            ).withValues(alpha: 0.10),
                            blurRadius: 42.0,
                            offset: const Offset(0, 22),
                          ),
                          BoxShadow(
                            color: AppColors.textDark.withValues(alpha: 0.045),
                            blurRadius: 14.0,
                            offset: const Offset(0, 2),
                          ),
                        ],
                        border: Border.all(
                          color: const Color(
                            0xFFE5EEEC,
                          ).withValues(alpha: 0.78),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Buat Akun',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.headlineMedium.copyWith(
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF142232),
                              letterSpacing: 0,
                              height: 1.22,
                            ),
                          ),
                          const SizedBox(height: 7),
                          Text(
                            'Lengkapi data untuk mulai memakai Bersihuy',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: const Color(0xFF6B7882),
                              fontSize: 13,
                              height: 1.45,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Nama Lengkap Field
                          _PremiumTextField(
                            label: 'Nama Lengkap',
                            hint: 'Masukkan nama lengkap Anda',
                            icon: Icons.person_outline_rounded,
                            controller: _fullNameController,
                          ),
                          const SizedBox(height: 17),

                          // Email Field
                          _PremiumTextField(
                            label: 'Email',
                            hint: 'Masukkan email Anda',
                            icon: Icons.mail_outline_rounded,
                            keyboardType: TextInputType.emailAddress,
                            controller: _emailController,
                          ),
                          const SizedBox(height: 17),

                          // Password Field
                          _PremiumTextField(
                            label: 'Password',
                            hint: 'Masukkan password Anda',
                            icon: Icons.lock_outline_rounded,
                            isPassword: true,
                            controller: _passwordController,
                          ),
                          const SizedBox(height: 17),

                          // Konfirmasi Password Field
                          _PremiumTextField(
                            label: 'Konfirmasi Password',
                            hint: 'Ulangi password Anda',
                            icon: Icons.lock_outline_rounded,
                            isPassword: true,
                            controller: _confirmPasswordController,
                          ),
                          const SizedBox(height: 24),

                          // Register Button
                          _PrimaryAuthButton(
                            text: 'Daftar',
                            onPressed: _handleRegister,
                            isLoading: _isLoading,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Footer Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Sudah punya akun?',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: const Color(0xFF65737D),
                            fontSize: 13.5,
                          ),
                        ),
                        const SizedBox(width: 4),
                        _TextAction(
                          text: 'Masuk',
                          onTap: () {
                            Navigator.pushReplacementNamed(
                              context,
                              AppRoutes.login,
                            );
                          },
                          style: AppTextStyles.linkMedium,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthBackground extends StatelessWidget {
  final Widget child;

  const _AuthBackground({required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFF8FAFB), Color(0xFFF1F8F7), Color(0xFFEAF7F5)],
            ),
          ),
          child: SizedBox.expand(),
        ),
        Positioned(
          top: -118,
          left: -72,
          right: -72,
          child: Container(
            height: 360,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF4BC7C3).withValues(alpha: 0.16),
                  const Color(0xFF4BC7C3).withValues(alpha: 0.07),
                  const Color(0xFF4BC7C3).withValues(alpha: 0.0),
                ],
                stops: const [0.0, 0.42, 1.0],
              ),
            ),
          ),
        ),
        Positioned(
          top: 220,
          right: -84,
          child: Container(
            width: 190,
            height: 190,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF4BC7C3).withValues(alpha: 0.10),
                  const Color(0xFF4BC7C3).withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -132,
          left: -84,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF4BC7C3).withValues(alpha: 0.11),
                  const Color(0xFF4BC7C3).withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class _PremiumTextField extends StatefulWidget {
  final String? label;
  final String hint;
  final IconData icon;
  final bool isPassword;
  final TextEditingController controller;
  final TextInputType keyboardType;

  const _PremiumTextField({
    this.label,
    required this.hint,
    required this.icon,
    required this.controller,
    this.isPassword = false,
    this.keyboardType = TextInputType.text,
  });

  @override
  State<_PremiumTextField> createState() => _PremiumTextFieldState();
}

class _PremiumTextFieldState extends State<_PremiumTextField> {
  late final FocusNode _focusNode;
  late bool _obscureText;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode()..addListener(_handleFocusChange);
    _obscureText = widget.isPassword;
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_handleFocusChange)
      ..dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isFocused = _focusNode.hasFocus;
    final iconColor = isFocused
        ? const Color(0xFF2F8F8A)
        : const Color(0xFF6F8987);
    final iconBackground = isFocused
        ? const Color(0xFFE8F7F5)
        : const Color(0xFFF1F6F5);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: AppTextStyles.labelMedium.copyWith(
              color: const Color(0xFF243343),
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 7),
        ],
        TextFormField(
          focusNode: _focusNode,
          controller: widget.controller,
          obscureText: _obscureText,
          keyboardType: widget.keyboardType,
          cursorColor: const Color(0xFF2F8F8A),
          style: AppTextStyles.bodyMedium.copyWith(
            color: const Color(0xFF172331),
            fontSize: 14,
            fontWeight: FontWeight.w500,
            height: 1.25,
          ),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: AppTextStyles.bodyMedium.copyWith(
              color: const Color(0xFF82918F),
              fontSize: 13.5,
              fontWeight: FontWeight.w400,
            ),
            filled: true,
            fillColor: const Color(0xFFFAFCFC),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 17,
            ),
            prefixIcon: Container(
              width: 34,
              height: 34,
              margin: const EdgeInsets.only(left: 12, right: 10),
              decoration: BoxDecoration(
                color: iconBackground,
                shape: BoxShape.circle,
              ),
              child: Icon(widget.icon, color: iconColor, size: 17),
            ),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 58,
              minHeight: 52,
            ),
            suffixIcon: widget.isPassword
                ? IconButton(
                    tooltip: _obscureText
                        ? 'Tampilkan password'
                        : 'Sembunyikan password',
                    icon: Icon(
                      _obscureText
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: iconColor,
                      size: 20,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureText = !_obscureText;
                      });
                    },
                  )
                : null,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide(
                color: const Color(0xFFDDE8E6).withValues(alpha: 0.82),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(
                color: Color(0xFF45BDB8),
                width: 1.5,
              ),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide(
                color: const Color(0xFFDDE8E6).withValues(alpha: 0.82),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PrimaryAuthButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;

  const _PrimaryAuthButton({
    required this.text,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    const borderRadius = BorderRadius.all(Radius.circular(28));

    return Container(
      height: 56,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color(0xFF2F8F8A), Color(0xFF45BDB8)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2F8F8A).withValues(alpha: 0.24),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: borderRadius,
          splashColor: Colors.white.withValues(alpha: 0.12),
          highlightColor: Colors.white.withValues(alpha: 0.08),
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    text,
                    style: AppTextStyles.buttonLabel.copyWith(
                      color: Colors.white,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _RegisterException implements Exception {
  final String message;

  const _RegisterException(this.message);
}

class _EmailAlreadyRegisteredException implements Exception {
  const _EmailAlreadyRegisteredException();
}

class _TextAction extends StatefulWidget {
  final String text;
  final VoidCallback onTap;
  final TextStyle style;

  const _TextAction({
    required this.text,
    required this.onTap,
    required this.style,
  });

  @override
  State<_TextAction> createState() => _TextActionState();
}

class _TextActionState extends State<_TextAction> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(8),
        hoverColor: AppColors.primary.withValues(alpha: 0.06),
        splashColor: AppColors.primary.withValues(alpha: 0.08),
        highlightColor: AppColors.primary.withValues(alpha: 0.05),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOut,
            style: widget.style.copyWith(
              color: _isHovered
                  ? const Color(0xFF216E6A)
                  : const Color(0xFF287A76),
              fontWeight: FontWeight.w600,
              letterSpacing: 0,
            ),
            child: Text(widget.text),
          ),
        ),
      ),
    );
  }
}
