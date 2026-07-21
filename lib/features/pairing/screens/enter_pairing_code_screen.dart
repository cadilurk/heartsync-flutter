import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_exception.dart';
import '../providers/pairing_provider.dart';

class EnterPairingCodeScreen extends StatefulWidget {
  const EnterPairingCodeScreen({super.key});

  @override
  State<EnterPairingCodeScreen> createState() => _EnterPairingCodeScreenState();
}

class _EnterPairingCodeScreenState extends State<EnterPairingCodeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    try {
      setState(() => _error = null);
      await context.read<PairingProvider>().connect(_codeController.text);
      if (mounted) context.go('/pairing/success');
    } on ApiException catch (error) {
      setState(() => _error = error.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.select<PairingProvider, bool>(
      (value) => value.state == PairingState.loading,
    );
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nhập mã ghép đôi'),
        leading: BackButton(onPressed: () => context.go('/pairing')),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text('Nhập mã 6 ký tự partner gửi cho bạn.'),
          const SizedBox(height: 20),
          Form(
            key: _formKey,
            child: TextFormField(
              controller: _codeController,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(labelText: 'Mã ghép đôi'),
              validator: (value) {
                final text = value?.trim() ?? '';
                if (text.isEmpty) return 'Vui lòng nhập mã ghép đôi.';
                if (text.length != 6) return 'Mã ghép đôi gồm 6 ký tự.';
                return null;
              },
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: Colors.red)),
          ],
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: isLoading ? null : _submit,
            child: isLoading
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Kết nối'),
          ),
        ],
      ),
    );
  }
}
