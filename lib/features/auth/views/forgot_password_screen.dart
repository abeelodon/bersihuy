import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/routes/app_routes.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
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
                            'Pulihkan akses akun Bersihuy kamu dengan aman',
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
                            'Lupa Password?',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.headlineMedium.copyWith(
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF142232),
                              letterSpacing: 0,
                              height: 1.22,
                            ),
                          ),
                          const SizedBox(height: 9),
                          Text(
                            'Masukkan email akun kamu, kami akan mengirim instruksi reset password.',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: const Color(0xFF6B7882),
                              fontSize: 13,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 24),
                          _PremiumTextField(
                            label: 'Email',
                            hint: 'Masukkan email anda',
                            icon: Icons.mail_outline_rounded,
                            keyboardType: TextInputType.emailAddress,
                            controller: _emailController,
                          ),
                          const SizedBox(height: 24),
                          _PrimaryAuthButton(
                            text: 'Kirim Instruksi',
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Instruksi reset password telah dikirim.',
                                  ),
                                  backgroundColor: AppColors.primary,
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 18),
                          Center(
                            child: _TextAction(
                              text: 'Kembali ke Masuk',
                              onTap: () {
                                Navigator.pushReplacementNamed(
                                  context,
                                  AppRoutes.login,
                                );
                              },
                              style: AppTextStyles.linkMedium,
                            ),
                          ),
                        ],
                      ),
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
  final TextEditingController controller;
  final TextInputType keyboardType;

  const _PremiumTextField({
    this.label,
    required this.hint,
    required this.icon,
    required this.controller,
    this.keyboardType = TextInputType.text,
  });

  @override
  State<_PremiumTextField> createState() => _PremiumTextFieldState();
}

class _PremiumTextFieldState extends State<_PremiumTextField> {
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode()..addListener(_handleFocusChange);
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
  final VoidCallback onPressed;

  const _PrimaryAuthButton({required this.text, required this.onPressed});

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
          onTap: onPressed,
          borderRadius: borderRadius,
          splashColor: Colors.white.withValues(alpha: 0.12),
          highlightColor: Colors.white.withValues(alpha: 0.08),
          child: Center(
            child: Text(
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
