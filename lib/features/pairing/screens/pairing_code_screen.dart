import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_exception.dart';
import '../providers/pairing_provider.dart';

class PairingCodeScreen extends StatefulWidget {
  const PairingCodeScreen({super.key});

  @override
  State<PairingCodeScreen> createState() => _PairingCodeScreenState();
}

class _PairingCodeScreenState extends State<PairingCodeScreen> {
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _generate());
  }

  Future<void> _generate() async {
    try {
      setState(() => _error = null);
      await context.read<PairingProvider>().generateCode();
    } on ApiException catch (error) {
      setState(() => _error = error.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PairingProvider>();
    final code = provider.activeCode;
    final isLoading = provider.state == PairingState.loading;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mã ghép đôi'),
        leading: BackButton(onPressed: () => context.go('/pairing')),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 48),
            const Text('Gửi mã này cho partner', textAlign: TextAlign.center),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: isLoading
                      ? const CircularProgressIndicator()
                      : Text(
                          code?.code ?? '------',
                          style: const TextStyle(
                            fontSize: 38,
                            letterSpacing: 4,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                ),
              ),
            ),
            if (code?.expiredAt != null)
              Text(
                'Hết hạn: ${code!.expiredAt!.toLocal()}',
                textAlign: TextAlign.center,
              ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
            const Spacer(),
            ElevatedButton.icon(
              onPressed: code == null
                  ? null
                  : () {
                      Clipboard.setData(ClipboardData(text: code.code));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Đã copy mã ghép đôi.')),
                      );
                    },
              icon: const Icon(Icons.copy),
              label: const Text('Copy mã'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: isLoading ? null : _generate,
              child: const Text('Tạo mã mới'),
            ),
          ],
        ),
      ),
    );
  }
}
