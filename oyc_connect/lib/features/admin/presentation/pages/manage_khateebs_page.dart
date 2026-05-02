import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../features/prayer_times/data/repositories/khateeb_repository.dart';

class ManageKhateebsPage extends ConsumerStatefulWidget {
  const ManageKhateebsPage({super.key});

  @override
  ConsumerState<ManageKhateebsPage> createState() => _ManageKhateebsPageState();
}

class _ManageKhateebsPageState extends ConsumerState<ManageKhateebsPage> {
  final _nameController = TextEditingController();

  void _showAddDialog() {
    _nameController.clear();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Khateeb'),
        content: TextField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Khateeb Name',
            hintText: 'e.g., Sheikh Ahmed',
            border: OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_nameController.text.isNotEmpty) {
                final name = _nameController.text.trim();
                Navigator.pop(context);
                try {
                  await ref.read(khateebRepositoryProvider).addKhateeb(name);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Khateeb added successfully'),
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error adding khateeb: $e')),
                    );
                  }
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(int id, String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Khateeb'),
        content: Text('Are you sure you want to delete "$name"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref.read(khateebRepositoryProvider).deleteKhateeb(id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Khateeb deleted')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Error deleting: $e')));
                }
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final khateebsAsync = ref.watch(khateebsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Khateebs'),
        centerTitle: true,
        actions: [
          IconButton(onPressed: _showAddDialog, icon: const Icon(Icons.add)),
        ],
      ),
      body: khateebsAsync.when(
        data: (khateebs) {
          if (khateebs.isEmpty) {
            return const Center(
              child: Text(
                'No Khateebs found.\nTap + to add one.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: khateebs.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              final khateeb = khateebs[index];
              return Card(
                elevation: 0,
                color: Colors.grey.shade50,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.teal.shade50,
                    child: Text(
                      khateeb.name[0].toUpperCase(),
                      style: TextStyle(color: Colors.teal.shade800),
                    ),
                  ),
                  title: Text(
                    khateeb.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => _confirmDelete(khateeb.id, khateeb.name),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
