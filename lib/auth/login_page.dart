import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../widgets/auth_scaffold.dart';
import 'signup_page.dart';

class LoginPage extends StatefulWidget {
  final String selectedRole;
  const LoginPage({super.key, required this.selectedRole});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _loading = false;

  Future<void> _login() async {
    final auth = context.read<AuthService>();

    setState(() => _loading = true);

    try {
      await auth.signInWithEmail(email: _email.text, password: _pass.text);

      if (mounted) Navigator.popUntil(context, (r) => r.isFirst);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("$e")));
    }

    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final isResponder = widget.selectedRole == "responder";

    return AuthScaffold(
      child: Column(
        children: [
          Image.asset('assets/logo.png', height: 100),
          const SizedBox(height: 20),

          _card(
            child: Column(
              children: [
                Text(
                  "Login as ${widget.selectedRole.toUpperCase()}",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),

                TextField(
                  controller: _email,
                  decoration: const InputDecoration(labelText: "Email"),
                ),
                const SizedBox(height: 12),

                TextField(
                  controller: _pass,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: "Password"),
                ),
                const SizedBox(height: 20),

                ElevatedButton(
                  onPressed: _loading ? null : _login,
                  child: _loading
                      ? const CircularProgressIndicator()
                      : const Text("Login"),
                ),

                if (!isResponder)
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SignupPage()),
                      );
                    },
                    child: const Text("Create Citizen Account"),
                  )
                else
                  const Padding(
                    padding: EdgeInsets.only(top: 10),
                    child: Text(
                      "Responder accounts are created by Admin.",
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(blurRadius: 10, color: Colors.black12)],
      ),
      child: child,
    );
  }
}
