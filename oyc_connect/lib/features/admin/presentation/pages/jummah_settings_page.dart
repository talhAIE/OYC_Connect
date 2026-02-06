import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../prayer_times/data/models/jummah_config.dart';
import '../../../prayer_times/data/models/khateeb_model.dart';
import '../../../prayer_times/presentation/providers/prayer_times_provider.dart';
import '../../../prayer_times/data/repositories/khateeb_repository.dart';

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
  String? _selectedKhateebName;

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
    final khateebsAsync = ref.watch(khateebsStreamProvider);

    // Listen to load initial data
    ref.listen(jummahConfigProvider, (prev, next) {
      if (next.hasValue && next.value != null && _docId == null) {
        final data = next.value!;
        setState(() {
          _docId = data.id;
          _khutbahController.text = data.khutbahTime;
          _addressController.text = data.address;
          _selectedKhateebName = data.khateebName;
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
            _selectedKhateebName = config.khateebName;
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

                  // Khateeb Dropdown
                  khateebsAsync.when(
                    data: (khateebs) {
                      // Ensure selected value is valid or null
                      if (_selectedKhateebName != null &&
                          !khateebs.any(
                            (k) => k.name == _selectedKhateebName,
                          )) {
                        // Keep it if it's custom, or clear if strict?
                        // For now, let's treat the saved string as source of truth visually,
                        // but if we want strict selection we might need to clear or show 'Unknown'.
                        // Let's assume we match by Name.
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value:
                                      khateebs.any(
                                        (k) => k.name == _selectedKhateebName,
                                      )
                                      ? _selectedKhateebName
                                      : null,
                                  decoration: InputDecoration(
                                    labelText: "Select Khateeb",
                                    prefixIcon: const Icon(Icons.person),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  items: khateebs.map((k) {
                                    return DropdownMenuItem(
                                      value: k.name,
                                      child: Text(k.name),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    setState(() {
                                      _selectedKhateebName = val;
                                    });
                                  },
                                  validator: (val) => null, // Optional
                                ),
                              ),
                              const SizedBox(width: 8),
                              InkWell(
                                onTap: () {
                                  context.push('/profile/admin/khateebs');
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.teal.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.teal.withOpacity(0.5),
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.list_alt,
                                    color: Colors.teal,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Padding(
                            padding: EdgeInsets.only(left: 4.0, top: 4.0),
                            child: Text(
                              "Tap the list icon to add or remove speakers",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                    loading: () => const LinearProgressIndicator(),
                    error: (e, _) => Text("Error loading khateebs: $e"),
                  ),

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
    final id = _docId ?? "";

    if (id.isEmpty) {
      try {
        final existing = await repo.getJummahConfig();
        if (existing != null) {
          final updatedConfig = existing.copyWith(
            khutbahTime: _khutbahController.text,
            address: _addressController.text,
            khateebName: _selectedKhateebName,
          );
          await _performUpdate(repo, updatedConfig);
          return;
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Error: No configuration found.")),
            );
          }
          return;
        }
      } catch (e) {
        // Error handling
      }
      return;
    }

    final currentConfig = await repo.getJummahConfig();
    if (currentConfig != null) {
      final updated = currentConfig.copyWith(
        khutbahTime: _khutbahController.text,
        address: _addressController.text,
        khateebName: _selectedKhateebName,
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
