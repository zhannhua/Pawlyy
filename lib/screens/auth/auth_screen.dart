import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/pawly_theme.dart';
import '../../providers/auth_controller.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _passwordConfirmation = TextEditingController();
  bool _isLogin = true;
  bool _isLoading = false;
  bool _showPassword = false;
  bool _awaitingEmailVerification = false;
  bool _isResending = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _password.dispose();
    _passwordConfirmation.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final auth = context.read<AuthController>();
      if (_isLogin) {
        await auth.signIn(email: _email.text, password: _password.text);
      } else {
        final requiresVerification = await auth.signUp(
          displayName: _name.text,
          phone: _normalisePhone(_phone.text),
          email: _email.text,
          password: _password.text,
        );
        if (mounted && requiresVerification) {
          setState(() => _awaitingEmailVerification = true);
        }
      }
    } on AuthException catch (error) {
      _showMessage(error.message, isError: true);
    } catch (_) {
      _showMessage('Something went wrong. Please try again.', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resetPassword() async {
    final controller = TextEditingController(text: _email.text);
    final email = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset password'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(hintText: 'you@email.com'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Send link'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (email == null || email.trim().isEmpty || !mounted) return;

    try {
      await context.read<AuthController>().sendPasswordReset(email);
      if (mounted) {
        _showMessage('Password reset link sent. Please check your inbox.');
      }
    } on AuthException catch (error) {
      if (mounted) _showMessage(error.message, isError: true);
    }
  }

  String _normalisePhone(String value) =>
      value.replaceAll(RegExp(r'[\s-]'), '').replaceFirst(RegExp(r'^0'), '+60');

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? const Color(0xFFB42318) : PawlyColors.teal,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 840;
            final form = Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: _awaitingEmailVerification
                      ? _VerificationNotice(
                          email: _email.text.trim(),
                          isResending: _isResending,
                          onResend: _resendConfirmation,
                          onBack: _backToSignIn,
                        )
                      : _buildForm(),
                ),
              ),
            );
            if (!wide) return SingleChildScrollView(child: form);
            return Row(
              children: [
                const Expanded(flex: 5, child: _WelcomePanel()),
                Expanded(flex: 6, child: SingleChildScrollView(child: form)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 28),
          Semantics(
            label: 'Pawly pet services app',
            image: true,
            child: Image.asset(
              'assets/branding/pawly-logo.png',
              width: 126,
              height: 64,
              alignment: Alignment.centerLeft,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 44),
          Text(
            _isLogin ? 'Welcome back' : 'Your pet life, together',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            _isLogin
                ? 'Sign in to manage your pets and bookings.'
                : 'Join Malaysia’s thoughtful pet-care community.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 28),
          if (!_isLogin) ...[
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Your name',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (value) => value == null || value.trim().length < 2
                  ? 'Enter your name'
                  : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Mobile number',
                hintText: '012-345 6789',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
              validator: (value) {
                final phone = _normalisePhone(value ?? '');
                return RegExp(r'^\+601\d{7,9}$').hasMatch(phone)
                    ? null
                    : 'Use a Malaysian mobile number';
              },
            ),
            const SizedBox(height: 14),
          ],
          TextFormField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            decoration: const InputDecoration(
              labelText: 'Email address',
              prefixIcon: Icon(Icons.mail_outline),
            ),
            validator: (value) =>
                RegExp(r'^\S+@\S+\.\S+$').hasMatch(value ?? '')
                ? null
                : 'Enter a valid email',
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _password,
            obscureText: !_showPassword,
            autofillHints: [
              _isLogin ? AutofillHints.password : AutofillHints.newPassword,
            ],
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                tooltip: _showPassword ? 'Hide password' : 'Show password',
                onPressed: () => setState(() => _showPassword = !_showPassword),
                icon: Icon(
                  _showPassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
              ),
            ),
            validator: (value) {
              if ((value ?? '').isEmpty) return 'Enter your password';
              if (!_isLogin && value!.length < 8)
                return 'Use at least 8 characters';
              return null;
            },
            onFieldSubmitted: (_) => _submit(),
          ),
          if (!_isLogin) ...[
            const SizedBox(height: 14),
            TextFormField(
              controller: _passwordConfirmation,
              obscureText: !_showPassword,
              autofillHints: const [AutofillHints.newPassword],
              decoration: const InputDecoration(
                labelText: 'Confirm password',
                prefixIcon: Icon(Icons.lock_outline),
              ),
              validator: (value) =>
                  value == _password.text ? null : 'Passwords do not match',
              onFieldSubmitted: (_) => _submit(),
            ),
          ],
          if (_isLogin)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _resetPassword,
                child: const Text('Forgot password?'),
              ),
            ),
          const SizedBox(height: 14),
          ElevatedButton(
            onPressed: _isLoading ? null : _submit,
            child: _isLoading
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(_isLogin ? 'Sign in' : 'Create my account'),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: _isLoading
                ? null
                : () => setState(() {
                    _isLogin = !_isLogin;
                    _formKey.currentState?.reset();
                  }),
            child: Text(
              _isLogin
                  ? 'New to Pawly? Create an account'
                  : 'Already have an account? Sign in',
            ),
          ),
          if (!_isLogin) ...[
            const SizedBox(height: 10),
            const Text(
              'By continuing, you agree to receive essential account and booking updates.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Color(0xFF667085)),
            ),
          ],
        ],
      ),
    );
  }

  void _backToSignIn() {
    setState(() {
      _awaitingEmailVerification = false;
      _isLogin = true;
    });
  }

  Future<void> _resendConfirmation() async {
    if (_email.text.trim().isEmpty) return;
    setState(() => _isResending = true);
    try {
      await context.read<AuthController>().resendEmailConfirmation(_email.text);
      if (mounted) _showMessage('A new confirmation link has been sent.');
    } on AuthException catch (error) {
      if (mounted) _showMessage(error.message, isError: true);
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }
}

