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
  bool _obscurePassword = true;

  @override
  void dispose() {
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  Color get dynamicColor => role == "citizen" ? kPrimaryBlue : kAccentOrange;

  List<Color> get gradientColors => role == "citizen"
      ? const [Color(0xFF6EC6FF), Color(0xFF1E88E5), Color(0xFF0D47A1)]
      : const [Color(0xFFFFCC80), Color(0xFFFF8F00), Color(0xFFE65100)];

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("$e"),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red.shade600,
        ),
      );
    }

    if (mounted) setState(() => loading = false);
  }

  InputDecoration _inputDecoration(String label, {IconData? prefixIcon}) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        color: Colors.grey.shade700,
        fontWeight: FontWeight.w500,
      ),
      prefixIcon: prefixIcon != null
          ? Icon(prefixIcon, color: dynamicColor)
          : null,
      filled: true,
      fillColor: Colors.white.withOpacity(0.96),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: dynamicColor, width: 2),
      ),
    );
  }

  Widget _buildTopHeader() {
    return Column(
      children: [
        Container(
          height: 92,
          width: 92,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.18),
            border: Border.all(color: Colors.white.withOpacity(0.25)),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Image.asset("assets/logo.png"),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          "Welcome Back",
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          "Login to continue to Jazone",
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withOpacity(0.9),
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildRoleSelector() {
    return DropdownButtonFormField<String>(
      value: role,
      decoration: _inputDecoration(
        "Select Role",
        prefixIcon: Icons.badge_outlined,
      ),
      icon: Icon(Icons.keyboard_arrow_down_rounded, color: dynamicColor),
      items: const [
        DropdownMenuItem(value: "citizen", child: Text("Citizen")),
        DropdownMenuItem(value: "responder", child: Text("Responder")),
      ],
      onChanged: (v) => setState(() => role = v!),
    );
  }

  Widget _buildLoginMethodToggle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: dynamicColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: dynamicColor.withOpacity(0.15)),
      ),
      child: SwitchListTile(
        dense: true,
        activeColor: dynamicColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
        title: Text(
          usePhone ? "Using Phone Number" : "Using Email Address",
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Text(
          usePhone
              ? "Login with your registered phone"
              : "Login with your registered email",
          style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
        ),
        value: usePhone,
        onChanged: (v) => setState(() => usePhone = v),
      ),
    );
  }

  Widget _buildLoginCard() {
    return Container(
      width: 430,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.16),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withOpacity(0.20)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 30,
            offset: Offset(0, 18),
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.92),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Jazone",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: dynamicColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "Fast, secure, and role-based access",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
            ),
            const SizedBox(height: 22),

            _buildRoleSelector(),
            const SizedBox(height: 16),

            _buildLoginMethodToggle(),
            const SizedBox(height: 16),

            if (usePhone)
              TextField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                decoration: _inputDecoration(
                  "Phone Number (09xxxxxxxxx)",
                  prefixIcon: Icons.phone_android_rounded,
                ),
              ),

            if (!usePhone)
              TextField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: _inputDecoration(
                  "Email",
                  prefixIcon: Icons.email_outlined,
                ),
              ),

            const SizedBox(height: 16),

            TextField(
              controller: _password,
              obscureText: _obscurePassword,
              decoration:
                  _inputDecoration(
                    "Password",
                    prefixIcon: Icons.lock_outline_rounded,
                  ).copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_rounded
                            : Icons.visibility_rounded,
                        color: dynamicColor,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: dynamicColor,
                  elevation: 8,
                  shadowColor: dynamicColor.withOpacity(0.35),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: loading ? null : _login,
                child: loading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.4,
                        ),
                      )
                    : const Text(
                        "Login",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                          color: Colors.white,
                        ),
                      ),
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
              child: RichText(
                text: TextSpan(
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                  children: [
                    const TextSpan(text: "Don’t have an account? "),
                    TextSpan(
                      text: "Create Account",
                      style: TextStyle(
                        color: dynamicColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackgroundDecor() {
    return Stack(
      children: [
        Positioned(
          top: -70,
          left: -40,
          child: Container(
            height: 180,
            width: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.10),
            ),
          ),
        ),
        Positioned(
          top: 120,
          right: -50,
          child: Container(
            height: 140,
            width: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.08),
            ),
          ),
        ),
        Positioned(
          bottom: -70,
          left: -20,
          child: Container(
            height: 170,
            width: 170,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.07),
            ),
          ),
        ),
        Positioned(
          bottom: 40,
          right: 20,
          child: Container(
            height: 100,
            width: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.06),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradientColors,
          ),
        ),
        child: Stack(
          children: [
            _buildBackgroundDecor(),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 24,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildTopHeader(),
                      const SizedBox(height: 28),
                      _buildLoginCard(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
