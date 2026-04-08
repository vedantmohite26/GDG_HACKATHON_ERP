import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../services/firestore_service.dart';
import '../../theme/premium_theme.dart';
import '../../widgets/premium_widgets.dart';

class ManageCalendarScreen extends StatefulWidget {
  final bool showAppBar;
  const ManageCalendarScreen({super.key, this.showAppBar = true});

  @override
  State<ManageCalendarScreen> createState() => _ManageCalendarScreenState();
}

class _ManageCalendarScreenState extends State<ManageCalendarScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String _selectedType = 'General';
  bool _isLoading = false;

  final List<String> _eventTypes = [
    'General',
    'Exam',
    'Holiday',
    'Deadline',
    'Event',
    'Workshop',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _createEvent() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final eventData = {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'date': _selectedDate,
        'type': _selectedType,
        'createdAt': DateTime.now(),
      };

      await context.read<FirestoreService>().createCalendarEvent(eventData);

      if (mounted) {
        Navigator.pop(context); // Close dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Event created successfully'),
            backgroundColor: PremiumTheme.success,
          ),
        );
        _titleController.clear();
        _descriptionController.clear();
        _selectedDate = DateTime.now();
        _selectedType = 'General';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating event: $e'),
            backgroundColor: PremiumTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteEvent(String eventId) async {
    try {
      await context.read<FirestoreService>().deleteCalendarEvent(eventId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Event deleted'),
            backgroundColor: PremiumTheme.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting event: $e'),
            backgroundColor: PremiumTheme.error,
          ),
        );
      }
    }
  }

  void _showAddEventDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: PremiumTheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: BorderSide(
                color: PremiumTheme.primary.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            title: Text(
              'Add Calendar Event',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                color: PremiumTheme.textPrimary,
              ),
            ),
            content: SizedBox(
              width: MediaQuery.of(context).size.width * 0.9,
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TechInput(
                        label: 'Event Title',
                        icon: Icons.title,
                        controller: _titleController,
                        validator: (value) =>
                            value!.isEmpty ? 'Enter a title' : null,
                      ),
                      const SizedBox(height: 16),
                      // Custom Dropdown using Container to match theme
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: PremiumTheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: PremiumTheme.primary.withValues(alpha: 0.1),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButtonFormField<String>(
                            initialValue: _selectedType,
                            dropdownColor: PremiumTheme.surface,
                            style: GoogleFonts.inter(color: PremiumTheme.textPrimary),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              prefixIcon: Icon(
                                Icons.category,
                                color: PremiumTheme.primary,
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                vertical: 12,
                              ),
                            ),
                            items: _eventTypes.map((type) {
                              return DropdownMenuItem(
                                value: type,
                                child: Text(type),
                              );
                            }).toList(),
                            onChanged: (val) {
                              setDialogState(() => _selectedType = val!);
                              setState(() => _selectedType = val!);
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      NeoGlassCard(
                        padding: const EdgeInsets.all(16),
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                            builder: (context, child) {
                              return Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: const ColorScheme.light(
                                    primary: PremiumTheme.primary,
                                    onPrimary: Colors.white,
                                    surface: PremiumTheme.surface,
                                    onSurface: PremiumTheme.textPrimary,
                                  ),
                                  dialogTheme: const DialogThemeData(
                                    backgroundColor: PremiumTheme.surface,
                                  ),
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (date != null && context.mounted) {
                            setDialogState(() => _selectedDate = date);
                            setState(() => _selectedDate = date);
                          }
                        },
                        child: Row(
                          children: [
                            const Icon(
                              Icons.calendar_today,
                              color: PremiumTheme.tertiary,
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Date',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                                Text(
                                  DateFormat(
                                    'MMMM dd, yyyy',
                                  ).format(_selectedDate),
                                  style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.w600,
                                    color: PremiumTheme.textPrimary,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      TechInput(
                        label: 'Description (Optional)',
                        icon: Icons.description,
                        controller: _descriptionController,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.outfit(color: PremiumTheme.textSecondary),
                ),
              ),
              FutureButton(
                text: 'Add Event',
                onPressed: _createEvent,
                isLoading: _isLoading,
                icon: Icons.check,
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PremiumTheme.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddEventDialog,
        icon: const Icon(Icons.add_rounded),
        label: Text(
          'Add Event',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
        ),
        backgroundColor: PremiumTheme.secondary,
        foregroundColor: Colors.white,
        elevation: 8,
        shape: const StadiumBorder(),
      ),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => widget.showAppBar ? [
          SliverAppBar(
            expandedHeight: 120,
            floating: true,
            pinned: true,
            elevation: 0,
            backgroundColor: PremiumTheme.primary,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: PremiumTheme.heroGradient,
                ),
              ),
              title: Text(
                'Manage Calendar',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: Colors.white,
                ),
              ),
              centerTitle: false,
              titlePadding: const EdgeInsets.only(left: 56, bottom: 16),
            ),
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 20,
              ),
              onPressed: () => Navigator.pop(context),
            )
          ),
        ] : [],
        body: Container(
          decoration: const BoxDecoration(
            color: PremiumTheme.background,
          ),
          child: StreamBuilder<List<Map<String, dynamic>>>(
          stream: context.read<FirestoreService>().getCalendarEvents(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error loading events',
                  style: GoogleFonts.inter(color: Colors.red),
                ),
              );
            }

            final events = snapshot.data ?? [];

            if (events.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: PremiumTheme.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.event_busy,
                        size: 64,
                        color: PremiumTheme.primary,
                      ),
                    ).animate().scale(duration: 500.ms, curve: Curves.easeOut),
                    const SizedBox(height: 16),
                    Text(
                      'No events scheduled',
                      style: GoogleFonts.outfit(
                        color: PremiumTheme.textSecondary,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: events.length,
              itemBuilder: (context, index) {
                final event = events[index];
                final date =
                    (event['date'] as dynamic)?.toDate() ?? DateTime.now();
                final title = event['title'] ?? 'Untitled';
                final type = event['type'] ?? 'General';
                final id = event['id'];
                final description = event['description'] ?? '';

                Color typeColor;
                switch (type) {
                  case 'Exam':
                    typeColor = const Color.fromARGB(255, 55, 211, 47);
                    break;
                  case 'Holiday':
                    typeColor = const Color.fromARGB(255, 255, 46, 46);
                    break;
                  case 'Deadline':
                    typeColor = Colors.orangeAccent;
                    break;
                  case 'Workshop':
                    typeColor = const Color.fromARGB(255, 197, 0, 171);
                    break;
                  default:
                    typeColor = PremiumTheme.primary;
                }

                return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: PremiumTheme.surface,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: PremiumTheme.primary.withValues(alpha: 0.1),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: PremiumTheme.primary.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Date Box
                            Container(
                              width: 60,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: typeColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: typeColor.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    DateFormat('dd').format(date),
                                    style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                      color: typeColor,
                                    ),
                                  ),
                                  Text(
                                    DateFormat(
                                      'MMM',
                                    ).format(date).toUpperCase(),
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: typeColor.withValues(alpha: 0.8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Content
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Wrap(
                                    alignment: WrapAlignment.spaceBetween,
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    spacing: 8,
                                    runSpacing: 4,
                                    children: [
                                      HoloBadge(text: type, color: typeColor),
                                      Text(
                                        DateFormat('EEEE, h:mm a').format(date),
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          color: PremiumTheme.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    title,
                                    style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                      color: PremiumTheme.textPrimary,
                                    ),
                                  ),
                                  if (description.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      description,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        color: PremiumTheme.textSecondary,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            // Delete Button
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline_rounded,
                                color: PremiumTheme.error,
                              ),
                              onPressed: () => _confirmDelete(id),
                            ),
                          ],
                        ),
                      ),
                    );
              },
            );
          },
        ),
      ),
      ),
    );
  }

  void _confirmDelete(String eventId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: PremiumTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Delete Event?',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            color: PremiumTheme.textPrimary,
          ),
        ),
        content: Text(
          'This action cannot be undone.',
          style: GoogleFonts.inter(color: PremiumTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.outfit(color: PremiumTheme.textSecondary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: PremiumTheme.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              Navigator.pop(context);
              _deleteEvent(eventId);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
