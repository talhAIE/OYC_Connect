import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_pallete.dart';
import '../../../../features/community/data/models/announcement_model.dart';
import '../../../../features/community/presentation/providers/community_providers.dart';

class ManageAnnouncementsPage extends ConsumerStatefulWidget {
  const ManageAnnouncementsPage({super.key});

  @override
  ConsumerState<ManageAnnouncementsPage> createState() =>
      _ManageAnnouncementsPageState();
}

class _ManageAnnouncementsPageState
    extends ConsumerState<ManageAnnouncementsPage> {
  Future<void> _deleteAnnouncement(int id) async {
    try {
      final repo = ref.read(communityRepositoryProvider);
      await repo.deleteAnnouncement(id);
      ref.invalidate(announcementsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Announcement deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _handleSave(Announcement announcement) async {
    final repo = ref.read(communityRepositoryProvider);
    await repo.upsertAnnouncement(announcement);
    ref.invalidate(announcementsProvider);
  }

  void _showAnnouncementDialog({Announcement? announcement}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AnnouncementFormDialog(
        initialAnnouncement: announcement,
        onSave: _handleSave,
      ),
    );
  }

  void _showDeleteConfirmation(int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Announcement?"),
        content: const Text("Are you sure? This cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CANCEL"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteAnnouncement(id);
            },
            child: const Text("DELETE", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showDetailsDialog(Announcement announcement) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(announcement.title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (announcement.isUrgent)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    "URGENT",
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              const SizedBox(height: 10),
              Text(announcement.content, style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 20),
              Text(
                "Posted on: ${DateFormat('MMM d, yyyy - h:mm a').format(announcement.createdAt)}",
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CLOSE"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final announcementsAsync = ref.watch(announcementsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Manage Announcements"),
        actions: [
          IconButton(
            onPressed: () => _showAnnouncementDialog(),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: announcementsAsync.when(
        data: (announcements) {
          if (announcements.isEmpty) {
            return const Center(child: Text("No announcements found."));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: announcements.length,
            itemBuilder: (context, index) {
              final item = announcements[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: ListTile(
                  onTap: () => _showDetailsDialog(item),
                  leading: const CircleAvatar(child: Icon(Icons.campaign)),
                  title: Row(
                    children: [
                      if (item.isUrgent)
                        const Padding(
                          padding: EdgeInsets.only(right: 8.0),
                          child: Icon(Icons.error, color: Colors.red, size: 20),
                        ),
                      Expanded(
                        child: Text(
                          item.title,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  subtitle: Text(
                    DateFormat('MMM d, h:mm a').format(item.createdAt),
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () =>
                            _showAnnouncementDialog(announcement: item),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _showDeleteConfirmation(item.id),
                      ),
                    ],
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

class AnnouncementFormDialog extends StatefulWidget {
  final Announcement? initialAnnouncement;
  final Future<void> Function(Announcement announcement) onSave;

  const AnnouncementFormDialog({
    super.key,
    this.initialAnnouncement,
    required this.onSave,
  });

  @override
  State<AnnouncementFormDialog> createState() => _AnnouncementFormDialogState();
}

class _AnnouncementFormDialogState extends State<AnnouncementFormDialog> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  bool _isUrgent = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialAnnouncement != null) {
      final a = widget.initialAnnouncement!;
      _titleController.text = a.title;
      _contentController.text = a.content;
      _isUrgent = a.isUrgent;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_titleController.text.isEmpty || _contentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill Title and Content')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final announcement =
          widget.initialAnnouncement?.copyWith(
            title: _titleController.text.trim(),
            content: _contentController.text.trim(),
            isUrgent: _isUrgent,
          ) ??
          Announcement(
            id: 0,
            title: _titleController.text.trim(),
            content: _contentController.text.trim(),
            isUrgent: _isUrgent,
            createdAt: DateTime.now(),
          );

      await widget.onSave(announcement);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.initialAnnouncement == null
                  ? 'Announcement created'
                  : 'Announcement updated',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.initialAnnouncement == null
            ? "New Announcement"
            : "Edit Announcement",
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: "Title *"),
              enabled: !_isLoading,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _contentController,
              decoration: const InputDecoration(labelText: "Description *"),
              maxLines: 4,
              enabled: !_isLoading,
            ),
            const SizedBox(height: 20),
            SwitchListTile(
              title: const Text("Mark as Urgent"),
              value: _isUrgent,
              activeColor: Colors.red,
              onChanged: _isLoading
                  ? null
                  : (val) => setState(() => _isUrgent = val),
            ),
          ],
        ),
      ),
      actions: [
        if (!_isLoading)
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CANCEL"),
          ),
        ElevatedButton(
          onPressed: _isLoading ? null : _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1B5E20),
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(widget.initialAnnouncement == null ? "POST" : "UPDATE"),
        ),
      ],
    );
  }
}
