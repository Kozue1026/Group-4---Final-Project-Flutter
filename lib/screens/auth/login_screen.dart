import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../demo/demo_auth.dart';
import '../../demo/demo_config.dart';
import '../../providers/auth_provider.dart';
import 'register_screen.dart';

/// Option A: one-tap demo login on top. Email/Google buttons also work
/// against the fake backend in demo mode.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _demoBusy = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _demoLogin() async {
    setState(() => _demoBusy = true);
    await context.read<DemoAuth>().oneTapLogin();
    if (mounted) setState(() => _demoBusy = false);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('EventHub — Sign in')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const Text('Discover and register for school events.',
                  style: TextStyle(fontSize: 16)),
              const SizedBox(height: 16),
              if (kDemoMode) ...[
                FilledButton.icon(
                  onPressed: _demoBusy ? null : _demoLogin,
                  icon: const Icon(Icons.bolt),
                  label: Text(_demoBusy
                      ? 'Signing in…'
                      : 'Continue as student@demo.school'),
                ),
                const SizedBox(height: 8),
                const Row(children: [
                  Expanded(child: Divider()),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text('or'),
                  ),
                  Expanded(child: Divider()),
                ]),
                const SizedBox(height: 8),
              ],
              TextFormField(
                controller: _email,
                decoration: const InputDecoration(
                    labelText: 'Email', border: OutlineInputBorder()),
                keyboardType: TextInputType.emailAddress,
                validator: (v) =>
                    (v == null || !v.contains('@')) ? 'Enter a valid email' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _password,
                decoration: const InputDecoration(
                    labelText: 'Password', border: OutlineInputBorder()),
                obscureText: true,
                validator: (v) =>
                    (v == null || v.length < 6) ? 'Min 6 characters' : null,
              ),
              if (auth.error != null && !kDemoMode) ...[
                const SizedBox(height: 12),
                Text(auth.error!,
                    style: const TextStyle(color: Colors.red)),
              ],
              const SizedBox(height: 16),
              FilledButton.tonal(
                onPressed: auth.busy
                    ? null
                    : () async {
                        if (kDemoMode) {
                          await _demoLogin();
                          return;
                        }
                        if (!_formKey.currentState!.validate()) return;
                        await auth.signIn(_email.text, _password.text);
                      },
                child: const Text('Sign in'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: auth.busy && !kDemoMode
                    ? null
                    : () async {
                        if (kDemoMode) {
                          await _demoLogin();
                          return;
                        }
                        await auth.signInGoogle();
                      },
                icon: const Icon(Icons.g_mobiledata),
                label: const Text('Continue with Google'),
              ),
              if (!kDemoMode)
                TextButton(
                  onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const RegisterScreen())),
                  child: const Text("Don't have an account? Register"),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
