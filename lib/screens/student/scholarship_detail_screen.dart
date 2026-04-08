import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/premium_theme.dart';
import '../../widgets/premium_widgets.dart';
import '../../models/scholarship.dart';
import '../../models/student_profile.dart';
import '../../models/application.dart';
import '../../services/eligibility_service.dart';
import '../../utils/date_helpers.dart';
import 'apply_scholarship_screen.dart';
import 'profile_screen.dart';

class ScholarshipDetailScreen extends StatelessWidget {
  final Scholarship scholarship;
  final StudentProfile? profile;
  final Application? application;

  const ScholarshipDetailScreen({
    super.key,
    required this.scholarship,
    this.profile,
    this.application,
  });

  @override
  Widget build(BuildContext context) {
    // Check eligibility details if profile exists
    final eligibilityDetails = profile != null
        ? EligibilityService.getEligibilityDetails(profile!, scholarship)
        : null;

    final isEligible = eligibilityDetails?['isEligible'] as bool? ?? false;
    final passedCriteria =
        eligibilityDetails?['passedCriteria'] as List<String>? ?? [];
    final failedCriteria =
        eligibilityDetails?['failedCriteria'] as List<String>? ?? [];

    return Scaffold(
      backgroundColor: PremiumTheme.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
              ),
            ],
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: PremiumTheme.primary, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: Text(
          'Scholarship Details',
          style: GoogleFonts.plusJakartaSans(
            color: PremiumTheme.textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Background Gradient
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: PremiumTheme.primary.withValues(alpha: 0.1),
              ),
            ),
          ),
          
          SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(24, MediaQuery.of(context).padding.top + 80, 24, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Detail
                Text(
                  scholarship.title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: PremiumTheme.textPrimary,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.account_balance_rounded, color: PremiumTheme.primary, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      scholarship.organization,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        color: PremiumTheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Key Info Box
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoCard(
                        'Amount',
                        '₹${scholarship.amount.toStringAsFixed(0)}',
                        Icons.payments_rounded,
                        PremiumTheme.success,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildInfoCard(
                        'Deadline',
                        DateHelpers.formatDate(scholarship.deadline),
                        Icons.event_rounded,
                        PremiumTheme.error,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Application Status Section
                if (application != null) ...[
                  Text(
                    'Application Status',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: PremiumTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildStatusDetailedCard(context, application!),
                  const SizedBox(height: 32),
                ],

                // Description
                Text(
                  'About the Scholarship',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: PremiumTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                NeoGlassCard(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    scholarship.description,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      color: PremiumTheme.textSecondary,
                      height: 1.6,
                    ),
                  ),
                ),
                
                const SizedBox(height: 32),

                // Eligibility Section
                Text(
                  'Eligibility Criteria',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: PremiumTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                NeoGlassCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _buildCriteriaRow('Branch', scholarship.eligibilityCriteria.courses.isEmpty
                          ? 'All Branches'
                          : scholarship.eligibilityCriteria.courses.join(', ')),
                      const Divider(height: 24),
                      _buildCriteriaRow('Year', scholarship.eligibilityCriteria.years.isEmpty
                          ? 'All Years'
                          : scholarship.eligibilityCriteria.years.map((y) => 'Year $y').join(', ')),
                      const Divider(height: 24),
                      _buildCriteriaRow('Category', scholarship.eligibilityCriteria.categories.isEmpty
                          ? 'All Categories'
                          : scholarship.eligibilityCriteria.categories.join(', ')),
                      const Divider(height: 24),
                      _buildCriteriaRow('Min CGPA', '${scholarship.eligibilityCriteria.minCGPA}'),
                      const Divider(height: 24),
                      _buildCriteriaRow('Family Income', '₹${scholarship.eligibilityCriteria.maxIncome.toStringAsFixed(0)}'),
                    ],
                  ),
                ),

                if (profile != null && eligibilityDetails != null) ...[
                  const SizedBox(height: 32),
                  _buildEligibilityStatus(isEligible, failedCriteria, passedCriteria),
                ],
              ],
            ),
          ),

          // Bottom Action Bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    PremiumTheme.background.withValues(alpha: 0),
                    PremiumTheme.background.withValues(alpha: 0.8),
                    PremiumTheme.background,
                  ],
                ),
              ),
              child: _buildApplyButton(context, isEligible),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: PremiumTheme.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: PremiumTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCriteriaRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: PremiumTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: PremiumTheme.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusDetailedCard(BuildContext context, Application application) {
    final status = application.status;
    final color = status == 'approved' ? PremiumTheme.success : 
                  status == 'rejected' ? PremiumTheme.error :
                  status == 'reverted' ? PremiumTheme.warning : PremiumTheme.primary;
    
    return NeoGlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  status == 'approved' ? Icons.check_rounded :
                  status == 'rejected' ? Icons.close_rounded :
                  status == 'reverted' ? Icons.assignment_return_rounded : Icons.schedule_rounded,
                  color: color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    status.toUpperCase(),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                  Text(
                    'Submitted on ${DateHelpers.formatDate(application.submittedAt)}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: PremiumTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (status == 'reverted' && application.facultyComments != null) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Divider(),
            ),
            Text(
              'Correction Needed',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: PremiumTheme.warning,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: PremiumTheme.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: PremiumTheme.warning.withValues(alpha: 0.1)),
              ),
              child: Text(
                application.facultyComments!,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: PremiumTheme.textPrimary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEligibilityStatus(bool isEligible, List<String> failed, List<String> passed) {
    return NeoGlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isEligible ? Icons.verified_rounded : Icons.info_outline_rounded,
                color: isEligible ? PremiumTheme.success : PremiumTheme.error,
              ),
              const SizedBox(width: 12),
              Text(
                isEligible ? 'You are eligible!' : 'Eligibility breakdown',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: PremiumTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (!isEligible) ...[
            ...failed.map((f) => _buildCriteriaCheck(f, false)),
          ],
          ...passed.map((p) => _buildCriteriaCheck(p, true)),
        ],
      ),
    );
  }

  Widget _buildCriteriaCheck(String label, bool isPassed) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            isPassed ? Icons.check_circle_rounded : Icons.cancel_rounded,
            color: isPassed ? PremiumTheme.success : PremiumTheme.error,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: isPassed ? PremiumTheme.textSecondary : PremiumTheme.error,
                fontWeight: isPassed ? FontWeight.normal : FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApplyButton(BuildContext context, bool isEligible) {
    final bool hasActiveApplication =
        application != null &&
        application!.status != 'reverted' &&
        application!.status != 'rejected';

    final bool canApply = isEligible && !hasActiveApplication;

    String buttonText = 'Apply Now';
    IconData icon = Icons.rocket_launch_rounded;
    
    if (profile == null) {
      buttonText = 'Complete Profile First';
      icon = Icons.person_add_rounded;
    } else if (hasActiveApplication) {
      buttonText = 'Already Applied';
      icon = Icons.check_circle_rounded;
    } else if (!isEligible) {
      buttonText = 'Not Eligible';
      icon = Icons.lock_rounded;
    } else if (application != null && application!.status == 'reverted') {
      buttonText = 'Resubmit Correction';
      icon = Icons.edit_note_rounded;
    } else if (application != null && application!.status == 'rejected') {
      buttonText = 'Re-apply Now';
      icon = Icons.replay_rounded;
    }

    return ElevatedButton(
      onPressed: canApply
          ? () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ApplyScholarshipScreen(
                    scholarship: scholarship,
                    profile: profile!,
                  ),
                ),
              );
            }
          : (profile == null ? () {
              // Navigate to profile
              Navigator.push(context, MaterialPageRoute(builder: (context) => ProfileScreen()));
          } : null),
      style: ElevatedButton.styleFrom(
        backgroundColor: canApply || profile == null ? PremiumTheme.primary : Colors.grey.shade300,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: canApply ? 8 : 0,
        shadowColor: PremiumTheme.primary.withValues(alpha: 0.4),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon),
          const SizedBox(width: 12),
          Text(
            buttonText,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
