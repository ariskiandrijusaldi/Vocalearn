import 'package:flutter/material.dart';

import '../../../../domain/entities/user.dart';

class UserFormResult {
  const UserFormResult({
    required this.fullName,
    required this.email,
    this.password,
    this.nim,
    this.nip,
    this.prodi,
  });

  final String fullName;
  final String email;
  final String? password;
  final String? nim;
  final String? nip;
  final String? prodi;
}

Future<UserFormResult?> showUserFormDialog(
  BuildContext context, {
  required UserRole role,
  User? existing,
}) {
  return showDialog<UserFormResult>(
    context: context,
    builder: (_) => _UserFormDialog(role: role, existing: existing),
  );
}

class _UserFormDialog extends StatefulWidget {
  const _UserFormDialog({required this.role, this.existing});

  final UserRole role;
  final User? existing;

  @override
  State<_UserFormDialog> createState() => _UserFormDialogState();
}

class _UserFormDialogState extends State<_UserFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _fullName;
  late final TextEditingController _email;
  late final TextEditingController _password;
  late final TextEditingController _nim;
  late final TextEditingController _nip;
  late final TextEditingController _prodi;

  bool get _isNew => widget.existing == null;
  bool get _isStudent => widget.role == UserRole.student;
  bool get _isLecturer => widget.role == UserRole.lecturer;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _fullName = TextEditingController(text: existing?.fullName ?? '');
    _email = TextEditingController(text: existing?.email ?? '');
    _password = TextEditingController();
    _nim = TextEditingController(text: existing?.nim ?? '');
    _nip = TextEditingController(text: existing?.nip ?? '');
    _prodi = TextEditingController(text: existing?.prodi ?? '');
  }

  @override
  void dispose() {
    _fullName.dispose();
    _email.dispose();
    _password.dispose();
    _nim.dispose();
    _nip.dispose();
    _prodi.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(
      UserFormResult(
        fullName: _fullName.text.trim(),
        email: _email.text.trim(),
        password: _isNew ? _password.text : null,
        nim: _isStudent ? _nim.text.trim() : null,
        nip: _isLecturer ? _nip.text.trim() : null,
        prodi: _prodi.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title =
        widget.existing == null ? 'Tambah ${widget.role.label}' : 'Edit ${widget.role.label}';
    return AlertDialog(
      title: Text(title),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _fullName,
                decoration: const InputDecoration(labelText: 'Nama Lengkap'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Nama wajib diisi' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _email,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  final value = v?.trim() ?? '';
                  if (value.isEmpty) return 'Email wajib diisi';
                  if (!value.contains('@')) return 'Format email tidak valid';
                  return null;
                },
              ),
              if (_isNew) ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _password,
                  decoration: const InputDecoration(labelText: 'Password'),
                  obscureText: true,
                  validator: (v) {
                    final value = v ?? '';
                    if (value.isEmpty) return 'Password wajib diisi';
                    if (value.length < 6) return 'Password minimal 6 karakter';
                    return null;
                  },
                ),
              ],
              const SizedBox(height: 12),
              if (_isStudent) ...[
                TextFormField(
                  controller: _nim,
                  decoration: const InputDecoration(labelText: 'NIM'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'NIM wajib diisi' : null,
                ),
                const SizedBox(height: 12),
              ],
              if (_isLecturer) ...[
                TextFormField(
                  controller: _nip,
                  decoration: const InputDecoration(labelText: 'NIP'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'NIP wajib diisi' : null,
                ),
                const SizedBox(height: 12),
              ],
              TextFormField(
                controller: _prodi,
                decoration: const InputDecoration(labelText: 'Program Studi'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Program studi wajib diisi' : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Simpan')),
      ],
    );
  }
}
