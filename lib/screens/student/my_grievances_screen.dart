import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/grievance.dart';
import '../../models/student_profile.dart';
import '../../services/firestore_service.dart';
import '../../services/priority_service.dart';
import '../../utils/date_helpers.dart';
import '../../utils/constants.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/empty_state_widget.dart';
import 'submit_grievance_screen.dart';

class MyGrievancesScreen extends StatefulWidget {
  final StudentProfile? profile;

  final bool showBackButton;

  const MyGrievancesScreen({
    super.key,
    this.profile,
    this.showBackButton = true,
  });

  @override
  State<MyGrievancesScreen> createState() => _MyGrievancesScreenState();
}

class _MyGrievancesScreenState extends State<MyGrievancesScreen> {
  // Key used to refresh the stream by forcing a rebuild
  Key _refreshKey = UniqueKey();

  void _refresh() {
    setState(() {
      _refreshKey = UniqueKey();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.profile == null) {
      return const Scaffold(body: Center(child: Text('Profile not loaded')));
    }

    final firestoreService = context.read<FirestoreService>();

    return Scaffold(
      appBar: AppBar(
        leading: widget.showBackButton
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        automaticallyImplyLeading: false,
        title: const Text('My Grievances'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
            tooltip: 'Refresh List',
          ),
        ],
      ),
      body: StreamBuilder<List<Grievance>>(
        key: _refreshKey,
        stream: firestoreService.getStudentGrievances(widget.profile!.userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingWidget(message: 'Loading grievances...');
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final grievances = snapshot.data ?? [];

          if (grievances.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.report_problem_outlined,
              message: 'No grievances submitted yet',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: grievances.length,
            cacheExtent: 1000,
            itemBuilder: (context, index) {
              final grievance = grievances[index];
              return _buildGrievanceCard(context, grievance);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  SubmitGrievanceScreen(profile: widget.profile),
            ),
          ).then((_) {
            // Refresh logic if needed, but StreamBuilder handles it
          });
        },
        heroTag: 'grievance_fab',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildGrievanceCard(BuildContext context, Grievance grievance) {
    final priorityLevel = PriorityService.getPriorityLevel(
      grievance.priorityScore,
    );
    final isCritical = priorityLevel == 'Critical';
    final isResolved = grievance.status == GrievanceStatus.resolved;

    return Card(
      color: Theme.of(context).cardTheme.color,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Category + Status
            Row(
              children: [
                Expanded(
                  child: Text(
                    grievance.category.toUpperCase(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                ),
                _buildStatusBadge(grievance.status),
              ],
            ),
            const SizedBox(height: 8),

            // Description Preview
            Text(
              grievance.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
            const SizedBox(height: 12),

            // Timestamps & SLA
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
                const SizedBox(width: 4),
                Text(
                  'Submitted: ${DateHelpers.formatDate(grievance.submittedAt)}',
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.timer,
                  size: 16,
                  color: isResolved
                      ? Colors.green
                      : (isCritical ? Colors.red : Colors.orange),
                ),
                const SizedBox(width: 4),
                Text(
                  isResolved
                      ? 'Resolved'
                      : 'Resolution by: ${DateHelpers.formatDate(grievance.slaDeadline)}',
                  style: TextStyle(
                    color: isResolved
                        ? Colors.green
                        : (isCritical ? Colors.red : Colors.orange[800]),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const Divider(height: 24),

            // Footer: Priority + Proof Indicator
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _getPriorityColor(
                      priorityLevel,
                    ).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _getPriorityColor(priorityLevel)),
                  ),
                  child: Text(
                    '$priorityLevel Priority',
                    style: TextStyle(
                      color: _getPriorityColor(priorityLevel),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (grievance.proofUrls.isNotEmpty)
                  const Icon(Icons.attach_file, size: 16, color: Colors.blue),
                if (grievance.isAnonymous) ...[
                  const Spacer(),
                  const Icon(
                    Icons.visibility_off,
                    size: 16,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'Anonymous',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status) {
      case GrievanceStatus.pending:
        color = Colors.orange;
        break;
      case GrievanceStatus.assigned:
        color = Colors.blue;
        break;
      case GrievanceStatus.inProgress:
        color = Colors.purple;
        break;
      case GrievanceStatus.resolved:
        color = Colors.green;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getPriorityColor(String level) {
    switch (level) {
      case 'Critical':
        return Colors.red;
      case 'High':
        return Colors.orange;
      case 'Medium':
        return Colors.amber;
      default:
        return Colors.green;
    }
  }
}
