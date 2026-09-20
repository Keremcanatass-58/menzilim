import 'package:flutter/material.dart';

import '../../../core/auth/auth_scope.dart';
import '../../../core/design/design_system.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../models/login_request.dart';
import '../services/auth_service.dart';
import '../../settings/screens/settings_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  /// Testlerde sahte servis verilebilir; normalde gerçek API kullanılır.
  final AuthService? authService;

  const LoginScreen({super.key, this.authService});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final ApiClient _apiClient = ApiClient();

  late final AuthService _authService;

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _authService = widget.authService ?? AuthService(_apiClient);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showMessage(context.l10n.loginFillFields);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _authService.login(
        LoginRequest(
          email: email,
          password: password,
        ),
      );

      if (!mounted) return;

      _showMessage(context.l10n.loginSuccess);

      // Oturumu kur; Dashboard/Onboarding yönlendirmesini AuthGate yapar.
      await AuthScope.of(context).signIn(
        token: response.token,
        userId: response.userId,
        email: response.email,
      );
    } catch (e) {
      if (!mounted) return;

      _showMessage(context.l10n.loginFailed);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  void _openRegisterScreen() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => const RegisterScreen(),
      ),
    );
  }

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const SettingsScreen(),
      ),
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
                constraints: const BoxConstraints(maxWidth: 440),
                child: MenzilimEntrance(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Expanded(child: AuthBrandMark()),
                          // Giriş yapmadan da dil/tema seçilebilsin.
                          IconButton(
                            tooltip: l10n.settingsTitle,
                            onPressed: _openSettings,
                            icon: const Icon(Icons.settings_outlined),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.section),
                      Text(
                        l10n.loginTitle,
                        style: context.textStyles.headlineLarge,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        l10n.loginSubtitle,
                        style: context.textStyles.bodyLarge?.copyWith(
                          color: context.colors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
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
                        onSubmitted: (_) => _login(),
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
                      const SizedBox(height: AppSpacing.xl),
                      MenzilimButton(
                        label: l10n.loginButton,
                        isLoading: _isLoading,
                        onPressed: _login,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              l10n.loginNoAccount,
                              style: context.textStyles.bodyMedium?.copyWith(
                                color: context.colors.onSurfaceVariant,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed:
                                _isLoading ? null : _openRegisterScreen,
                            child: Text(l10n.registerButton),
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
      ),
    );
  }
}

/// Giriş/kayıt ekranlarındaki marka alanı: sembol, yazı ve slogan.
class AuthBrandMark extends StatelessWidget {
  const AuthBrandMark({super.key});

  @override
  Widget build(BuildContext context) {
    return MenzilimLogo(
      markSize: 40,
      wordmarkStyle: context.textStyles.titleLarge,
      showTagline: true,
    );
  }
}
