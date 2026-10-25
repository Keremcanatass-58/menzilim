import 'package:flutter/material.dart';

import '../../../core/auth/auth_scope.dart';
import '../../../core/design/design_system.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/theme/app_theme.dart';

import '../../../core/network/api_client.dart';
import '../models/register_request.dart';
import '../services/auth_service.dart';
import 'login_screen.dart' show LoginScreen, AuthBrandMark;

class RegisterScreen extends StatefulWidget {
  /// Testlerde sahte servis verilebilir; normalde gerçek API kullanılır.
  final AuthService? authService;

  const RegisterScreen({super.key, this.authService});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final ApiClient _apiClient = ApiClient();

  late final AuthService _authService;

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    _authService = widget.authService ?? AuthService(_apiClient);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      _showMessage(context.l10n.registerFillAll);
      return;
    }

    if (!email.contains('@')) {
      _showMessage(context.l10n.registerInvalidEmail);
      return;
    }

    if (password.length < 6) {
      _showMessage(context.l10n.registerPasswordTooShort);
      return;
    }

    if (password != confirmPassword) {
      _showMessage(context.l10n.registerPasswordsMismatch);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _authService.register(
        RegisterRequest(email: email, password: password),
      );

      if (!mounted) return;

      _showMessage(context.l10n.registerSuccess);

      // Yeni hesapta profil yoktur; AuthGate Onboarding'e yönlendirir.
      await AuthScope.of(context).signIn(
        token: response.token,
        userId: response.userId,
        email: response.email,
      );
    } catch (e) {
      if (!mounted) return;

      if (e is ApiException) {
        _showMessage(e.message);
      } else {
        _showMessage(context.l10n.registerUnexpectedError);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  void _openLoginScreen() {
    if (_isLoading) return;

    final navigator = Navigator.of(context);

    // Bu ekran Login'in üstüne açıldıysa geri dönmek yeterlidir; altta
    // AuthGate kalır ve oturum açılınca yönlendirmeyi o yapar.
    if (navigator.canPop()) {
      navigator.pop();
      return;
    }

    navigator.pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => Center(
            child: SingleChildScrollView(
              padding: AppSpacing.screen(constraints.maxWidth),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: MenzilimEntrance(
                  child: MenzilimCard(
                    padding: EdgeInsets.all(
                      constraints.maxWidth < 480
                          ? AppSpacing.lg
                          : AppSpacing.xxl,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const AuthBrandMark(),
                        const SizedBox(height: AppSpacing.section),
                        Text(
                          l10n.registerTitle,
                          style: context.textStyles.headlineLarge,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          l10n.registerSubtitle,
                          style: context.textStyles.bodyLarge?.copyWith(
                            color: context.colors.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xxl),
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            labelText: l10n.emailLabel,
                            hintText: l10n.emailHint,
                            prefixIcon: const Icon(Icons.email_outlined),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        TextField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            labelText: l10n.passwordLabel,
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        TextField(
                          controller: _confirmPasswordController,
                          obscureText: _obscureConfirmPassword,
                          onSubmitted: (_) => _register(),
                          textInputAction: TextInputAction.done,
                          decoration: InputDecoration(
                            labelText: l10n.registerConfirmPasswordLabel,
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              onPressed: () {
                                setState(() {
                                  _obscureConfirmPassword =
                                      !_obscureConfirmPassword;
                                });
                              },
                              icon: Icon(
                                _obscureConfirmPassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        MenzilimButton(
                          label: l10n.registerCreateAccount,
                          isLoading: _isLoading,
                          onPressed: _register,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Center(
                          child: TextButton(
                            onPressed: _isLoading ? null : _openLoginScreen,
                            child: Text(
                              l10n.registerHaveAccount,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
