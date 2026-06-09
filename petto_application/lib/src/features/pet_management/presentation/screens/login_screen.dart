import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../widgets/auth_widgets.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';
import 'pet_profile_screen.dart';

/// Feature 1 - UC: Login.
///
/// UI-only for now: the backend has no auth endpoint yet, so a valid form
/// just routes to the pet profile. Wire to a real /auth/login later.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  bool _loading = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    // TODO: call auth repository (POST /auth/login) once the backend exists.
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() => _loading = false);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const PetProfileScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'ยินดีต้อนรับกลับ',
      subtitle: 'เข้าสู่ระบบเพื่อดูแลน้องของคุณต่อ',
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            PettoTextField(
              controller: _email,
              label: 'อีเมล',
              icon: Icons.mail_outline,
              keyboardType: TextInputType.emailAddress,
              validator: (v) => (v == null || !v.contains('@'))
                  ? 'กรุณากรอกอีเมลให้ถูกต้อง'
                  : null,
            ),
            const SizedBox(height: 16),
            PettoTextField(
              controller: _password,
              label: 'รหัสผ่าน',
              icon: Icons.lock_outline,
              obscure: _obscure,
              validator: (v) =>
                  (v == null || v.length < 6) ? 'รหัสผ่านอย่างน้อย 6 ตัวอักษร' : null,
              suffix: IconButton(
                icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility,
                    color: AppTheme.mutedText),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
                ),
                child: const Text('ลืมรหัสผ่าน?',
                    style: TextStyle(
                        fontFamily: AppTheme.sansFontFamily,
                        color: AppTheme.secondaryColor,
                        fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 8),
            PettoPrimaryButton(label: 'เข้าสู่ระบบ', onPressed: _login, loading: _loading),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('ยังไม่มีบัญชี?',
                    style: TextStyle(
                        fontFamily: AppTheme.sansFontFamily, color: AppTheme.mutedText)),
                TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const RegisterScreen()),
                  ),
                  child: const Text('สมัครสมาชิก',
                      style: TextStyle(
                          fontFamily: AppTheme.sansFontFamily,
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
