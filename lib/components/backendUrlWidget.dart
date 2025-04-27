import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/appInfo_state.dart'; // Make sure this has your userProvider and model

class BackendUrlWidget extends ConsumerWidget {
  const BackendUrlWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appInfo = ref.watch(appInfoProvider);

    // Controller holds the name for editing
    final controller = TextEditingController(text: appInfo?.backendUrl ?? '');

    return Padding(
      padding: const EdgeInsets.all(30.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Edit Name:", style: TextStyle(fontSize: 16)),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Enter new name',
            ),
            onChanged: (value) {
              ref.read(appInfoProvider.notifier).updateURL(value);
            },
          ),
          const SizedBox(height: 16),
          Text(
            "Current Name: ${appInfo?.backendUrl}",
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
}
