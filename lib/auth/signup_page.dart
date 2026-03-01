import 'package:flutter/material.dart';
import '../services/auth_service.dart';

const kPrimaryBlue = Color(0xFF1565C0);
const kDeepBlue = Color(0xFF0D47A1);
const kAccentOrange = Color(0xFFFF8F00);

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final AuthService _authService = AuthService();

  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();

  String role = "citizen";
  bool usePhone = true;
  bool loading = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _signup() async {
    setState(() => loading = true);
    try {
      final name = _name.text.trim();
      if (name.isEmpty) throw Exception("Name is required.");
      if (_password.text.trim().length < 6)
        throw Exception("Password must be at least 6 characters.");

      final selectedRole = role == "citizen"
          ? UserRole.citizen
          : UserRole.responder;

      if (usePhone) {
        if (_phone.text.trim().isEmpty)
          throw Exception("Phone number is required.");
        await _authService.signUpWithPhonePassword(
          phone: _phone.text,
          password: _password.text,
          name: name,
          role: selectedRole,
        );
      } else {
        if (_email.text.trim().isEmpty) throw Exception("Email is required.");
        await _authService.signUpWithEmailPassword(
          email: _email.text,
          password: _password.text,
          name: name,
          role: selectedRole,
        );
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("$e")));
    }

    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kDeepBlue,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: const [
                BoxShadow(blurRadius: 20, color: Colors.black26),
              ],
            ),
            child: Column(
              children: [
                const Text(
                  "Create Jazone Account",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: kPrimaryBlue,
                  ),
                ),
                const SizedBox(height: 20),

                TextField(
                  controller: _name,
                  decoration: const InputDecoration(labelText: "Full Name"),
                ),

                const SizedBox(height: 15),

                DropdownButtonFormField<String>(
                  value: role,
                  decoration: const InputDecoration(labelText: "Select Role"),
                  items: const [
                    DropdownMenuItem(value: "citizen", child: Text("Citizen")),
                    DropdownMenuItem(
                      value: "responder",
                      child: Text("Responder"),
                    ),
                  ],
                  onChanged: (v) => setState(() => role = v!),
                ),

                const SizedBox(height: 15),

                SwitchListTile(
                  activeColor: kAccentOrange,
                  title: Text(usePhone ? "Using Phone" : "Using Email"),
                  value: usePhone,
                  onChanged: (v) => setState(() => usePhone = v),
                ),

                if (usePhone)
                  TextField(
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: "Phone Number (09xxxxxxxxx)",
                    ),
                  ),

                if (!usePhone)
                  TextField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: "Email"),
                  ),

                const SizedBox(height: 15),

                TextField(
                  controller: _password,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: "Password"),
                ),

                const SizedBox(height: 20),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kAccentOrange,
                    minimumSize: const Size(double.infinity, 45),
                  ),
                  onPressed: loading ? null : _signup,
                  child: loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text("Sign Up"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
