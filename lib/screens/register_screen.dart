import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_theme.dart';
import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/primary_button.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// REGISTER SCREEN — Speakera
///
/// • Same gradient background & card style as LoginScreen
/// • Fields: Name, Email, Password, Confirm Password
/// • Role toggle (Admin / Student)
/// • Staggered fade-in + slide-up animation
/// • "Already have an account? Sign In" link
/// ═══════════════════════════════════════════════════════════════════════════
class RegisterScreen extends StatefulWidget {
  final VoidCallback? onSwitchToLogin;

  const RegisterScreen({super.key, this.onSwitchToLogin});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with TickerProviderStateMixin {
  // ── Form state ─────────────────────────────────────────────────────────
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  UserRole _selectedRole = UserRole.student;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;
  String? _errorMessage;

  // ── Animation controllers ──────────────────────────────────────────────
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _logoFade;
  late Animation<double> _titleFade;
  late Animation<double> _toggleFade;
  late Animation<double> _fieldsFade;
  late Animation<double> _buttonFade;
  late Animation<Offset> _slideUp;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _logoFade = CurvedAnimation(
      parent: _fadeController,
      curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
    );
    _titleFade = CurvedAnimation(
      parent: _fadeController,
      curve: const Interval(0.15, 0.45, curve: Curves.easeOut),
    );
    _toggleFade = CurvedAnimation(
      parent: _fadeController,
      curve: const Interval(0.30, 0.60, curve: Curves.easeOut),
    );
    _fieldsFade = CurvedAnimation(
      parent: _fadeController,
      curve: const Interval(0.45, 0.75, curve: Curves.easeOut),
    );
    _buttonFade = CurvedAnimation(
      parent: _fadeController,
      curve: const Interval(0.60, 1.0, curve: Curves.easeOut),
    );

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  // ── Register handler ───────────────────────────────────────────────────
  Future<void> _handleRegister() async {
    setState(() => _errorMessage = null);

    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final authProvider = context.read<AuthProvider>();

    final error = await authProvider.register(
      name: name,
      email: email,
      password: password,
      role: _selectedRole,
    );

    if (!mounted) return;

    if (error == null) {
      // Registration successful — auto-login handled by AuthProvider
      // Navigation is handled by SpeakeraHome Consumer
      return;
    }

    setState(() {
      _isLoading = false;
      _errorMessage = error;
    });
  }

  // ═════════════════════════════════════════════════════════════════════
  // BUILD
  // ═════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 700;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [AppColors.gradientDarkStart, AppColors.gradientDarkEnd]
                : [AppColors.gradientStart, AppColors.gradientEnd],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 40 : 20,
                vertical: 24,
              ),
              child: SlideTransition(
                position: _slideUp,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: _buildCard(isDark, theme),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Registration card ──────────────────────────────────────────────────
  Widget _buildCard(bool isDark, ThemeData theme) {
    return Card(
      elevation: 8,
      shadowColor: AppColors.primary.withValues(alpha: 0.12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xxxl,
          vertical: 36,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Logo ───────────────────────────────────────────────
              FadeTransition(
                opacity: _logoFade,
                child: _buildLogo(),
              ),
              const SizedBox(height: AppSpacing.lg),

              // ── Title & subtitle ───────────────────────────────────
              FadeTransition(
                opacity: _titleFade,
                child: _buildTitleBlock(isDark, theme),
              ),
              const SizedBox(height: AppSpacing.xxl + 4),

              // ── Role toggle ────────────────────────────────────────
              FadeTransition(
                opacity: _toggleFade,
                child: _buildRoleToggle(isDark),
              ),
              const SizedBox(height: AppSpacing.xxl),

              // ── Fields ─────────────────────────────────────────────
              FadeTransition(
                opacity: _fieldsFade,
                child: _buildFields(isDark),
              ),
              const SizedBox(height: AppSpacing.xxl),

              // ── Button + link ──────────────────────────────────────
              FadeTransition(
                opacity: _buttonFade,
                child: _buildActions(isDark),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Logo icon ──────────────────────────────────────────────────────────
  Widget _buildLogo() {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.accent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Icon(
        Icons.school_rounded,
        color: AppColors.textOnPrimary,
        size: 32,
      ),
    );
  }

  // ── Title block ────────────────────────────────────────────────────────
  Widget _buildTitleBlock(bool isDark, ThemeData theme) {
    return Column(
      children: [
        Text(
          'Create Account',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.textDarkPrimary : AppColors.primary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Sign up to start using Speakera',
          style: theme.textTheme.bodySmall?.copyWith(
            color: isDark
                ? AppColors.textDarkSecondary
                : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  // ── Role toggle (Admin / Student) ──────────────────────────────────────
  Widget _buildRoleToggle(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.inputDarkFill : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: UserRole.values.map((role) {
          final isSelected = _selectedRole == role;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedRole = role),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isDark ? AppColors.accent : AppColors.primary)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: (isDark
                                    ? AppColors.accent
                                    : AppColors.primary)
                                .withValues(alpha: 0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : [],
                ),
                alignment: Alignment.center,
                child: Text(
                  role == UserRole.admin ? 'Admin' : 'Student',
                  style: TextStyle(
                    color: isSelected
                        ? AppColors.textOnPrimary
                        : (isDark
                            ? AppColors.textDarkSecondary
                            : AppColors.textSecondary),
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Form fields ────────────────────────────────────────────────────────
  Widget _buildFields(bool isDark) {
    return Column(
      children: [
        // Full Name
        CustomTextField(
          controller: _nameController,
          labelText: 'Full Name',
          hintText: 'Enter your full name',
          prefixIcon: Icons.person_outline,
          keyboardType: TextInputType.name,
          textInputAction: TextInputAction.next,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter your name';
            }
            if (value.trim().length < 2) {
              return 'Name must be at least 2 characters';
            }
            return null;
          },
        ),
        const SizedBox(height: AppSpacing.lg),

        // Email
        CustomTextField(
          controller: _emailController,
          labelText: 'Email',
          hintText: 'your.email@example.com',
          prefixIcon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter your email';
            }
            if (!RegExp(r'^[\w\-.]+@([\w\-]+\.)+[\w\-]{2,4}$')
                .hasMatch(value.trim())) {
              return 'Please enter a valid email address';
            }
            return null;
          },
        ),
        const SizedBox(height: AppSpacing.lg),

        // Password
        CustomTextField(
          controller: _passwordController,
          labelText: 'Password',
          hintText: 'At least 6 characters',
          prefixIcon: Icons.lock_outline,
          obscureText: !_isPasswordVisible,
          textInputAction: TextInputAction.next,
          suffixIcon: IconButton(
            icon: Icon(
              _isPasswordVisible
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              size: 20,
              color: isDark
                  ? AppColors.textDarkSecondary
                  : AppColors.textSecondary,
            ),
            onPressed: () =>
                setState(() => _isPasswordVisible = !_isPasswordVisible),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter a password';
            }
            if (value.length < 6) {
              return 'Password must be at least 6 characters';
            }
            return null;
          },
        ),
        const SizedBox(height: AppSpacing.lg),

        // Confirm Password
        CustomTextField(
          controller: _confirmPasswordController,
          labelText: 'Confirm Password',
          hintText: 'Re-enter your password',
          prefixIcon: Icons.lock_outline,
          obscureText: !_isConfirmPasswordVisible,
          textInputAction: TextInputAction.done,
          suffixIcon: IconButton(
            icon: Icon(
              _isConfirmPasswordVisible
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              size: 20,
              color: isDark
                  ? AppColors.textDarkSecondary
                  : AppColors.textSecondary,
            ),
            onPressed: () => setState(
                () => _isConfirmPasswordVisible = !_isConfirmPasswordVisible),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please confirm your password';
            }
            if (value != _passwordController.text) {
              return 'Passwords do not match';
            }
            return null;
          },
        ),

        // Error message
        if (_errorMessage != null) ...[
          const SizedBox(height: AppSpacing.md),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: Border.all(
                color: AppColors.error.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline,
                    color: AppColors.error, size: 18),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(
                      color: AppColors.error,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // ── Sign-up button + login link ────────────────────────────────────────
  Widget _buildActions(bool isDark) {
    return Column(
      children: [
        PrimaryButton(
          text: 'Create Account',
          isLoading: _isLoading,
          onPressed: _handleRegister,
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Already have an account? ',
              style: TextStyle(
                color: isDark
                    ? AppColors.textDarkSecondary
                    : AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
            GestureDetector(
              onTap: widget.onSwitchToLogin,
              child: Text(
                'Sign In',
                style: TextStyle(
                  color: isDark ? AppColors.accent : AppColors.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
