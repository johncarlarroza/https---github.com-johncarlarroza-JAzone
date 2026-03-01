import 'package:flutter/material.dart';
import 'package:jazone_1/pages/citizen_base_page.dart';
import 'package:jazone_1/responder/responder_base_page.dart';
import '../services/auth_service.dart';
import 'signup_page.dart';

const kPrimaryBlue = Color(0xFF1565C0);
const kDeepBlue = Color(0xFF0D47A1);
const kAccentOrange = Color(0xFFFF8F00);

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final AuthService _authService = AuthService();

  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();

  String role = "citizen";
  bool usePhone = true;
  bool loading = false;

  @override
  void dispose() {
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  Color get dynamicColor => role == "citizen" ? kPrimaryBlue : kAccentOrange;

  List<Color> get gradientColors => role == "citizen"
      ? const [
          Color(0xFF42A5F5), // Light Blue
          Color(0xFF0D47A1), // Deep Blue
        ]
      : const [
          Color(0xFFFFB74D), // Light Orange
          Color(0xFFE65100), // Deep Orange
        ];

  Future<void> _login() async {
    setState(() => loading = true);
    try {
      final selectedRole = role == "citizen"
          ? UserRole.citizen
          : UserRole.responder;

      if (usePhone) {
        await _authService.signInWithPhonePassword(
          phone: _phone.text,
          password: _password.text,
          selectedRole: selectedRole,
        );
      } else {
        await _authService.signInWithEmailPassword(
          email: _email.text,
          password: _password.text,
          selectedRole: selectedRole,
        );
      }

      if (!mounted) return;

      if (selectedRole == UserRole.citizen) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const CitizenBasePage()),
          (route) => false,
        );
      } else {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const ResponderBasePage()),
          (route) => false,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("$e")));
    }

    if (mounted) setState(() => loading = false);
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: dynamicColor, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: gradientColors,
          ),
        ),
        child: Center(
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
                  Image.asset("assets/logo.png", height: 100),

                  const SizedBox(height: 15),

                  Text(
                    "Jazone",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: dynamicColor,
                    ),
                  ),

                  const SizedBox(height: 20),

                  DropdownButtonFormField<String>(
                    value: role,
                    decoration: _inputDecoration("Select Role"),
                    items: const [
                      DropdownMenuItem(
                        value: "citizen",
                        child: Text("Citizen"),
                      ),
                      DropdownMenuItem(
                        value: "responder",
                        child: Text("Responder"),
                      ),
                    ],
                    onChanged: (v) => setState(() => role = v!),
                  ),

                  const SizedBox(height: 15),

                  SwitchListTile(
                    activeColor: dynamicColor,
                    title: Text(usePhone ? "Using Phone" : "Using Email"),
                    value: usePhone,
                    onChanged: (v) => setState(() => usePhone = v),
                  ),

                  const SizedBox(height: 10),

                  if (usePhone)
                    TextField(
                      controller: _phone,
                      keyboardType: TextInputType.phone,
                      decoration: _inputDecoration(
                        "Phone Number (09xxxxxxxxx)",
                      ),
                    ),

                  if (!usePhone)
                    TextField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      decoration: _inputDecoration("Email"),
                    ),

                  const SizedBox(height: 15),

                  TextField(
                    controller: _password,
                    obscureText: true,
                    decoration: _inputDecoration("Password"),
                  ),

                  const SizedBox(height: 25),

                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: dynamicColor,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: loading ? null : _login,
                    child: loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            "Login",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                  ),

                  const SizedBox(height: 12),

                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SignupPage()),
                      );
                    },
                    child: Text(
                      "Create Account",
                      style: TextStyle(color: dynamicColor),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
