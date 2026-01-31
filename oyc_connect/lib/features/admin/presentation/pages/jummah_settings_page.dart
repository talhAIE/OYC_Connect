import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../prayer_times/data/models/jummah_config.dart';
import '../../../prayer_times/presentation/providers/prayer_times_provider.dart';

class JummahSettingsPage extends ConsumerStatefulWidget {
  const JummahSettingsPage({super.key});

  @override
  ConsumerState<JummahSettingsPage> createState() => _JummahSettingsPageState();
}

class _JummahSettingsPageState extends ConsumerState<JummahSettingsPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _khutbahController;
  late TextEditingController _addressController;
  String? _docId; // To store existing ID if update

  @override
  void initState() {
    super.initState();
    _khutbahController = TextEditingController();
    _addressController = TextEditingController();
  }

  @override
  void dispose() {
    _khutbahController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final configAsync = ref.watch(jummahConfigProvider);

    // Listen to load initial data
    ref.listen(jummahConfigProvider, (prev, next) {
      if (next.hasValue && next.value != null && _docId == null) {
        final data = next.value!;
        setState(() {
          _docId = data.id;
          _khutbahController.text = data.khutbahTime;
          _addressController.text = data.address;
        });
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text("Jummah Settings"),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: configAsync.when(
        data: (config) {
          // If we haven't loaded yet (and listen didn't fire due to immediate data), load now
          if (config != null && _docId == null) {
            _docId = config.id;
            _khutbahController.text = config.khutbahTime;
            _addressController.text = config.address;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    "Configure Friday Jummah Details",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),

                  _buildTextField(
                    controller: _khutbahController,
                    label: "Khutbah Start Time (e.g. 1:30 PM)",
                    icon: Icons.access_time,
                  ),
                  const SizedBox(height: 16),

                  const SizedBox(height: 16),

                  _buildTextField(
                    controller: _addressController,
                    label: "Address",
                    icon: Icons.location_on,
                    maxLines: 2,
                  ),

                  const SizedBox(height: 32),

                  ElevatedButton(
                    onPressed: _saveSettings,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    child: const Text("SAVE SETTINGS"),
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text("Error: $err")),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        helperText: hint,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      maxLines: maxLines,
      validator: (value) => value == null || value.isEmpty ? "Required" : null,
    );
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    final repo = ref.read(jummahRepositoryProvider);
    final id =
        _docId ??
        ""; // If empty, backend might generate one or fail depending on RLS/schema

    // Fix: If no ID found in state, try to fetch it one last time from repo.
    if (id.isEmpty) {
      try {
        final existing = await repo.getJummahConfig();
        if (existing != null) {
          // Found it! Use this ID.
          // Recursive call or just proceed? Proceed clearer.
          final updatedConfig = existing.copyWith(
            khutbahTime: _khutbahController.text,
            address: _addressController.text,
            // jummahTime kept as is
          );
          await _performUpdate(repo, updatedConfig);
          return;
        } else {
          // Still nothing? This means table is empty. Insert new?
          // Not handled here based on previous assumptions, but let's error out safely
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  "Error: No configuration found. Migration missing?",
                ),
              ),
            );
          }
          return;
        }
      } catch (e) {
        // Error handling
      }
      return;
    }

    // Normal update flow if we have ID
    // We need to preserve jummahTime since we removed the field but model requires it.
    // We can fetch current to preserve it, OR just pass empty string if we don't care.
    // Better to fetch current to be safe if ID is known.
    // But since we are outside the `data` block, we might rely on provider params or just fetch.
    // Let's do a fetch-modify-save pattern to be robust.

    final currentConfig = await repo.getJummahConfig();
    if (currentConfig != null) {
      final updated = currentConfig.copyWith(
        khutbahTime: _khutbahController.text,
        address: _addressController.text,
      );
      await _performUpdate(repo, updated);
    }
  }

  Future<void> _performUpdate(dynamic repo, JummahConfig config) async {
    try {
      await repo.updateJummahConfig(config);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Jummah settings updated!")),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error saving: $e")));
      }
    }
  }
}
