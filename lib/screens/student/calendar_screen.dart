import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../services/firestore_service.dart';
import '../../theme/premium_theme.dart';
import '../../widgets/premium_widgets.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  Key _refreshKey = UniqueKey();

  void _refresh() {
    setState(() {
      _refreshKey = UniqueKey();
    });
  }

  @override
  Widget build(BuildContext context) {
    final firestoreService = context.read<FirestoreService>();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).iconTheme.color,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Academic Calendar',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Theme.of(context).iconTheme.color),
            onPressed: _refresh,
            tooltip: 'Refresh Calendar',
          ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        key: _refreshKey,
        stream: firestoreService.getCalendarEvents(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final events = snapshot.data ?? [];

          if (events.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_busy, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No upcoming events',
                    style: GoogleFonts.inter(color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              final date =
                  (event['date'] as dynamic)?.toDate() ?? DateTime.now();
              final day = DateFormat('dd').format(date);
              final month = DateFormat('MMM').format(date);
              final title = event['title'] ?? 'Event';
              final type = event['type'] ?? 'General'; // Exam, Holiday, etc.

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
                case 'Event':
                  typeColor = const Color(0xFF1565C0); // PremiumTheme.primary
                  break;
                default:
                  typeColor = PremiumTheme.primary;
              }

              return NeoGlassCard(
                padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                child: IntrinsicHeight(
                  child: Row(
                    children: [
                      Container(
                        width: 80,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        decoration: BoxDecoration(
                          color: typeColor.withValues(alpha: 0.1),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(16),
                            bottomLeft: Radius.circular(16),
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              day,
                              style: GoogleFonts.outfit(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: typeColor,
                              ),
                            ),
                            Text(
                              month.toUpperCase(),
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: typeColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                title,
                                style: GoogleFonts.outfit(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(
                                    context,
                                  ).textTheme.bodyLarge?.color,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Wrap(
                                alignment: WrapAlignment.start,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 8,
                                runSpacing: 4,
                                children: [
                                  HoloBadge(text: type, color: typeColor),
                                  Text(
                                    DateFormat('EEEE').format(date),
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate(delay: (index * 100).ms).fadeIn().slideX();
            },
          );
        },
      ),
    );
  }
}
