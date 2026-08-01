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
  bool _isLogin = true;
  bool _isLoading = false;
  bool _showPassword = false;
  bool _awaitingEmailVerification = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _password.dispose();
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
                      ? _VerificationNotice(onBack: _backToSignIn)
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
          Row(
            children: [
              Container(
                height: 46,
                width: 46,
                decoration: const BoxDecoration(
                  color: PawlyColors.teal,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.pets_rounded, color: Colors.white),
              ),
              const SizedBox(width: 12),
              const Text(
                'Pawly',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
              ),
            ],
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
                : 'Join Malaysia’s friendly pet-care community.',
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
}

class _WelcomePanel extends StatelessWidget {
  const _WelcomePanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: PawlyColors.teal,
      padding: const EdgeInsets.all(56),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.pets_rounded, color: Colors.white, size: 56),
          SizedBox(height: 28),
          Text(
            'Better days\nfor every paw.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 46,
              height: 1.04,
              fontWeight: FontWeight.w900,
              letterSpacing: -2,
            ),
          ),
          SizedBox(height: 20),
          Text(
            'Book trusted local care, organise routines, and keep your pet’s profile close at hand.',
            style: TextStyle(
              color: Color(0xE6FFFFFF),
              fontSize: 18,
              height: 1.45,
            ),
          ),
          SizedBox(height: 36),
          _Feature(
            icon: Icons.verified_user_outlined,
            label: 'Verified pet-care partners',
          ),
          SizedBox(height: 14),
          _Feature(
            icon: Icons.calendar_month_outlined,
            label: 'Simple bookings in RM',
          ),
          SizedBox(height: 14),
          _Feature(
            icon: Icons.favorite_outline,
            label: 'Daily care in one calm place',
          ),
        ],
      ),
    );
  }
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
  const _VerificationNotice({required this.onBack});

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
      const Text(
        'We sent a verification link to your inbox. Verify your email, then sign in to Pawly.',
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 30),
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
