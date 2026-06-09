import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../widgets/auth_widgets.dart';

/// Feature 1 - UC: Register.
/// UI-only for now (no backend /auth/register yet) — on success it pops back
/// to Login with a confirmation snackbar.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscure = true;
  bool _loading = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    // TODO: call auth repository (POST /auth/register) once the backend exists.
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    setState(() => _loading = false);
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('สมัครสมาชิกสำเร็จ! เข้าสู่ระบบได้เลย')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      showBack: true,
      title: 'สร้างบัญชีใหม่',
      subtitle: 'เริ่มต้นดูแลสุขภาพน้องกับ Petto',
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            PettoTextField(
              controller: _name,
              label: 'ชื่อ',
              icon: Icons.person_outline,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'กรุณากรอกชื่อ' : null,
            ),
            const SizedBox(height: 16),
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
            const SizedBox(height: 16),
            PettoTextField(
              controller: _confirm,
              label: 'ยืนยันรหัสผ่าน',
              icon: Icons.lock_outline,
              obscure: _obscure,
              validator: (v) =>
                  (v != _password.text) ? 'รหัสผ่านไม่ตรงกัน' : null,
            ),
            const SizedBox(height: 24),
            PettoPrimaryButton(
                label: 'สมัครสมาชิก', onPressed: _register, loading: _loading),
          ],
        ),
      ),
    );
  }
}
