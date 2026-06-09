import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/services/supabase_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _handleLogin(BuildContext context) async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showError(context, 'Mohon isi email dan password.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // ── Step 1: Authenticate via Supabase ──────────────────────────────────
      debugPrint('LOGIN: Attempting signInWithPassword for $email');
      final response = await SupabaseService.client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      final user = response.user;
      if (user == null) {
        throw Exception('Login berhasil tapi user null');
      }
      debugPrint('LOGIN: Auth success - user id: ${user.id}');

      if (!context.mounted) return;

      // ── Step 2: Fetch profile from profiles table ─────────────────────────
      debugPrint('LOGIN: Fetching profile for user id: ${user.id}');
      final profile = await SupabaseService.client
          .from('profiles')
          .select('id, email, full_name, role')
          .eq('id', user.id)
          .maybeSingle();

      debugPrint('LOGIN: Raw profile response: $profile');

      if (profile == null) {
        throw Exception('Profile tidak ditemukan untuk user ${user.id}');
      }

      final role = profile['role'] as String?;
      debugPrint('LOGIN: Extracted role: $role');

      if (!context.mounted) return;

      // ── Step 3: Navigate by role ───────────────────────────────────────────
      if (role == 'customer') {
        debugPrint('LOGIN: Navigating to customer home');
        Navigator.pushReplacementNamed(context, AppRoutes.customerHome);
      } else if (role == 'staff') {
        debugPrint('LOGIN: Navigating to staff home');
        Navigator.pushReplacementNamed(context, AppRoutes.staffHome);
      } else if (role == 'admin') {
        debugPrint('LOGIN: Navigating to admin dashboard');
        Navigator.pushReplacementNamed(context, AppRoutes.adminDashboard);
      } else {
        debugPrint(
          'LOGIN: Unknown role "$role" - falling back to customer home',
        );
        Navigator.pushReplacementNamed(context, AppRoutes.customerHome);
      }
    } catch (e, st) {
      debugPrint('LOGIN ERROR: $e');
      debugPrint('LOGIN STACKTRACE: $st');

      if (!context.mounted) return;

      final message = _friendlyError(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _friendlyError(Object error) {
    final message = error.toString();
    final lower = message.toLowerCase();

    // Supabase Auth errors
    if (error is AuthException) {
      debugPrint(
        'LOGIN: AuthException code=${error.statusCode} msg=${error.message}',
      );
      if (lower.contains('invalid login credentials')) {
        return 'Email atau password salah.';
      }
      if (lower.contains('email not confirmed')) {
        return 'Email belum dikonfirmasi. Silakan cek inbox Anda.';
      }
      if (lower.contains('too many requests')) {
        return 'Terlalu banyak percobaan login. Silakan tunggu beberapa saat.';
      }
      if (lower.contains('user not found')) {
        return 'Akun tidak ditemukan.';
      }
      // Return raw message for debugging - strip "Exception: " prefix
      return error.message;
    }

    // Profile not found
    if (lower.contains('profile tidak ditemukan')) {
      return 'Profil pengguna tidak ditemukan di database.';
    }

    // User null after success
    if (lower.contains('user null')) {
      return 'Sesi berhasil tapi data pengguna tidak valid.';
    }

    // Network errors
    if (lower.contains('connection') ||
        lower.contains('network') ||
        lower.contains('socket') ||
        lower.contains('timeout')) {
      return 'Koneksi internet bermasalah. Coba lagi.';
    }

    // Return readable version of any other error
    final clean = message.startsWith('Exception: ')
        ? message.substring(11)
        : message;
    return 'Login gagal: $clean';
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
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
                            'Layanan kebersihan praktis untuk kos, rumah, dan kantor',
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

                    // Login Card
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
                            'Selamat Datang',
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
                            'Masuk untuk melanjutkan layanan Bersihuy',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: const Color(0xFF6B7882),
                              fontSize: 13,
                              height: 1.45,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Email Field
                          _PremiumTextField(
                            label: 'Email',
                            hint: 'Masukkan email anda',
                            icon: Icons.mail_outline_rounded,
                            keyboardType: TextInputType.emailAddress,
                            controller: _emailController,
                          ),
                          const SizedBox(height: 17),

                          // Password Field
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Password',
                                    style: AppTextStyles.labelMedium.copyWith(
                                      color: const Color(0xFF243343),
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0,
                                    ),
                                  ),
                                  _TextAction(
                                    text: 'Lupa password?',
                                    onTap: () {
                                      Navigator.pushNamed(
                                        context,
                                        AppRoutes.forgotPassword,
                                      );
                                    },
                                    style: AppTextStyles.linkSmall,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              _PremiumTextField(
                                hint: 'Masukkan password anda',
                                icon: Icons.lock_outline_rounded,
                                isPassword: true,
                                controller: _passwordController,
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Login Button
                          _PrimaryAuthButton(
                            text: 'Masuk',
                            onPressed: () => _handleLogin(context),
                            isLoading: _isLoading,
                          ),
                          const SizedBox(height: 16),

                          // Divider
                          Row(
                            children: [
                              Expanded(
                                child: Divider(
                                  color: AppColors.outlineVariant.withValues(
                                    alpha: 0.3,
                                  ),
                                  thickness: 1,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12.0,
                                ),
                                child: Text(
                                  'atau',
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: AppColors.outline,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Divider(
                                  color: AppColors.outlineVariant.withValues(
                                    alpha: 0.3,
                                  ),
                                  thickness: 1,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Google Sign-In Button
                          _GoogleAuthButton(
                            text: 'Lanjutkan dengan Google',
                            onPressed: () {
                              // Handle Google sign in
                            },
                            icon: Image.asset(
                              'assets/images/google_icon.png',
                              width: 19,
                              height: 19,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(
                                  Icons.login,
                                  size: 20,
                                  color: AppColors.textDark,
                                );
                              },
                            ),
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
                          'Belum punya akun?',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: const Color(0xFF65737D),
                            fontSize: 13.5,
                          ),
                        ),
                        const SizedBox(width: 4),
                        _TextAction(
                          text: 'Daftar',
                          onTap: () {
                            Navigator.pushNamed(context, AppRoutes.register);
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

class _GoogleAuthButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Widget icon;

  const _GoogleAuthButton({
    required this.text,
    required this.onPressed,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: const Color(0xFFFEFFFF),
          foregroundColor: const Color(0xFF172331),
          overlayColor: const Color(0xFF2F8F8A).withValues(alpha: 0.055),
          side: BorderSide(
            color: const Color(0xFFDDE8E6).withValues(alpha: 0.95),
          ),
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 18),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            icon,
            const SizedBox(width: 11),
            Flexible(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.buttonLabel.copyWith(
                  color: const Color(0xFF172331),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
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