class _WelcomePanel extends StatelessWidget {
  const _WelcomePanel();

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      Image.asset('assets/images/pawly-auth-real.jpg', fit: BoxFit.cover),
      const ColoredBox(color: Color(0xB8093534)),
      Padding(
        padding: const EdgeInsets.all(56),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.end,
          children: const [
            Text(
              'PAWLY PET SERVICES',
              style: TextStyle(
                color: Color(0xE6FFFFFF),
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
              ),
            ),
            SizedBox(height: 14),
            Text(
              'Care that feels\nwell looked after.',
              style: TextStyle(
                color: Colors.white,
                fontSize: 46,
                height: 1.04,
                fontWeight: FontWeight.w800,
                letterSpacing: -1.8,
              ),
            ),
            SizedBox(height: 18),
            SizedBox(
              width: 380,
              child: Text(
                'Find dependable local care, plan an appointment, and keep every small routine together.',
                style: TextStyle(
                  color: Color(0xE6FFFFFF),
                  fontSize: 17,
                  height: 1.45,
                ),
              ),
            ),
            SizedBox(height: 30),
            _Feature(
              icon: Icons.verified_outlined,
              label: 'Verified care partners',
            ),
            SizedBox(height: 12),
            _Feature(
              icon: Icons.calendar_today_outlined,
              label: 'Appointments in Ringgit',
            ),
          ],
        ),
      ),
    ],
  );
}

class _Feature extends StatelessWidget {
  const _Feature({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, color: Color(0xE6FFFFFF)),
      SizedBox(width: 12),
      Text(
        label,
        style: TextStyle(color: Color(0xE6FFFFFF), fontWeight: FontWeight.w700),
      ),
    ],
  );
}

class _VerificationNotice extends StatelessWidget {
  const _VerificationNotice({
    required this.email,
    required this.isResending,
    required this.onResend,
    required this.onBack,
  });

  final String email;
  final bool isResending;
  final VoidCallback onResend;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Container(
        width: 72,
        height: 72,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: Color(0x1A167C80),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.mark_email_read_outlined,
          size: 36,
          color: PawlyColors.teal,
        ),
      ),
      const SizedBox(height: 28),
      Text(
        'Check your email',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.headlineMedium,
      ),
      const SizedBox(height: 12),
      Text(
        'We sent a verification link to $email. Open it, then return here to sign in to Pawly.',
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 30),
      OutlinedButton(
        onPressed: isResending ? null : onResend,
        child: isResending
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Text('Resend confirmation email'),
      ),
      const SizedBox(height: 10),
      ElevatedButton(onPressed: onBack, child: const Text('Back to sign in')),
    ],
  );
}

class UpdatePasswordScreen extends StatefulWidget {
  const UpdatePasswordScreen({super.key});

  @override
  State<UpdatePasswordScreen> createState() => _UpdatePasswordScreenState();
}

class _UpdatePasswordScreenState extends State<UpdatePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await context.read<AuthController>().updatePassword(_password.text);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Your password has been updated.')),
        );
      }
    } on AuthException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.message),
            backgroundColor: const Color(0xFFB42318),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.lock_reset_rounded,
                  size: 52,
                  color: PawlyColors.teal,
                ),
                const SizedBox(height: 22),
                Text(
                  'Set a new password',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 10),
                const Text(
                  'Choose a new password for your Pawly account.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                TextFormField(
                  controller: _password,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'New password',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  validator: (value) => (value ?? '').length >= 8
                      ? null
                      : 'Use at least 8 characters',
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _confirmation,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Confirm new password',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  validator: (value) =>
                      value == _password.text ? null : 'Passwords do not match',
                  onFieldSubmitted: (_) => _save(),
                ),
                const SizedBox(height: 22),
                ElevatedButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          height: 21,
                          width: 21,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Update password'),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
