import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/supabase_constants.dart';
import '../../../../core/theme/app_pallete.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../features/community/data/models/event_model.dart';
import '../../../../features/community/presentation/providers/community_providers.dart';

class ManageEventsPage extends ConsumerStatefulWidget {
  const ManageEventsPage({super.key});

  @override
  ConsumerState<ManageEventsPage> createState() => _ManageEventsPageState();
}

class _ManageEventsPageState extends ConsumerState<ManageEventsPage> {
  Future<void> _deleteEvent(int id) async {
    try {
      final repo = ref.read(communityRepositoryProvider);
      await repo.deleteEvent(id);
      ref.invalidate(eventsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Event deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error deleting event: $e')));
      }
    }
  }

  Future<void> _handleSaveEvent(
    Event event,
    Uint8List? imageBytes,
    String? imageName,
  ) async {
    final repo = ref.read(communityRepositoryProvider);
    String? imageUrl = event.imageUrl;

    // 1. Upload Image if new bytes provided
    if (imageBytes != null && imageName != null) {
      final path = 'events/${DateTime.now().millisecondsSinceEpoch}_$imageName';
      final uploadedUrl = await repo.uploadEventImage(path, imageBytes);
      if (uploadedUrl == null) {
        throw Exception("Failed to upload image. Please try again.");
      }
      imageUrl = uploadedUrl;
    } else if (imageUrl == null || imageUrl.isEmpty) {
      // 2. Default image when no image selected (new or existing event)
      imageUrl = SupabaseConstants.defaultEventImageUrl;
    }

    // 3. Create Event object with final URL
    final finalEvent = event.copyWith(imageUrl: imageUrl);

    // 4. Upsert
    await repo.upsertEvent(finalEvent);
    ref.invalidate(eventsProvider);
  }

  void _showEventDialog({Event? event}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          EventFormDialog(initialEvent: event, onSave: _handleSaveEvent),
    );
  }

  void _showDeleteConfirmation(int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Event?"),
        content: const Text(
          "Are you sure you want to delete this event? This action cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CANCEL"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteEvent(id);
            },
            child: const Text("DELETE", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(eventsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Manage Events"),
        actions: [
          IconButton(
            onPressed: () => _showEventDialog(),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: eventsAsync.when(
        data: (events) {
          if (events.isEmpty) {
            return const Center(child: Text("No events found. Add one!"));
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(8),
                  leading: event.imageUrl != null
                      ? CircleAvatar(
                          backgroundImage: NetworkImage(event.imageUrl!),
                        )
                      : const CircleAvatar(child: Icon(Icons.event)),
                  title: Text(
                    event.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    DateFormat('MMM d, yyyy - h:mm a').format(event.eventDate),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _showEventDialog(event: event),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _showDeleteConfirmation(event.id),
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

class EventFormDialog extends StatefulWidget {
  final Event? initialEvent;
  final Future<void> Function(
    Event event,
    Uint8List? imageBytes,
    String? imageName,
  )
  onSave;

  const EventFormDialog({super.key, this.initialEvent, required this.onSave});

  @override
  State<EventFormDialog> createState() => _EventFormDialogState();
}

class _EventFormDialogState extends State<EventFormDialog> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _locationController = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  Uint8List? _selectedImageBytes;
  String? _selectedImageName;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialEvent != null) {
      final e = widget.initialEvent!;
      _titleController.text = e.title;
      _descController.text = e.description ?? '';
      _locationController.text = e.location ?? '';
      _selectedDate = e.eventDate;
      _selectedTime = TimeOfDay.fromDateTime(e.eventDate);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _selectedImageBytes = bytes;
        _selectedImageName = image.name;
      });
    }
  }

  Future<void> _save() async {
    if (_titleController.text.isEmpty ||
        _selectedDate == null ||
        _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill Title, Date, and Time')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final eventDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      final eventObj =
          widget.initialEvent?.copyWith(
            title: _titleController.text.trim(),
            description: _descController.text.trim(),
            location: _locationController.text.trim(),
            eventDate: eventDateTime,
          ) ??
          Event(
            id: 0,
            title: _titleController.text.trim(),
            description: _descController.text.trim(),
            location: _locationController.text.trim(),
            eventDate: eventDateTime,
            imageUrl: null,
            isFeatured: false,
          );

      await widget.onSave(eventObj, _selectedImageBytes, _selectedImageName);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.initialEvent == null ? 'Event created' : 'Event updated',
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
      title: Text(widget.initialEvent == null ? "Add New Event" : "Edit Event"),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: "Event Title *"),
              enabled: !_isLoading,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _descController,
              decoration: const InputDecoration(labelText: "Description"),
              maxLines: 3,
              enabled: !_isLoading,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _locationController,
              decoration: const InputDecoration(labelText: "Location"),
              enabled: !_isLoading,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.calendar_today),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.black,
                    ),
                    label: Text(
                      _selectedDate == null
                          ? "Pick Date *"
                          : DateFormat('MMM d, yyyy').format(_selectedDate!),
                    ),
                    onPressed: _isLoading
                        ? null
                        : () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _selectedDate ?? DateTime.now(),
                              firstDate: DateTime(2024),
                              lastDate: DateTime(2030),
                            );
                            if (picked != null) {
                              setState(() => _selectedDate = picked);
                            }
                          },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.access_time),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.black,
                    ),
                    label: Text(
                      _selectedTime == null
                          ? "Pick Time *"
                          : _selectedTime!.format(context),
                    ),
                    onPressed: _isLoading
                        ? null
                        : () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: _selectedTime ?? TimeOfDay.now(),
                              builder: (context, child) {
                                return Theme(
                                  data: AppTheme.lightTheme.copyWith(
                                    timePickerTheme: const TimePickerThemeData(
                                      dialHandColor: Color(0xFF1B5E20),
                                      dialBackgroundColor: Color(0xFFE8F5E9),
                                    ),
                                    colorScheme: const ColorScheme.light(
                                      primary: Color(0xFF1B5E20),
                                      onSurface: Colors.black,
                                    ),
                                  ),
                                  child: child!,
                                );
                              },
                            );
                            if (picked != null) {
                              setState(() => _selectedTime = picked);
                            }
                          },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              icon: const Icon(Icons.image),
              label: Text(_selectedImageName ?? "Change/Select Image"),
              onPressed: _isLoading ? null : _pickImage,
            ),
            if (_selectedImageBytes != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Image.memory(
                  _selectedImageBytes!,
                  height: 100,
                  fit: BoxFit.cover,
                ),
              )
            else if (widget.initialEvent?.imageUrl != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Image.network(
                  widget.initialEvent!.imageUrl!,
                  height: 100,
                  fit: BoxFit.cover,
                ),
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
              : Text(
                  widget.initialEvent == null ? "SAVE EVENT" : "UPDATE EVENT",
                ),
        ),
      ],
    );
  }
}
